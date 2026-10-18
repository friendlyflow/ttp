# defpages.pl (T=ttpc.defs.ff): ttpc's definitions, one page of 255 (all a
# node holds), as pages by meaning. Every definition page is in scope, so
# nothing else changes:
#   ttpc:          Linux, characters, the tree's and the passes' layouts and
#                  limits, registers, enter/leave
#   messages:      the lengths of the messages
#   c layer:       its types, variables, state (CC_), keywords, operators,
#                  compile time
#   build files:   workspaces and the build state
our $t; do "$ENV{PATCHLIB}" or die $@;
my @pages = tree();
die "defpages: already split\n" if @pages != 1 || $pages[0]{content} ne 'ttpc:';
my (%page, @order);
for my $d (@{ $pages[0]{children} }) {
    (my $n = $d->{content}) =~ s/:$//;
    my $p = $n =~ /^msg_\w+_len$/ ? 'messages:'
        : $n =~ /^(TY_|VAR_|MAX_TYPES$|MAX_VARS$|CC_|KW_|CT_|MAX_CT$|JIT_frame$|CH_f$)/ ? 'c layer:'
        : $n =~ /^OP_/ && $n !~ /^OP_(code|size)$/ ? 'c layer:'
        : $n =~ /^(MAX_WS|MAX_WSFILES|MAX_TREES|MAX_PAGES|WS_|BS_)/ ? 'build files:'
        : 'ttpc:';
    push @{ $page{$p} }, $d;
}
for (qw(ttpc: messages: c\ layer: build\ files:)) { die "defpages: $_ holds " . @{ $page{$_} } . "\n" if @{ $page{$_} } > 255 }
untree(map { FF::node($_, @{ $page{$_} }) } 'ttpc:', 'messages:', 'c layer:', 'build files:');
save();
