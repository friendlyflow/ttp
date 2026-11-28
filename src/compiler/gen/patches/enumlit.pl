# enumlit.pl: in a value position an enum constant wins over a type of the
# same name (the master's fault 31, GNU make's main.c: enum { flag, ...,
# string, strlist, filename, ... } and glibc's struct strlist: case strlist
# stopped "cannot compile: strlist"; the user's rule A, position decides).
# litk took a leaf that names a struct or union type (the program's,
# cxlabel, or a library's, libtype) for a compound literal of it, asking
# only whether a local of that name hides it (vfind); now an enum constant
# the code sees (enumconst: the scopes', the program's or its library
# group's, then the pages') is a value too, so the leaf is no literal. A
# type position (a declaration's type, a cast, sizeof of a type form) does
# not ask litk and still takes the type. Test: progs/cenumlit.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;
edit(\$t, 'cc/litk', "        K50:\n" => "        K50:\n" . asm(10, "
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    call enumconst
    bnez KL9 a0
"));
save();
