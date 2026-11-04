# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
# mkpages.py: all.ff.txt (c2ff's) -> csem.ff.txt (library "c semantics") and csema.ff.txt (program)
import re
def parse(lines):
    root = ['', []]; stack = [(-1, root)]
    for l in lines:
        if not l.strip() or l.startswith('#'): continue
        d = (len(l) - len(l.lstrip(' '))) // 2
        n = [l.strip(' '), []]
        while stack[-1][0] >= d: stack.pop()
        stack[-1][1][1].append(n); stack.append((d, n))
    return root[1]
def lines(f): return [l for l in open(f).read().strip('\n').split('\n') if not l.startswith('#')]
def isnum(s): return re.fullmatch(r'[0-9]+', s) is not None
def clean(n):
    n = [re.sub(r'^text (\d+)(:?)$', r'csem text \1\2', n[0]), n[1]]
    k = [clean(x) for x in n[1] if not (x[0] == 'line' and x[1] and (isnum(x[1][-1][0]) and len(x[1]) <= 2))]
    return [n[0], k]
def emit(n, d, out):
    out.append('  ' * d + n[0])
    for k in n[1]: emit(k, d + 1, out)
def layers(ns):
    if len(ns) <= 255: return ns
    per = 255
    while len(ns) > per * 255: per *= 255
    return [['%d:' % (i // per), layers(ns[i:i + per])] for i in range(0, len(ns), per)]
top = parse(open('all.ff.txt').read().split('\n'))
g = {n[0].rstrip(':'): n[1] for n in top}
# (c2ff's comment and license of a unit, also inside its own layers, past 255: the page has the tools' license at its root)
def nohead(ns): return [[x[0], nohead(x[1])] if re.fullmatch(r'[0-9]+:', x[0]) else x for x in ns if x[0] not in ('comment', 'license')]
defs = lambda name: [clean(x) for x in nohead(g[name])]
types = [t for t in g['csema types'] if t[0] != 'node:']
desc = lines('csem.head')
lib = [['comment', [[l, []] for l in desc]], ['c semantics:', layers(types + defs('csema cs.i'))]]
out = []
for n in lib: emit(n, 0, out)
open('csem.ff.txt', 'w').write('\n'.join(out) + '\n')
head = lines('csema.head')
out = []
for n in [['comment', [[l, []] for l in head]], ['csema:', layers(defs('csema csema_main.i'))]]: emit(n, 0, out)
open('csema.ff.txt', 'w').write('\n'.join(out) + '\n')
# each target's program page: _start, as every tool's but of this target's registers alone, and setjmp and longjmp:
# with compile time on the page it would all be compiled for the host too, whose ttpc has no such instructions
def ren(n): return ['csema_main' if n[0] == 'main' else n[0], [ren(k) for k in n[1]]]
lines_ = [l for l in open('start.txt').read().rstrip('\n').split('\n') if not l.startswith('#')]
for t, reg, off in (('riscv64', 's0', 16), ('x86_64', 'rbp', 16), ('aarch64', 'x29', 16), ('arm', 'r11', 8)):
    a = lines_.index('  :')
    b = lines_.index('  status:')
    s = lines_[:a] + ['  stack', '  =', '  cast', '    long', '    * pointer', '  :', '    ' + reg, '    +', '    %d' % off,
        '  cp_jump', '    0', '  =', '  cp_setjmp', '  & address', '  cp_jump', '    1', '  =', '  cp_longjmp', '  & address'] + lines_[b:]
    st = [ren(n) for n in parse(s)] + parse(open('jump-%s.txt' % t).read().split('\n'))
    out = []
    for n in [['comment', [[l, []] for l in ('csema on ' + t + ": its start, and what -k's failures go back through",)]]] + st: emit(n, 0, out)
    open('csema-%s.ff.txt' % t, 'w').write('\n'.join(out) + '\n')
