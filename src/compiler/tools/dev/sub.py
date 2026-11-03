# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# sub.py: edits of the dev C from a script, the safe way. A file is never opened
# for writing where it lies: open(f, 'w').write(open(f).read()) empties it
# (the 'w' comes first; so cl_x.c went on 2026-11-03).
#   from sub import sub; sub('cs/cl_x.c', old, new)
# old must be there exactly once, or nothing is written and it stops; the new
# text goes to a temporary file beside it, then a rename.
import os, tempfile

def write(path, text):
    old = os.path.getsize(path) if os.path.exists(path) else 0
    if not text or len(text) * 2 < old:
        raise SystemExit('sub.py: %s would shrink from %d to %d bytes: not written' % (path, old, len(text)))
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path) or '.', prefix='.sub.')
    with os.fdopen(fd, 'w', errors='surrogateescape') as h:
        h.write(text)
    os.replace(tmp, path)

def sub(path, old, new):
    with open(path, errors='surrogateescape') as h:
        s = h.read()
    if s.count(old) != 1:
        raise SystemExit('sub.py: %s holds this %d times, not once: %s' % (path, s.count(old), old[:80]))
    write(path, s.replace(old, new))
