# split.pl: ttpc.ff's page (251 of the 255 children a node holds, and
# mkhost.pl adds 4) and its cc group (255) in layers, the user's overflow of
# a node (0: 1: 2:, whose children count as the parent's; see
# language.ff.txt), cut where the meaning changes:
#   the page: origin and elf_header, then 0: the assembler (_start .. exit),
#     1: the C layer and the constant data (cc .. the tables), 2: the
#     variables and the memory (hexbuf .. mem_end)
#   cc: its own code, then 0: types and expressions (kind ..), 1: statements
#     (stmts ..), 2: definitions, the library, compile time and build files
#     (libbase ..)
# A layer is placed as a label: the bytes ttpc makes are the same.
our $t; do "$ENV{PATCHLIB}" or die $@;
my @page = tree();
sub at {
    my ($list, $name) = @_;
    my ($i) = grep { $list->[$_]{content} eq $name } 0 .. $#$list;
    defined $i or die "split: no $name\n";
    $i;
}
sub layer {
    my ($name, $what, @n) = @_;
    die "split: layer $name would hold " . (@n + 1) . " children\n" if @n >= 255;
    FF::node($name, FF::node('comment', FF::node($what)), @n);
}
die "split: already in layers\n" if grep { $_->{content} =~ /^\d+:$/ } @page;
my ($s, $c, $v) = (at(\@page, '_start:'), at(\@page, 'cc:'), at(\@page, 'hexbuf:'));
$v-- if $page[$v - 1]{content} eq 'align';
my $cc = $page[$c];
my @k = @{ $cc->{children} };
my ($ki, $st, $lb) = (at(\@k, 'kind:'), at(\@k, 'stmts:'), at(\@k, 'libbase:'));
$cc->{children} = [@k[0 .. $ki - 1],
    layer('0:', 'the C layer, types and expressions: kinds, types, conversions, lookup, the primitives, loads and stores, items, expressions, operators, paths, structs, calls', @k[$ki .. $st - 1]),
    layer('1:', 'the C layer, statements: blocks, if, while, for, do while, switch, goto, enums, bitfields, globals and their items, the frame, varargs', @k[$st .. $lb - 1]),
    layer('2:', 'the C layer, definitions: the library (what a program reaches of the pages before it), ifuncs, declarations, functions, compile time and its jit, build files, its messages', @k[$lb .. $#k])];
untree(@page[0 .. $s - 1],
    layer('0:', 'the assembler: reading the trees, the passes, lookup, the arguments, exec, encoding, the output, the errors', @page[$s .. $c - 1]),
    layer('1:', 'the C layer, then the constant data: messages, names, the tables of the C layer and its primitives', @page[$c .. $v - 1]),
    layer('2:', 'the variables, then the memory (bss): the trees, the labels, the buffers, the C layer\'s tables', @page[$v .. $#page]));
save();
