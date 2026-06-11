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

/*
 * node.h — the trust project's content node.
 *
 * A NODE is the universal record of the system: a blob of `content` plus an
 * ordered list of child nodes, content-addressed by `id` (a hash of the content
 * and the child ids — reserved here, filled once hashing lands). Code is written
 * as nodes: an instruction is a node whose content is the mnemonic and whose
 * children are its operands, e.g. `xor rax, rax` is the node "xor" with children
 * "rax" and "rax". ttpc's `-a` mode reads such a tree and assembles it.
 *
 * This header is owned by the OS (nodes are the OS's data model) and shared with
 * the host compiler. The two builds differ only in I/O:
 *
 *   - The freestanding CORE (struct, builder, and the buffer-based
 *     node_read_mem / node_write_mem serialization) needs only malloc/realloc/
 *     calloc/free/memcpy/strlen. The OS supplies these (heap.c, string.c), so
 *     the kernel can build and serialize trees without libc.
 *
 *   - The host adds FILE* convenience wrappers (node_read / node_write) when it
 *     defines TTP_HOSTED; they just slurp/spill a file around the mem core.
 *
 * The serialized form is a flat record stream — the bootstrap stand-in for the
 * eventual 4 KB on-disk DISK NODE blocks with their child_lba block numbers
 * (see src/compiler/PLAN.md); children are referenced by array index instead of
 * block number until a block allocator exists.
 */
#ifndef TTP_NODE_H
#define TTP_NODE_H

#include <stdint.h>
#include <stddef.h>

#ifdef TTP_HOSTED
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
#else
  /* Freestanding: declare the libc subset the OS implements (heap.c/string.c).
     Prototypes match those headers, so including them too is harmless. */
  void  *malloc(size_t);
  void  *calloc(size_t, size_t);
  void  *realloc(void *, size_t);
  void   free(void *);
  void  *memcpy(void *, const void *, size_t);
  size_t strlen(const char *);
#endif

struct node {
	unsigned char  id[32];       /* content hash — reserved (zero for now)   */
	int            n_children;
	struct node  **children;     /* rebuilt on load, not stored as pointers   */
	int            content_len;  /* no NUL termination (content may be binary) */
	char          *content;      /* NUL-terminated copy kept for convenience  */
};

/* ---- builder -------------------------------------------------------------- */

static inline struct node *node_new(const char *content)
{
	struct node *n = (struct node *)calloc(1, sizeof *n);
	n->content_len = content ? (int)strlen(content) : 0;
	n->content = (char *)malloc((size_t)n->content_len + 1);
	if (content)
		memcpy(n->content, content, (size_t)n->content_len);
	n->content[n->content_len] = '\0';
	return n;
}

static inline void node_add(struct node *parent, struct node *child)
{
	parent->children = (struct node **)realloc(
		parent->children,
		(size_t)(parent->n_children + 1) * sizeof(struct node *));
	parent->children[parent->n_children++] = child;
}

/* Append a fresh leaf child carrying `content`; returns the child. */
static inline struct node *node_kid(struct node *parent, const char *content)
{
	struct node *c = node_new(content);
	node_add(parent, c);
	return c;
}

/* ---- meta convention -----------------------------------------------------
 * A node may carry a child tagged by the reserved content "meta" (conventionally
 * first). It holds compiled artifacts (meta/elf) and provenance, and is excluded
 * from the operand/source walks — so it never shifts operand positions and the
 * source hash stays stable when only the cached binary changes. meta is found by
 * its tag, not its index, so it survives sorting and any child reordering.
 */

/* Does this node's content equal the NUL-terminated string s? (binary-safe) */
static inline int node_is(const struct node *n, const char *s)
{
	int i = 0;
	for (; s[i]; i++)
		if (i >= n->content_len || n->content[i] != s[i])
			return 0;
	return i == n->content_len;
}

/* The node's meta child, or NULL. */
static inline struct node *node_meta(struct node *n)
{
	for (int i = 0; i < n->n_children; i++)
		if (node_is(n->children[i], "meta"))
			return n->children[i];
	return NULL;
}

