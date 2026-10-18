# lazyorder.pl: the files of a library read lazily go in front of the
# program in the order of its index (which is its pages' order), not in the
# order the reach met them: so a name that two pages define (a struct type
# sysinfo, and the asm function sysinfo of misc/sysinfo.S) is the same one
# a whole include of the tree finds. lazyload keeps the root of a file in
# its slot (+24); lazyrun puts them in, in the slots' order, when the reach
# is done.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'lazyload',
    "    mv\n      a0\n      s5\n    call\n      add_page\n",
    "    mv\n      a0\n      s5\n    sd\n      24\n      s5\n      s4\n");
once(\$t, "      the file of slot a0 read, once: put in front of the program, its definitions in their entries\n",
    "      the file of slot a0 read, once, its root kept in the slot (lazyrun puts it in front of the program), its definitions in their entries\n", 'lazyload\'s comment');
edit(\$t, 'lazyfile',
    "      sd\n        16\n        zero\n        a0\n",
    "      sd\n        16\n        zero\n        a0\n      sd\n        24\n        zero\n        a0\n");
edit(\$t, 'lazyrun', "    U9:\n      mv\n        s4\n        a0\n      leave3\n", asm(4, "
    U9:
    la lazy s5
    li 0 s6
    U10:
    ld LZ_nfiles s5 t0
    bgeu rel:U12 t0 s6
    slli 5 s6 t1
    lui LZ_files t2
    add t2 t1 t1
    add s5 t1 t1
    ld 16 t1 t2
    beqz U11 t2
    ld 24 t1 a0
    call add_page
    U11:
    addi 1 s6 s6
    j U10
    U12:
    mv s4 a0
    leave3
"));
once(\$t, "until none is new (a0 kept)\n", "until none is new (a0 kept)\n      then the files read go in front of the program, in the order of the index\n", 'lazyrun\'s comment');
save();
