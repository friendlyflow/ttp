# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
# mkpages.py: all.ff.txt (c2ff's) -> s2ff.ff.txt (s2ff and its runtime in a group) and s2ff-start.ff.txt (its _start)
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
types = g['s2ff types']
shim = parse(open('shim.ff.txt').read().split('\n'))
def ren(n): return ['s2ff_main' if n[0] == 'main' else n[0], [ren(k) for k in n[1]]]
start = [ren(n) for n in parse(open('start.txt').read().split('\n'))]
out = []
for n in [['comment', [[l, []] for l in lines('s2ff.head')]], ['s2ff:', layers(shim + types + defs('s2ff s2ff.i'))]]: emit(n, 0, out)
open('s2ff.ff.txt', 'w').write('\n'.join(out) + '\n')
# _start on a page of its own after it, as cpp's (tools/dev/pp/mkpages.py)
out = []
for n in [['comment', [['the start of s2ff (tools/s2ff.ff), on its own page', []]]]] + start: emit(n, 0, out)
open('s2ff-start.ff.txt', 'w').write('\n'.join(out) + '\n')