/* Count / index the non-meta children — the operands (or body) the encoder and
   the source hash see. node_operand(n, i) returns the i-th, or NULL. */
static inline int node_noperands(struct node *n)
{
	int c = 0;
	for (int i = 0; i < n->n_children; i++)
		if (!node_is(n->children[i], "meta"))
			c++;
	return c;
}
static inline struct node *node_operand(struct node *n, int idx)
{
	for (int i = 0; i < n->n_children; i++) {
		if (node_is(n->children[i], "meta"))
			continue;
		if (idx-- == 0)
			return n->children[i];
	}
	return NULL;
}

/* The child whose content equals `name`, or NULL. */
static inline struct node *node_child(struct node *n, const char *name)
{
	for (int i = 0; i < n->n_children; i++)
		if (node_is(n->children[i], name))
			return n->children[i];
	return NULL;
}

/* The child named `name`, creating an empty leaf if absent. */
static inline struct node *node_get_or_add(struct node *n, const char *name)
{
	struct node *c = node_child(n, name);
	return c ? c : node_kid(n, name);
}

/* The single value-child of `n`, creating it if absent. A named node keeps its
   name in its content; its payload (e.g. meta/elf's bytes) lives in this child,
   so storing the payload never clobbers the name used to look the node up. */
static inline struct node *node_value(struct node *n)
{
	if (n->n_children == 0)
		node_kid(n, "");
	return n->children[0];
}

/* Replace a node's content with `len` bytes (binary-safe; NUL-terminated copy). */
static inline void node_set_content(struct node *n, const char *data, int len)
{
	n->content = (char *)realloc(n->content, (size_t)len + 1);
	if (len > 0 && data)
		memcpy(n->content, data, (size_t)len);
	n->content[len] = '\0';
	n->content_len = len;
}

/* Insert `child` as the first child of `parent` (used to keep meta in front). */
static inline struct node *node_prepend(struct node *parent, struct node *child)
{
	node_add(parent, child);
	for (int i = parent->n_children - 1; i > 0; i--)
		parent->children[i] = parent->children[i - 1];
	parent->children[0] = child;
	return child;
}

/* ---- serialization core (freestanding) ------------------------------------ */

static inline void node__collect(struct node *n, struct node ***arr,
				 int *len, int *cap)
{
	for (int i = 0; i < n->n_children; i++)
		node__collect(n->children[i], arr, len, cap);
	if (*len == *cap) {
		*cap = *cap ? *cap * 2 : 16;
		*arr = (struct node **)realloc(*arr,
			(size_t)*cap * sizeof(struct node *));
	}
	(*arr)[(*len)++] = n;          /* post-order: children before parent */
}

static inline int node__index(struct node **arr, int len, struct node *n)
{
	for (int i = 0; i < len; i++)
		if (arr[i] == n)
			return i;
	return -1;
}

/* Copy `sz` bytes into buf at *pos when there is room; always advance *pos so a
   NULL/short buffer still computes the total length (dry run). */
static inline void node__put(unsigned char *buf, size_t cap, size_t *pos,
			     const void *src, size_t sz)
{
	if (buf && *pos + sz <= cap)
		memcpy(buf + *pos, src, sz);
	*pos += sz;
}

/* Serialize the tree rooted at `root` into buf (capacity cap). With buf==NULL it
   only measures: *out_len gets the byte count and it returns 0. With a real buf
   it returns 0 on success, -1 if cap was too small (*out_len still set). */
static inline int node_write_mem(struct node *root, unsigned char *buf,
				 size_t cap, size_t *out_len)
{
	struct node **arr = NULL;
	int len = 0, acap = 0;
	node__collect(root, &arr, &len, &acap);

	size_t pos = 0;
	uint32_t cnt = (uint32_t)len;
	node__put(buf, cap, &pos, &cnt, sizeof cnt);
	for (int i = 0; i < len; i++) {
		struct node *n = arr[i];
		int32_t cl = n->content_len;
		int32_t nc = n->n_children;
		node__put(buf, cap, &pos, n->id, sizeof n->id);
		node__put(buf, cap, &pos, &cl, sizeof cl);
		if (cl > 0)
			node__put(buf, cap, &pos, n->content, (size_t)cl);
		node__put(buf, cap, &pos, &nc, sizeof nc);
		for (int j = 0; j < n->n_children; j++) {
			int32_t ci = node__index(arr, len, n->children[j]);
			node__put(buf, cap, &pos, &ci, sizeof ci);
		}
	}
	free(arr);
	if (out_len)
		*out_len = pos;
	return (buf && pos > cap) ? -1 : 0;
}

