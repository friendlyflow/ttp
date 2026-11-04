# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
# mkpages.py: all.ff.txt (c2ff's) -> c.ff.txt (library "c parser"), cparse.ff.txt, cprint.ff.txt
import sys, re
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
# (c2ff's comment and license of a unit, also inside its own layers, past 255: the page has the tools' license at its root)
def nohead(ns): return [[x[0], nohead(x[1])] if re.fullmatch(r'[0-9]+:', x[0]) else x for x in ns if x[0] not in ('comment', 'license')]
defs = lambda name: [clean(x) for x in nohead(g[name])]
types = [t for t in g['cparse types'] if t[0] != 'node:']
shim = parse(open('shim.ff.txt').read().split('\n'))
desc = lines('c.head')
lib = [['comment', [[l, []] for l in desc]], ['c parser:', layers(shim + types + defs('cparse c.i'))]]
out = []
for n in lib: emit(n, 0, out)
open('c.ff.txt', 'w').write('\n'.join(out) + '\n')
start = parse(open('start.txt').read().split('\n'))
for prog in ('cparse', 'cprint'):
    st = [x for x in start]
    def ren(n):
        return [prog + '_main' if n[0] == 'main' else n[0], [ren(k) for k in n[1]]]
    st = [ren(n) for n in st]
    head = lines(prog + '.head')
    out = []
    for n in [['comment', [[l, []] for l in head]]] + st + defs('cparse %s_main.i' % prog): emit(n, 0, out)
    open(prog + '.ff.txt', 'w').write('\n'.join(out) + '\n')
