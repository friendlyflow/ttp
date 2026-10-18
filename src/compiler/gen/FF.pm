# FF.pm — the ff node tree for the host tools (mkff.pl, fftext.pl, s2ff.pl).
#
# A node is { content => bytes, children => [nodes] }. On disk (.ff) a node
# is written depth-first as
#
#   hash[32] · children_len u8 · children · content_len u8 · content
#
# with hash = sha256(child_0.hash ‖ … ‖ child_n.hash ‖ sha256(content)), as
# in the sicompass editor (texteditor-plugin-sicompass/src/ff.rs).
#
# As text (.ff.txt) the same tree is one node per line, indented two spaces
# per level, the way `ttpc file.ff` prints it. A file holds a list of nodes;
# a whole tree is written as the children of its root, whose content is
# empty. Content is escaped so that every line reads back exactly:
#
#   \\  backslash      \n  newline      \xNN  any other byte below 0x20,
#   \e  empty content                   0x7f, or a space at either end

package FF;

use strict;
use warnings;
use Digest::SHA qw(sha256);
use Exporter qw(import);

our @EXPORT_OK = qw(node call uncomment frozen is_layer kids holder layers read_ff write_ff read_txt write_txt);

sub node { my ($content, @children) = @_; { content => $content, children => \@children } }

# A call: name with leaf arguments.
sub call { my ($name, @args) = @_; node($name, map { node($_) } @args) }

# A layer: a function whose name is only digits (0: 1: ...), the overflow of
# its parent past the 255 children a node holds. Its children count as the
# parent's, in every scope, and a layer may hold layers (language.ff.txt).
sub is_layer { $_[0]{content} =~ /^[0-9]+:$/ }

# The children of n as a scope sees them: through its layers and theirs.
sub kids {
    my ($n, $depth) = @_;
    $depth //= 0;
    die "ff: layers nested too deep in $n->{content}\n" if $depth > 64;
    map { is_layer($_) ? kids($_, $depth + 1) : $_ } @{ $n->{children} };
}

# Nodes as the children of one node, which holds 255: in layers (0: 1: ...)
# where they are more than that, each 255 nodes or 255 layers of them, as
# deep as they need.
sub layers {
    my @n = @_;
    return @n if @n <= 255;
    my $per = 255;
    $per *= 255 while @n > $per * 255;
    my @l;
    for (my $i = 0; $i < @n; $i += $per) {
        my $e = $i + $per - 1 < $#n ? $i + $per - 1 : $#n;
        push @l, node(scalar(@l) . ':', layers(@n[$i .. $e]));
    }
    @l;
}

# Where the child of n (through its layers) with this content stands: the
# node that holds it and its index there; nothing if there is none.
sub holder {
    my ($n, $content, $depth) = @_;
    $depth //= 0;
    die "ff: layers nested too deep in $n->{content}\n" if $depth > 64;
    my $k = $n->{children};
    for my $i (0 .. $#$k) {
        return ($n, $i) if $k->[$i]{content} eq $content;
        if (is_layer($k->[$i])) { my @h = holder($k->[$i], $content, $depth + 1); return @h if @h }
    }
    ();
}

# The tree under n without its comments (comment with its text), all the way
# down. A leaf comment is data (ascii / comment) and stays.
sub uncomment {
    my ($n) = @_;
    node($n->{content},
        map { uncomment($_) } grep { !($_->{content} eq "comment" && @{ $_->{children} }) }
            @{ $n->{children} });
}

# The tree under n in the language of the frozen ttpc1 and stage0: without
# comments, and without a definition whose name has a space unless it is a
# register (its first child a bit string). They take any such definition
# with children for a register: else if: / condition would name registers
# else and if.
sub frozen {
    my ($n) = @_;
    my $k = $n->{children};
    return node("char", frozen($k->[1]))
        if $n->{content} eq "address" && @$k == 2 && $k->[0]{content} eq "char"
        && !@{ $k->[0]{children} } && !@{ $k->[1]{children} };
    node($n->{content},
        map { frozen($_) } grep {
            my $c = $_->{children};
            !($_->{content} eq "comment" && @$c)
                && !($_->{content} =~ / .*:$/ && @$c && !($c->[0]{content} =~ /^[01]+$/ && !@{ $c->[0]{children} }))
        } @{ $n->{children} });
}

