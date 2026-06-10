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

#include <stdio.h>
#include <stdlib.h>

/*
 * Bootstrap stage: for now the "compiler" just reads the OS boot-flow
 * disassembly and prints it verbatim, so we have an end-to-end build that
 * runs and produces output. Real compilation comes later (see PLAN.md).
 */
#define DEFAULT_INPUT "src/os/boot_flow.txt"

int main(int argc, char **argv)
{
	const char *path = (argc > 1) ? argv[1] : DEFAULT_INPUT;

	FILE *f = fopen(path, "rb");
	if (!f) {
		fprintf(stderr, "ttpc: cannot open '%s'\n", path);
		return EXIT_FAILURE;
	}

	char buf[4096];
	size_t n;
	while ((n = fread(buf, 1, sizeof buf, f)) > 0) {
		if (fwrite(buf, 1, n, stdout) != n) {
			fprintf(stderr, "ttpc: write error\n");
			fclose(f);
			return EXIT_FAILURE;
		}
	}

	if (ferror(f)) {
		fprintf(stderr, "ttpc: read error on '%s'\n", path);
		fclose(f);
		return EXIT_FAILURE;
	}

	fclose(f);
	return EXIT_SUCCESS;
}
