/*
 * ttp — the trust project: a self-hosting OS and compiler.
 * Copyright (C) 2026  Nico Verrijdt
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include "navigator.h"
#include "keyboard.h"   // KEY_* codes
#include "uapi.h"       // sys_getkey / sys_blit (the navigator runs in ring 3)
#include "vga.h"        // VGA_COLS/ROWS, vga_color
#include "string.h"
#include <encode.h>     // struct insn, encode(), assemble() (shared with ttpc)
#include "hash.h"       // sha256, node_source_id

#define MAX_DEPTH 64
#define INFO_ROW  (VGA_ROWS - 2)          // the assembler result line
#define LIST_TOP  5                       // first row of the child list
#define LIST_BOT  (VGA_ROWS - 3)          // last list row (info on 23, help on 24)
#define LIST_ROWS (LIST_BOT - LIST_TOP)   // visible child rows

// Path from root to the current node, plus the selected child index at each
// level. The node tree has no parent pointers, so we remember the descent.
static struct node *path[MAX_DEPTH];
static int          sel[MAX_DEPTH];
static int          depth;

// Last assembler result (filled when the user presses 'a').
static char info[VGA_COLS + 1];

// Ring 3 cannot touch VGA memory through the (future) isolation boundary, so the
// navigator renders into this shadow buffer and SYS_BLITs it in one syscall.
static uint16_t fb[VGA_COLS * VGA_ROWS];

static uint16_t cell(char c, vga_color fg, vga_color bg) {
    return (uint16_t)(unsigned char)c | (uint16_t)(((bg << 4) | fg) << 8);
}
static void fb_clear(vga_color bg) {
    for (int i = 0; i < VGA_COLS * VGA_ROWS; i++) fb[i] = cell(' ', WHITE, bg);
}
static void fb_putc(int x, int y, char c, vga_color fg, vga_color bg) {
    if (x < 0 || x >= VGA_COLS || y < 0 || y >= VGA_ROWS) return;
    fb[y * VGA_COLS + x] = cell(c, fg, bg);
}
static void fb_puts(int x, int y, const char *s, vga_color fg, vga_color bg) {
    for (int i = 0; s[i] && x + i < VGA_COLS; i++) fb_putc(x + i, y, s[i], fg, bg);
}

static struct node *current(void) { return path[depth]; }

// ── tiny string builders (no sprintf in the kernel) ──────────────────
static int s_put(char *dst, int pos, const char *s) {
    while (*s && pos < VGA_COLS) dst[pos++] = *s++;
    return pos;
}
static int s_puti(char *dst, int pos, int v) {
    char t[12]; int i = 0;
    if (v == 0) t[i++] = '0';
    while (v > 0) { t[i++] = (char)('0' + v % 10); v /= 10; }
    while (i > 0 && pos < VGA_COLS) dst[pos++] = t[--i];
    return pos;
}

// The CPU mode in effect for child `idx`: the most recent preceding "bits" node.
static int asm_mode_for(struct node *cur, int idx) {
    int mode = 64;
    for (int i = 0; i < idx && i < cur->n_children; i++) {
        struct node *c = cur->children[i];
        if (!strcmp(c->content, "bits") && c->n_children == 1)
            mode = atoi(c->children[0]->content);
    }
    return mode;
}

// Append the first 4 bytes of a 32-byte hash as 8 hex chars.
static int s_puthash(char *dst, int pos, const uint8_t *h) {
    static const char hx[] = "0123456789abcdef";
    for (int k = 0; k < 4 && pos < VGA_COLS - 1; k++) {
        dst[pos++] = hx[h[k] >> 4];
        dst[pos++] = hx[h[k] & 0xF];
    }
    return pos;
}

// meta freshness: -1 = no compiled binary, 0 = fresh (binary matches the current
// source), 1 = stale (the source changed since the binary was built).
static int meta_state(struct node *n) {
    struct node *m = node_meta(n);
    if (!m) return -1;
    struct node *src = node_child(m, "src");
    if (!src || src->n_children < 1 || src->children[0]->content_len != 32)
        return 1;
    uint8_t now[32];
    node_source_id(n, now);                     // excludes meta
    return memcmp(now, src->children[0]->content, 32) ? 1 : 0;
}

// Compile the selected node: encode -> bytes, hash the source and the binary,
// and cache the result on the node as meta/elf (+ provenance in meta/src and the
// binary id in meta/bin). The compiler writing back into the tree it just read —
// the self-hosting loop in miniature.
static void compile_selected(void) {
    struct node *cur = current();
    int s = sel[depth];
    if (cur->n_children == 0 || s >= cur->n_children) {
        info[s_put(info, 0, "(nothing to compile)")] = '\0';
        return;
    }
    struct node *t = cur->children[s];
    int mode = asm_mode_for(cur, s);

    struct insn in;
    const char *err = NULL;
    if (!encode(t, mode, &in, &err)) {
        int pos = s_put(info, 0, "compile ");
        pos = s_put(info, pos, t->content);
        pos = s_put(info, pos, ": error: ");
        pos = s_put(info, pos, err ? err : "unsupported");
        info[pos] = '\0';
        return;
    }
    unsigned char buf[16];
    int n = assemble(&in, buf);

    uint8_t sid[32], bid[32];
    node_source_id(t, sid);                     // hash of the source (no meta)
    sha256(buf, (size_t)n, bid);                // hash of the compiled bytes

    // Cache under meta as named nodes (elf/src/bin), each holding its payload in
    // a value-child so the name stays intact for lookup. meta is conventionally
    // the first child and is excluded from the node's source identity.
    struct node *m = node_meta(t);
    if (!m) { m = node_new("meta"); node_prepend(t, m); }
    node_set_content(node_value(node_get_or_add(m, "elf")), (const char *)buf, n);
    node_set_content(node_value(node_get_or_add(m, "src")), (const char *)sid, 32);
    node_set_content(node_value(node_get_or_add(m, "bin")), (const char *)bid, 32);

    // info: the bytes, then the short source and binary ids.
    int pos = s_put(info, 0, t->content);
    pos = s_put(info, pos, ": ");
    static const char hx[] = "0123456789abcdef";
    for (int k = 0; k < n && pos < VGA_COLS - 26; k++) {
        info[pos++] = hx[buf[k] >> 4];
        info[pos++] = hx[buf[k] & 0xF];
        info[pos++] = ' ';
    }
    pos = s_put(info, pos, " src:");
    pos = s_puthash(info, pos, sid);
    pos = s_put(info, pos, " bin:");
    pos = s_puthash(info, pos, bid);
    info[pos] = '\0';
}

static void draw(void);

// Persist the whole tree as a new generation (via the kernel, which serializes
// it and writes it to disk). A later boot can pick it from the boot menu.
static void save_tree(void) {
    int g = sys_save(path[0]);
    int p;
    if (g >= 0) {
        p = s_put(info, 0, "saved generation ");
        p = s_puti(info, p, g);
        p = s_put(info, p, "  (reboot to pick it from the boot menu)");
    } else {
        p = s_put(info, 0, "save failed (generation log full or tree too big)");
    }
    info[p] = '\0';
}

// Edit the selected node's content in place: type to change it, Backspace to
// delete, Enter to commit (node_set_content), Esc to cancel. Editing a node — a
// mnemonic or an operand — changes its source id, so any cached binary on it (or
// an ancestor) goes stale until recompiled.
static void edit_selected(void) {
    struct node *cur = current();
    int s = sel[depth];
    if (cur->n_children == 0 || s >= cur->n_children) return;
    struct node *t = cur->children[s];

    char ebuf[VGA_COLS];
    int len = 0;
    for (int i = 0; i < t->content_len && len < VGA_COLS - 12; i++) {
        char c = t->content[i];
        ebuf[len++] = (c >= 0x20 && c < 0x7f) ? c : '?';   // printable preview
    }

    for (;;) {
        int p = s_put(info, 0, "edit: ");
        for (int i = 0; i < len && p < VGA_COLS - 2; i++) info[p++] = ebuf[i];
        if (p < VGA_COLS - 1) info[p++] = '_';             // cursor
        info[p] = '\0';
        draw();

        int k = sys_getkey();
        if (k == KEY_ENTER)      { node_set_content(t, ebuf, len); break; }
        if (k == KEY_ESC)        { break; }
        if (k == KEY_BACKSPACE)  { if (len > 0) len--; continue; }
        if (k >= 0x20 && k < 0x7f && len < VGA_COLS - 12) ebuf[len++] = (char)k;
    }
    info[s_put(info, 0, "a: compile   e: edit")] = '\0';
}

static void draw(void) {
    struct node *cur = current();
    int nkids = cur->n_children;

    fb_clear(BLUE);

    // ── title ─────────────────────────────────────────────
    fb_puts(0, 0, " ff - the trust project              "
                      "                                       ",
                BLACK, LIGHT_GREY);

    // ── breadcrumb (path to the current node) ─────────────
    int x = 0;
    for (int d = 0; d <= depth; d++) {
        vga_color fg = (d == depth) ? YELLOW : LIGHT_CYAN;
        fb_puts(x, 1, path[d]->content, fg, BLUE);
        x += (int)strlen(path[d]->content);
        if (d != depth) { fb_puts(x, 1, " > ", DARK_GREY, BLUE); x += 3; }
        if (x >= VGA_COLS - 4) break;
    }

    // ── current node + child count ────────────────────────
    fb_puts(0, 3, "node: ", LIGHT_GREY, BLUE);
    fb_puts(6, 3, cur->content, WHITE, BLUE);
    fb_puts(40, 3, "children: ", LIGHT_GREY, BLUE);
    {
        char num[12]; int n = nkids, i = 0;
        if (n == 0) num[i++] = '0';
        while (n > 0) { num[i++] = '0' + (n % 10); n /= 10; }
        char rev[12]; int k = 0;
        while (i--) rev[k++] = num[i];
        rev[k] = '\0';
        fb_puts(50, 3, rev, WHITE, BLUE);
    }

    // ── child list, windowed around the selection ─────────
    int s = sel[depth];
    int top = 0;
    if (nkids > LIST_ROWS) {
        top = s - LIST_ROWS / 2;
        if (top < 0) top = 0;
        if (top > nkids - LIST_ROWS) top = nkids - LIST_ROWS;
    }
    for (int row = 0; row < LIST_ROWS; row++) {
        int i = top + row;
        if (i >= nkids) break;
        struct node *kid = cur->children[i];
        int selected = (i == s);
        vga_color fg = selected ? BLACK : WHITE;
        vga_color bg = selected ? CYAN  : BLUE;
        // paint the whole row so the highlight is a full bar
        for (int cx = 0; cx < VGA_COLS; cx++)
            fb_putc(cx, LIST_TOP + row, ' ', fg, bg);
        fb_puts(2, LIST_TOP + row, selected ? ">" : " ", fg, bg);
        fb_puts(4, LIST_TOP + row, kid->content, fg, bg);
        // right-edge tag: compiled-binary freshness, else a subtree hint
        int ms = meta_state(kid);
        if (ms == 0)
            fb_puts(VGA_COLS - 8, LIST_TOP + row, "ok",
                    selected ? BLACK : LIGHT_GREEN, bg);
        else if (ms == 1)
            fb_puts(VGA_COLS - 8, LIST_TOP + row, "STALE",
                    selected ? BLACK : LIGHT_RED, bg);
        else if (kid->n_children)
            fb_puts(VGA_COLS - 6, LIST_TOP + row, "[+]",
                    selected ? BLACK : DARK_GREY, bg);
    }
    if (nkids == 0)
        fb_puts(4, LIST_TOP, "(leaf - no children)", DARK_GREY, BLUE);

    // ── assembler result line ─────────────────────────────
    fb_puts(0, INFO_ROW, info, LIGHT_GREEN, BLUE);

    // ── help ──────────────────────────────────────────────
    fb_puts(0, VGA_ROWS - 1,
                " arrows:navigate  a:compile  e:edit  s:save generation ",
                BLACK, LIGHT_GREY);

    sys_blit(fb);   // push the frame to the screen in one syscall
}

void navigator_run(struct node *root) {
    depth = 0;
    path[0] = root;
    sel[0] = 0;
    info[s_put(info, 0, "a: compile selected node to meta/elf   e: edit content")] = '\0';

    for (;;) {
        draw();
        int key = sys_getkey();
        struct node *cur = current();

        switch (key) {
        case KEY_UP:
            if (sel[depth] > 0) sel[depth]--;
            break;
        case KEY_DOWN:
            if (sel[depth] + 1 < cur->n_children) sel[depth]++;
            break;
        case KEY_RIGHT:
            if (cur->n_children > 0 && depth + 1 < MAX_DEPTH) {
                struct node *kid = cur->children[sel[depth]];
                depth++;
                path[depth] = kid;
                sel[depth] = 0;
            }
            break;
        case KEY_LEFT:
            if (depth > 0) depth--;
            break;
        case 'a':
            compile_selected();
            break;
        case 'e':
            edit_selected();
            break;
        case 's':
            save_tree();
            break;
        default:
            break;
        }
    }
}