# ---------------------------------------------------------------------------
# .ff
# ---------------------------------------------------------------------------

sub rehash {
    my ($n) = @_;
    my $d = Digest::SHA->new(256);
    $d->add(rehash($_)) for @{ $n->{children} };
    $d->add(sha256($n->{content}));
    $n->{hash} = $d->digest;
}

sub emit {
    my ($n) = @_;
    my $count = @{ $n->{children} };
    my $len = length $n->{content};
    die "ff: $n->{content} has $count children (max 255)\n" if $count > 255;
    die "ff: $n->{content} is $len bytes (max 255)\n" if $len > 255;
    die "ff: a node's text is not UTF-8: $n->{content}\n" unless utf8::decode(my $text = $n->{content});
    join "", $n->{hash}, chr($count), (map { emit($_) } @{ $n->{children} }),
        chr($len), $n->{content};
}

# The bytes of the tree under root.
sub write_ff {
    my ($root) = @_;
    rehash($root);
    emit($root);
}

# The root of the tree in bytes; dies on a truncated tree or a wrong hash.
sub read_ff {
    my ($bytes) = @_;
    my $pos = 0;
    my $take = sub {
        my ($len) = @_;
        die "ff: truncated node\n" if $pos + $len > length $bytes;
        my $s = substr($bytes, $pos, $len);
        $pos += $len;
        $s;
    };
    my $read;
    $read = sub {
        my $hash = $take->(32);
        my @children = map { $read->() } 1 .. ord $take->(1);
        my $n = node($take->(ord $take->(1)), @children);
        $n->{hash} = $hash;
        $n;
    };
    my $root = $read->();
    die "ff: trailing bytes after the root node\n" if $pos != length $bytes;
    my $stored = $root->{hash};
    rehash($root);
    die "ff: hash mismatch\n" if $stored ne $root->{hash};
    $root;
}

# ---------------------------------------------------------------------------
# .ff.txt
# ---------------------------------------------------------------------------

sub escape {
    my ($s) = @_;
    return "\\e" if $s eq "";
    $s =~ s/\\/\\\\/g;
    $s =~ s/\n/\\n/g;
    $s =~ s/([\x00-\x1f\x7f])/sprintf "\\x%02x", ord $1/ge;
    $s =~ s/^ /\\x20/;
    $s =~ s/ $/\\x20/;
    $s;
}

sub unescape {
    my ($s, $where) = @_;
    return "" if $s eq "\\e";
    $s =~ s/\\(?:(\\)|(n)|x([0-9a-fA-F]{2})|(.?))/
        defined $1 ? "\\" : defined $2 ? "\n" : defined $3 ? chr hex $3
        : die "ff: bad escape \\$4 at $where\n"/ge;
    $s;
}

# The lines of a list of nodes.
sub write_txt {
    my @lines;
    my $walk;
    $walk = sub {
        my ($n, $depth) = @_;
        push @lines, "  " x $depth . escape($n->{content}) . "\n";
        $walk->($_, $depth + 1) for @{ $n->{children} };
    };
    $walk->($_, 0) for @_;
    join "", @lines;
}

# The list of nodes in text; $name is for error messages.
sub read_txt {
    my ($text, $name) = @_;
    my @top;
    my @stack;                          # $stack[$d]: the last node at depth $d
    my $line = 0;
    for (split /\n/, $text) {
        $line++;
        my $where = "$name:$line";
        die "ff: empty line at $where\n" if $_ eq "";
        /^( *)(.*)$/;
        my ($indent, $text) = (length $1, $2);
        die "ff: odd indent at $where\n" if $indent % 2;
        my $depth = $indent / 2;
        die "ff: indent jumps at $where\n" if $depth > @stack;
        my $n = node(unescape($text, $where));
        if ($depth) { push @{ $stack[$depth - 1]{children} }, $n }
        else        { push @top, $n }
        splice @stack, $depth;
        push @stack, $n;
    }
    @top;
}

1;
