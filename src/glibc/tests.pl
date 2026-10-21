#!/usr/bin/env perl
# tests.pl — glibc's own tests of an area (tests-ref in the Makefile): what
# glibc's build made of them, each one's run of gcc's build and of ttpc's
# against each other, and the table of all of them.
#
#   perl tests.pl mk <obj dir> <area> <pattern> > TBUILD/area.mk
#       the area's tests (the programs named <pattern>, a shell glob, that
#       the area's log links; or that its build failed to make), the
#       objects each is linked from (TOBJS_<test>: the area's own, without
#       glibc's startup, a shared module of its own as its object; TFILES_<test>
#       their files, x.o or x.os) and the libraries of glibc it is linked with
#       (TLIBS_<test>: libm, ... as their static libraries), the objects of
#       libsupport (SUPPORT), all relative to the obj dir, without .o
#   perl tests.pl why <log>
#       the line of a step's log that says why it failed
#   perl tests.pl run <dir> <test> <input> <slot command> -- <qemu> <cpu>...
#       runs dir/test.ref (gcc's) and dir/test-prog (ttpc's) on each cpu
#       (qemu -cpu), in dir/test.run, stdin from <input>, and prints the
#       result: "equal: ..." where every run exits with the same status
#       and prints the same (stdout and stderr), else "differ: ..."
#   perl tests.pl table <area> <target> <dir> <test>...
#       the table of dir/<test>.result: a line of counts, then a line per test
#
# A test's status is glibc's: 0 PASS, 77 UNSUPPORTED, anything else FAIL.
#
# A host tool (core Perl only).
use strict;
use warnings;
use Cwd ();

my $cmd = shift @ARGV // '';

