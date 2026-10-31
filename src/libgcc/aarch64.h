/* aarch64.h: gcc's aarch64 builtins of libgcc's unwinder (aarch64-unwind.h:
   pointer authentication and the guarded control stack) that clang has
   not, as functions for clang to read (clang's -include, as gcc has them);
   c2ff calls them as builtins (builtins-aarch64.ff.txt). A host file of ttp
   (src/libgcc), not part of libgcc. */
void *__builtin_aarch64_autia1716 (void *, unsigned long);
void *__builtin_aarch64_autib1716 (void *, unsigned long);
unsigned long __builtin_aarch64_chkfeat (unsigned long);
void *__builtin_aarch64_gcspr (void);
unsigned long __builtin_aarch64_gcspopm (void);
