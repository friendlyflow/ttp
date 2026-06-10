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
 * the host compiler. The serialized form below is a flat record stream — the
 * bootstrap stand-in for the eventual 4 KB on-disk DISK NODE blocks with their
 * child_lba block numbers (see src/compiler/PLAN.md); children are referenced by
 * array index instead of block number until a block allocator exists.
 */
#ifndef TTP_NODE_H
#define TTP_NODE_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

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

/* ---- serialization -------------------------------------------------------- */

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

/* Write the tree rooted at `root` as a flat record stream. Returns 0. */
static inline int node_write(FILE *f, struct node *root)
{
	struct node **arr = NULL;
	int len = 0, cap = 0;
	node__collect(root, &arr, &len, &cap);

	uint32_t cnt = (uint32_t)len;
	if (fwrite(&cnt, sizeof cnt, 1, f) != 1)
		return -1;
	for (int i = 0; i < len; i++) {
		struct node *n = arr[i];
		int32_t cl = n->content_len;
		int32_t nc = n->n_children;
		if (fwrite(n->id, 1, sizeof n->id, f) != sizeof n->id ||
		    fwrite(&cl, sizeof cl, 1, f) != 1 ||
		    (cl > 0 && fwrite(n->content, 1, (size_t)cl, f) != (size_t)cl) ||
		    fwrite(&nc, sizeof nc, 1, f) != 1) {
			free(arr);
			return -1;
		}
		for (int j = 0; j < n->n_children; j++) {
			int32_t ci = node__index(arr, len, n->children[j]);
			if (fwrite(&ci, sizeof ci, 1, f) != 1) {
				free(arr);
				return -1;
			}
		}
	}
	free(arr);
	return 0;
}

/* Read a flat record stream back into a tree; returns the root or NULL. */
static inline struct node *node_read(FILE *f)
{
	uint32_t cnt;
	if (fread(&cnt, sizeof cnt, 1, f) != 1 || cnt == 0)
		return NULL;

	struct node **nodes = (struct node **)calloc(cnt, sizeof(struct node *));
	for (uint32_t i = 0; i < cnt; i++) {
		struct node *n = (struct node *)calloc(1, sizeof *n);
		int32_t cl = 0, nc = 0;
		if (fread(n->id, 1, sizeof n->id, f) != sizeof n->id ||
		    fread(&cl, sizeof cl, 1, f) != 1 || cl < 0) {
			free(n); free(nodes); return NULL;
		}
		n->content_len = cl;
		n->content = (char *)malloc((size_t)cl + 1);
		if ((cl > 0 && fread(n->content, 1, (size_t)cl, f) != (size_t)cl) ||
		    fread(&nc, sizeof nc, 1, f) != 1 || nc < 0) {
			free(n->content); free(n); free(nodes); return NULL;
		}
		n->content[cl] = '\0';
		n->n_children = nc;
		n->children = nc ? (struct node **)malloc(
			(size_t)nc * sizeof(struct node *)) : NULL;
		for (int j = 0; j < nc; j++) {
			int32_t ci = 0;
			if (fread(&ci, sizeof ci, 1, f) != 1 ||
			    ci < 0 || (uint32_t)ci >= i) {   /* child precedes parent */
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

#endif /* TTP_NODE_H */
