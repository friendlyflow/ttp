# startparam.pl: _start takes no parameters. A local first in a body with
# only its type is one more parameter (language.ff.txt), so _start: / void
# / p: / big made p a parameter of the program's entry, which nothing
# calls: on riscv64 and aarch64 a struct of more than 16 bytes goes by its
# address, a0 or x0 at the entry, and writing p crashed the program; on
# x86_64 and arm it was the stack's words. No message (datacheck's tests
# kept such locals out of _start). Now fnbody stops where _start has a
# parameter, naming it. Test cstartparam (ctime, every target).
#
# Run on ttpc.ff, then with T=ttpc.defs.ff (its message's length).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

if ($t =~ /^ttpc:\n/m) {
    once(\$t, "  msg_untyped_len:\n    size\n      msg_untyped\n",
        "  msg_untyped_len:\n    size\n      msg_untyped\n  msg_startp_len:\n    size\n      msg_startp\n", 'msg_untyped_len');
    save();
    exit;
}

edit(\$t, 'cc/fnbody', asm(10, "
    call nparams
    mv a0 s11
") => asm(10, "
    call nparams
    mv a0 s11
    mv s4 a0
    mv s11 a1
    mv s6 a2
    call nostartp
"));

# nostartp (a0 the function, a1 its count of parameters, a2 where they
# begin): a _start with one stops, named
my ($from, $to) = find(\$t, 'cc/fnbody');
substr($t, $to, 0) = fn('nostartp', "
    enter1
    beqz P9 a1
    mv a2 s4
    lbu NODE_content_len a0 t0
    li 7 t1
    bne rel:P9 t1 t0
    ld NODE_content a0 a0
    li 6 a1
    la ifnames a2
    addi 26 a2 a2
    li 6 a3
    call streq
    beqz P9 a0
    ld 0 s4 a0
    la msg_startp a1
    li msg_startp_len a2
    j diename
P9:
    leave1
", 6);

my ($mf, $mt) = find(\$t, 'msg_untyped');
substr($t, $mt, 0) = "      msg_startp:\n        ascii\n          ttpc: _start has no caller to pass it a parameter; give a local first in its body a value (r:, point, 0):\\x20\n";
save();