/* Rebuild a tree from a flat record stream in memory; returns root or NULL. */
static inline struct node *node_read_mem(const unsigned char *buf, size_t len)
{
	size_t pos = 0;
	uint32_t cnt;
	if (len < sizeof cnt)
		return NULL;
	memcpy(&cnt, buf + pos, sizeof cnt); pos += sizeof cnt;
	if (cnt == 0)
		return NULL;

	struct node **nodes = (struct node **)calloc(cnt, sizeof(struct node *));
	for (uint32_t i = 0; i < cnt; i++) {
		struct node *n = (struct node *)calloc(1, sizeof *n);
		int32_t cl = 0, nc = 0;
		if (pos + sizeof n->id + sizeof cl > len) {
			free(n); free(nodes); return NULL;
		}
		memcpy(n->id, buf + pos, sizeof n->id); pos += sizeof n->id;
		memcpy(&cl, buf + pos, sizeof cl);       pos += sizeof cl;
		if (cl < 0 || pos + (size_t)cl + sizeof nc > len) {
			free(n); free(nodes); return NULL;
		}
		n->content_len = cl;
		n->content = (char *)malloc((size_t)cl + 1);
		if (cl > 0)
			memcpy(n->content, buf + pos, (size_t)cl);
		pos += (size_t)cl;
		n->content[cl] = '\0';
		memcpy(&nc, buf + pos, sizeof nc); pos += sizeof nc;
		if (nc < 0 || pos + (size_t)nc * sizeof(int32_t) > len) {
			free(n->content); free(n); free(nodes); return NULL;
		}
		n->n_children = nc;
		n->children = nc ? (struct node **)malloc(
			(size_t)nc * sizeof(struct node *)) : NULL;
		for (int j = 0; j < nc; j++) {
			int32_t ci = 0;
			memcpy(&ci, buf + pos, sizeof ci); pos += sizeof ci;
			if (ci < 0 || (uint32_t)ci >= i) {   /* child precedes parent */
				free(n->children); free(n->content);
				free(n); free(nodes); return NULL;
			}
			n->children[j] = nodes[ci];
		}
		nodes[i] = n;
	}
	struct node *root = nodes[cnt - 1];     /* root written last */
	free(nodes);
	return root;
}

/* ---- host FILE* convenience (libc only) ----------------------------------- */
#ifdef TTP_HOSTED

/* Read a flat record stream from a file; returns the root or NULL. */
static inline struct node *node_read(FILE *f)
{
	if (fseek(f, 0, SEEK_END) != 0)
		return NULL;
	long sz = ftell(f);
	if (sz <= 0 || fseek(f, 0, SEEK_SET) != 0)
		return NULL;
	unsigned char *buf = (unsigned char *)malloc((size_t)sz);
	if (!buf)
		return NULL;
	struct node *root = NULL;
	if (fread(buf, 1, (size_t)sz, f) == (size_t)sz)
		root = node_read_mem(buf, (size_t)sz);
	free(buf);
	return root;
}

/* Write the tree rooted at `root` as a flat record stream. Returns 0. */
static inline int node_write(FILE *f, struct node *root)
{
	size_t need = 0;
	node_write_mem(root, NULL, 0, &need);          /* measure */
	unsigned char *buf = (unsigned char *)malloc(need);
	if (!buf)
		return -1;
	int rc = node_write_mem(root, buf, need, NULL);
	if (rc == 0 && fwrite(buf, 1, need, f) != need)
		rc = -1;
	free(buf);
	return rc;
}

#endif /* TTP_HOSTED */

#endif /* TTP_NODE_H */
