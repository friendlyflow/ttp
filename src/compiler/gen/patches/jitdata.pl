# jitdata.pl: compile time's JIT leaves the target's globals put off
# alone. A program page with a writable global before a function whose
# compile time lambda runs (tools/cpp.ff's state with its _start on the
# same page; test cjitdata) stopped with "label moved between the
# passes: phdrs:": in the first pass the global was put off for the
# target (datadefer, data_vars), then the lambda's JIT compiled the page
# for the host, and its cc_library's dataplace placed the target's global
# in the host's image and emptied data_vars; the target's first pass then
# had no such global, its second pass had it. The JIT puts off none of
# its own (datadefer gives 0 there), so now dataplace and databound do
# nothing in it, and the target's round stays for the target.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/dataplace', asm(8, "
    enter3
    mv a0 s6
") => asm(8, "
    enter3
    mv a0 s6
    la ccs t0
    ld CC_jit t0 t0
    bnez X9 t0
"));
edit(\$t, 'cc/databound', asm(8, "
    la data_state t1
    ld 16 t1 t1
") => asm(8, "
    la ccs t1
    ld CC_jit t1 t1
    bnez B9 t1
    la data_state t1
    ld 16 t1 t1
"));
save();
