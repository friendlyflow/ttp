# tlslast.pl: the TLS image is placed after the data a program puts off,
# not before. cc_library placed what it had put off in the order ctplace,
# secplace, tlsplace, dataplace, each round going back to compile what that
# reached; a function that only the data reaches (an initializer's
# function pointer: glibc's vtables, a program taking every global's
# address) could reach a thread local after the image was placed, and ttpc
# stopped: "a thread local reached only from a thread local's value"
# (src/glibc's datacheck: tls_dtor_list, _nl_current_LC_CTYPE). Now
# dataplace comes before tlsplace; what a thread local's value reaches
# after that (data_state set) is placed as reached, after the image.
# Test ctlslate (4 targets).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc_library', asm(10, "
    call tlsplace
    bnez L5 a0
    mv s4 a0
    call dataplace
    bnez L5 a0
") => asm(10, "
    mv s4 a0
    call dataplace
    bnez L5 a0
    call tlsplace
    bnez L5 a0
"));
save();
