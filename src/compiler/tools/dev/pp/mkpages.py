# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
# mkpages.py: all.ff.txt (c2ff's) -> cpp.ff.txt (the preprocessor and its runtime in a group) and cpp-start.ff.txt (its _start)
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
def nohead(ns): return [[x[0], nohead(x[1])] if re.fullmatch(r'[0-9]+:', x[0]) else x for x in ns if x[0] not in ('comment', 'license')]
defs = lambda name: [clean(x) for x in nohead(g[name])]
types = g['cpp types']
shim = parse(open('shim.ff.txt').read().split('\n'))
def ren(n): return ['cpp_main' if n[0] == 'main' else n[0], [ren(k) for k in n[1]]]
start = [ren(n) for n in parse(open('start.txt').read().split('\n'))]
out = []
for n in [['comment', [[l, []] for l in lines('cpp.head')]], ['cpp:', layers(shim + types + defs('cpp pp.i'))]]: emit(n, 0, out)
open('cpp.ff.txt', 'w').write('\n'.join(out) + '\n')
# _start on a page of its own after it (it was a workaround: a group's cpp_main was unknown to it, now progroups.pl; and the JIT of its
# compile time placed the page's globals in the host's image, now jitdata.pl; so it could be on cpp.ff's page now)
out = []
for n in [['comment', [['the start of cpp (tools/cpp.ff), on its own page', []]]]] + start: emit(n, 0, out)
open('cpp-start.ff.txt', 'w').write('\n'.join(out) + '\n')
