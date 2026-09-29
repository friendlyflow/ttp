# boot_flow.awk — turn `objdump -D` of os.elf into the boot_flow.txt ttpc reads.
#
# On every instruction line it rewrites two columns (see DISASSEMBLY.md):
#   address: runtime address -> file offset in os.bin (minus BASE), since ttpc
#            writes each line's bytes at the offset in its first column;
#   bytes:   objdump prints a RISC-V instruction as one little-endian number
#            (f14022f3); ttpc wants the bytes in memory order (f3 22 40 f1).
# Labels, branch targets and comments keep their runtime addresses.

function hex(s,    n, i) {
    n = 0
    s = tolower(s)
    for (i = 1; i <= length(s); i++)
        n = n * 16 + index("0123456789abcdef", substr(s, i, 1)) - 1
    return n
}

BEGIN { FS = OFS = "\t"; BASE = hex("80000000") }

/^ *[0-9a-f]+:\t[0-9a-f]+ *(\t|$)/ {
    a = $1; sub(/^ */, "", a); sub(/:$/, "", a)
    $1 = sprintf("%8x:", hex(a) - BASE)

    w = $2; sub(/ +$/, "", w)
    b = ""
    for (i = length(w) - 1; i >= 1; i -= 2)
        b = b (b == "" ? "" : " ") substr(w, i, 2)
    $2 = sprintf("%-12s", b)
}

# objdump names the input by its full path; keep the file machine-independent.
/: +file format / { sub(/^.*\//, "") }

{ print }
