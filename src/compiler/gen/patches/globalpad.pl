# globalpad.pl: a global ends on an 8-byte boundary, as one with a value did
# already: one without (a u8, _dl_tls_dtv_gaps) put the function after it on
# an odd address, where it cannot run (main's stdio-prog has
# _dlfo_read_version_locked there, which nothing calls; glibc's startup
# calls the resolver __libc_memcmp_ifunc, so placed: SIGILL).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;
edit(\$t, 'cc',
    "    L3:\n      mv\n        s4\n        a0\n      la\n        global\n        a1\n      call\n        place\n      j\n        L8\n",
    "    L3:\n" . asm(6, "
    mv s4 a0
    la global a1
    call place
    la cur_pc t0
    ld 0 t0 t0
    andi 7 t0 t1
    beqz L8 t1
    li 8 a0
    sub t1 a0 a0
    call skip
    j L8
"));
save();