if ($cmd eq 'mk') {
    my ($obj, $area, $pat) = @ARGV;
    my $real = Cwd::abs_path($obj);
    (my $re = $pat) =~ s/([^\w*?])/\\$1/g;
    $re =~ s/\*/[^\/\\s]*/g;
    $re =~ s/\?/[^\/\\s]/g;
    my $o = qr{(?:\Q$obj\E|\Q$real\E)};
    my (%tests, %objs, %files, %libs, %broken);
    open my $log, '<', "$obj/$area.log" or die "tests: cannot open $obj/$area.log: $!\n";
    while (my $l = <$log>) {
        # make's own word for a test it could not make: its program or object
        if ($l =~ m{^make\S*: \*\*\* \[\S+: $o/\Q$area\E/($re?)(?:\.o)?\] Error}) { $broken{$1} = 1; next }
        next if $l =~ / -c /;
        next unless $l =~ m{ -o $o/\Q$area\E/($re) };
        my $t = $1;
        next if $t =~ /\./;
        $tests{$t} = 1;
        my (@o, @f, @a);
        for my $w (split ' ', $l) {
            next unless $w =~ s{^$o/}{};
            next if $w =~ m{^csu/(?:S?crt1|crti|crtn|rcrt1|grcrt1)\.o$} || $w eq "$area/$t";
            if ($w =~ /^(.*)\.o$/) { push @o, $1; push @f, $w }
            # a shared module of the test's own (tst-x-mod.so): its object,
            # x.os, linked in
            elsif ($w =~ m{^(.*/(?!lib)[^/]+)\.so$} && -e "$obj/$1.os") { push @o, $1; push @f, "$1.os" }
            # a library of glibc's as the static library a static program
            # links (libm.so.6: math/libm.a); libc's own is libc.a there,
            # libsupport the test's always
            elsif ($w =~ m{^(?:(.*)/)?lib(\w+)\.(?:so[.\d]*|a)$}) {
                my ($d, $n) = ($1 // '', $2);
                next if $n =~ /^(?:c|c_nonshared|support|support_nonshared)$/ || $w =~ m{^elf/ld};
                push @a, ($d ne '' ? "$d/" : '') . "lib$n";
            }
        }
        $objs{$t} = \@o;
        $files{$t} = \@f;
        $libs{$t} = \@a;
    }
    close $log;
    delete $broken{$_} for keys %tests;
    my @support = map { chomp; s/\.oS$//; "support/$_" } `ar t $obj/support/libsupport_nonshared.a`;
    $? == 0 or die "tests: no libsupport_nonshared.a in $obj/support\n";
    print "# made by tests.pl from $obj/$area.log\n";
    print "TESTS := ", join(' ', sort(keys %tests, keys %broken)), "\n";
    print "TBROKEN := ", join(' ', sort keys %broken), "\n";
    for my $t (sort keys %tests) {
        print "TOBJS_$t := ", join(' ', @{ $objs{$t} }), "\n";
        print "TFILES_$t := ", join(' ', @{ $files{$t} }), "\n";
        print "TLIBS_$t := ", join(' ', @{ $libs{$t} }), "\n";
    }
    print "SUPPORT := ", join(' ', @support), "\n";
    exit 0;
}

if ($cmd eq 'why') {
    my ($f) = @ARGV;
    open my $h, '<', $f or do { print "no log\n"; exit 0 };
    my @l = grep { /\S/ && !/^make(?:\[\d+\])?: (?:\*\*\*|Entering|Leaving)/ && !/^slot\.sh: / } map { s/\s+$//r } <$h>;
    # a tool's own message first (c2ff:, ttpc:), then an error's (the
    # linker's; not a command's, whose file names may say error), else the
    # last line
    my ($why) = reverse grep { /^(?:c2ff|s2ff|ffsplit|fftext|mki|ttpc): / } @l;
    ($why) = reverse grep { !/^(?:sh|perl|qemu-\S+|\S*gcc) / && /error|undefined reference|cannot|timeout|Killed/i } @l unless defined $why;
    $why //= $l[-1] // 'no output';
    $why =~ s/^\s+//;
    $why = substr($why, 0, 200) . ' ...' if length $why > 200;
    print "$why\n";
    exit 0;
}

sub slurp { my ($f) = @_; open my $h, '<:raw', $f or return ''; local $/; <$h> }
sub status_word { my ($s) = @_; $s == 0 ? 'PASS' : $s == 77 ? 'UNSUPPORTED' : $s >= 128 ? 'FAIL, signal ' . ($s - 128) : 'FAIL' }

if ($cmd eq 'run') {
    my ($dir, $t, $input) = splice @ARGV, 0, 3;
    my @slot;
    push @slot, shift @ARGV while @ARGV && $ARGV[0] ne '--';
    shift @ARGV;
    my ($qemu, @cpus) = @ARGV;
    # (the slot command by its full path: each run is in a folder of its own)
    @slot = map { -e $_ ? Cwd::abs_path($_) : $_ } @slot;
    my $run = "$dir/$t.run";
    my %got;
    for my $b ("ref", "prog") {
        my $bin = Cwd::abs_path($b eq 'ref' ? "$dir/$t.ref" : "$dir/$t-prog");
        for my $cpu (@cpus) {
            (my $c = $cpu) =~ s/[^\w]+/_/g;
            my $out = "$dir/$t.$b.$c";
            system('rm', '-rf', $run);
            mkdir $run or die "tests: cannot make $run: $!\n";
            # (in a folder of its own, its temporary files there too; the
            # driver's timeouts scaled for qemu)
            my $pid = fork // die "tests: cannot fork: $!\n";
            if (!$pid) {
                chdir $run or die;
                open STDIN, '<', $input or die "tests: cannot open $input: $!\n";
                open STDOUT, '>', "$out.out" or die;
                open STDERR, '>', "$out.err" or die;
                $ENV{TMPDIR} = Cwd::abs_path('.');
                $ENV{TIMEOUTFACTOR} = 10;
                exec @slot, $qemu, '-cpu', $cpu, $bin or die "tests: cannot run $qemu: $!\n";
            }
            waitpid $pid, 0;
            my $s = $? & 127 ? 128 + ($? & 127) : $? >> 8;
            $got{$b}{$cpu} = [$s, slurp("$out.out"), slurp("$out.err")];
        }
    }
    system('rm', '-rf', $run);
    my ($want) = $got{ref}{ $cpus[0] };
    my @diff;
    for my $b ("ref", "prog") {
        for my $cpu (@cpus) {
            next if $b eq 'ref' && $cpu eq $cpus[0];
            my $g = $got{$b}{$cpu};
            my $who = ($b eq 'ref' ? "gcc's" : "ttpc's") . " on $cpu";
            if ($g->[0] != $want->[0]) { push @diff, "$who: exit $g->[0], gcc's on $cpus[0] $want->[0]" }
            elsif ($g->[1] ne $want->[1]) { push @diff, "$who: other output" }
            elsif ($g->[2] ne $want->[2]) { push @diff, "$who: other stderr" }
        }
    }
    my $s = $want->[0];
    if (@diff) { print "differ: ", join('; ', @diff), "\n" }
    else { print "equal: exit $s (", status_word($s), ")", @cpus > 1 ? ", on " . join(' and ', @cpus) : '', "\n" }
    exit 0;
}

if ($cmd eq 'table') {
    my ($area, $target, $dir, @tests) = @ARGV;
    my (%n, @lines);
    my $w = 0;
    $w < length and $w = length for @tests;
    for my $t (@tests) {
        my $r = slurp("$dir/$t.result");
        chomp $r;
        $r = 'not yet: no result' if $r eq '';
        my ($kind) = $r =~ /^(equal|differ)/;
        $n{ $kind // 'not yet' }++;
        push @lines, sprintf("  %-*s  %s\n", $w, $t, $r);
    }
    printf "tests-ref %s (%s): %d tests, %d equal, %d differ, %d not yet\n", $area, $target, scalar @tests,
        $n{equal} // 0, $n{differ} // 0, $n{'not yet'} // 0;
    print @lines;
    exit 0;
}

die "usage: tests.pl mk|why|run|table ...\n";
