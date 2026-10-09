- reverse engineer keccak richting asm instructions

- create first instructions, then go to -->

- create hash function in asm

- read first stage of bootstage1.asm
- make it to knitter in assembly


- .knit file:
cb8e93ac: --> header
    wat statistiek over code
comment:
mov: --> functie
    a23fb87d: --> header (is a hash of bla1 en bla2)
        length van volgende lijn
        2 3/0 3/1 --> used, 2de functie of functie call, enz
        wat statistiek over code
    bla1
    bla2
mov --> call instruction
    25cd4fe3:
        length van volgende lijn
        1 --> from
        wat statistiek over code
    t
    u
label: --> functie, multiple calls inside
    k
    l
    m
    n
    mov
        k
        l
    mov
        o
        p
label2:
    a
    b
    c
    d
    e
    f
    label
        comment
            lorem ipsum
            lorem ipsum
        a
        b
        c
        d
    mov
        r
        s
    tests:
        bla test 1: --> geen idee hoe tests te implementeren
    free:
        bla, na malloc
label2
    x
    y
    z
    q
    v
    w

master table: functie of functie call ref eg. 3/0 (2^8 * 2^8 + 256 keer /) | f of f call name (2^16?) | f of f call pointer (2^64)

JIT compileren kan perfect
Meta programmeren, compile time execution: type T invullen in functies doet al veel, en ook de referenties naar functies in heel het programma om herhaling te voorkomen, ook errors vangen voor gebruik kan, #define en #ifdef --> hier kan dat veel uitgebreider (define en if else) ==> hoe is 't verschil tussen gewoon programmeren en meta programmeren? wel, veelal is dat er niet, juist T

free, na malloc, kan overal liggen, maar automatisch als laatste in zelfde array

hoe tests implementeren?



if
    :(verdwijnt)
        x0
        ==
        x1
    and
    ...

: (anonymous function call)
    comment
        blah deze function call wordt uitgevoerd en is gegroepeerd, is alleen veel langer dan op 1 lijn, ook een revisioning van asm
    x0
    and
    x1

om weg te geraken van lisp style asm





dus je hebt functie creëren en functie oproepen
functie: en call instructie
volgende lijn 
argumenten alleen laten zien zonder uitgebreid te tonen
list met functienamen in memory --> maar stack of heap, misschien stack alleen voor basis en heap voor functies
nested functies is de bedoeling

't wordt een binary, dus knitting moet kunnen gebeuren he, maar daarvoor is een os nodig

sublabeling, ik denk dat alleen de argumenten anders zijn dan asm

moet nog data text en bss uitzoeken
named arguments mogelijk?

een bootstrap van asm zeg, niet simpel
two pass knitter, eerst symbol table maken en dan machine code