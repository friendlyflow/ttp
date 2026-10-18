# include.pl: the word import is include (the user's choice, 2026-10-18,
# "to stay more C"), for a tree and for a library's folder alike: in the
# C layer's words (cc_kw, where it keeps its place: the words after it move
# one byte, which nothing reads at a fixed place), program_root's is_import
# and code_call's skip of it (7 bytes now), and the message that it goes
# first. ttpc's own function include (a section's groups put in scope)
# becomes include_section, so the word and the label are never confused.
# Its own names follow: is_import is is_include, msg_import msg_include
# (and msg_include_len and KW_include, on ttpc.defs.ff: T=ttpc.defs.ff).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

if ($t =~ /^ttpc:\n/m) {
    my $n = () = $t =~ /^ *msg_import(?:_len)?:?\n/mg;
    die "include: msg_import found $n times, not 2\n" unless $n == 2;
    $t =~ s/^( *)msg_import(_len)?(:?)\n/$1msg_include$2$3\n/mg;
    once(\$t, "  KW_import:\n", "  KW_include:\n", 'KW_import');
    save();
    exit;
}

once(\$t, 'target\x00import\x00workspace', 'target\x00include\x00workspace', 'cc_kw');
# is_import and code_call: cc_kw + 128, 6 bytes -> 7
my $re = qr/^( *)la\n\1  cc_kw\n\1  a1\n\1addi\n\1  128\n\1  a1\n\1  a1\n\1li\n\1  6\n\1  a2\n/m;
my $n = () = $t =~ /$re/g;
die "include: cc_kw + 128, 6 found $n times, not 2\n" unless $n == 2;
$t =~ s/$re/$1la\n$1  cc_kw\n$1  a1\n$1addi\n$1  128\n$1  a1\n$1  a1\n$1li\n$1  7\n$1  a2\n/g;
once(\$t, "      ttpc: import goes first\\n\n", "      ttpc: include goes first\\n\n", 'msg_import');

# the label include, called and taken
my $k = () = $t =~ /^ *include:?\n/mg;
$t =~ s/^( *)include(:?)\n/$1include_section$2\n/mg;
die "include: no label include\n" unless $k;
warn "include: $k nodes include -> include_section\n";
my $m = () = $t =~ /^ *(?:is_import|msg_import|msg_import_len):?\n/mg;
die "include: is_import and msg_import found $m times\n" unless $m == 6;
$t =~ s/^( *)is_import(:?)\n/$1is_include$2\n/mg;
$t =~ s/^( *)msg_import(_len)?(:?)\n/$1msg_include$2$3\n/mg;
# the comments of the lazy library's functions
for (['the tree a0, imported whole,', 'the tree a0, included whole,'],
     ['the import of the path a0', 'the include of the path a0'],
     ['with a library imported:', 'with a library included:'],
     ['those of the trees it imports whole', 'those of the trees it includes whole']) {
    once(\$t, $_->[0], $_->[1], 'a comment');
}
save();
