    ; TODO put numbers in knit_stream instead of sentences

global _start

section .text
 
_start:
    xor     rax, rax                ;Set it to 0
    xor     rbx, rbx
    xor     rcx, rcx
    xor     rdx, rdx
    xor     r8, r8
    xor     r9, r9
    xor     r10, r10
    xor     r11, r11
    xor     r12, r12
    xor     r13, r13
    xor     r14, r14
    xor     r15, r15
    mov     rsi, knitter
    mov     rdi, intermediary
loop_1st_pass:
    mov     al, byte [rsi + rbx]
    cmp     al, 0                   ;Check the end of string
    jz      knit_binary
    inc     rbx
    cmp     al, 10                  ;Check for new line
    jz      reset_sentence_after_new_line
    cmp     al, 32                  ;Check for space
    jz      count_preceding_spaces_after_space_1st_pass
    cmp     al, 58                  ;Check for colon
    jz      create_functions_table_after_colon
    inc     r15                     ;Beginning of function_name
    cmp     r10, r11                ;Layers: r11 is spaces
    jnz     loop_1st_pass
    mov     byte [rdi + rcx], al
    inc     rcx
    jmp     loop_1st_pass
reset_sentence_after_new_line:      ;A sentence can become a function name or a function call
    xor     r15, r15
    inc     r9                      ;Increment new line counter
    cmp     r10, r11                ;Layer: spaces is r11
    jnz     xor_r11_r8
    cmp     r8, 0                   ;Check for colon
    jz      xor_rcx
loop1:
    cmp     rcx, r13
    jz      next_after_new_line
    mov     al, byte [rdi + r13]
    mov     byte [function_names_array + r14], al
    inc     r13
    inc     r14
    jmp     loop1
next_after_new_line:
    xor     rcx, rcx
    xor     r13, r13
    mov     byte [function_names_array + r14], 58    ; colon
    inc     r14
    mov     r12, rbx
.loop1:
    mov     al, byte [rsi + r12]
    inc     r12
    cmp     al, 32
    jz      .loop1
    dec     r12 ;;;;;;;;;;;;;;;;;;; is niet goed!!!!!!!!!!!!!! doen zoals loop_2nd_pass
    mov     [functions_offset_array + (rdx * 8)], r12
    inc     rdx
    xor     r8, r8
    jmp     loop_1st_pass
xor_r11_r8:
    xor     r11, r11
    xor     r8, r8
    jmp     loop_1st_pass
xor_rcx:
    xor     rcx, rcx
    jmp     loop_1st_pass
count_preceding_spaces_after_space_1st_pass:
    cmp     r10, r11
    jnz     loop_1st_pass
    cmp     r15, 0
    jnz     add_space
    ;Count spaces and put in array
    inc     r11
    jmp     loop_1st_pass
add_space:
    mov     byte [rdi + rcx], 32
    inc     rcx
    jmp     loop_1st_pass
create_functions_table_after_colon:
    inc     r8                  ;Colon presence boolean
    jmp     loop_1st_pass
knit_binary:
    mov     byte [function_names_array + r14], 0    ; EOF
    xor     rax, rax
    xor     rbx, rbx
    xor     rcx, rcx
    xor     rdx, rdx
    xor     r8, r8
    xor     r9, r9
    xor     r10, r10
    xor     r11, r11
    xor     r12, r12
    xor     r13, r13
    xor     r14, r14
    xor     r15, r15
    mov     [offset_knit_bin_stream], r15     ; offset in knit_bin_stream
    mov     [offset_knit_stream], r15
loop_2nd_pass:
    mov     al, byte [rsi + rbx]
    cmp     al, 0                   ;Check the end of string
    jz      end
    inc     rbx
    cmp     al, 58                  ;Check for colon
    jz      set_function
    cmp     al, 32                  ;Check for space
    jz      count_preceding_spaces_after_space_2nd_pass
    cmp     al, 10                  ;Check for new line
    jz      is_new_line
    inc     r14
    mov     byte [rdi + rcx], al
    inc     rcx
    jmp     loop_2nd_pass


count_preceding_spaces_after_space_2nd_pass:
    cmp     r14, 0
    jnz     add_space_2nd
    ;Count spaces and put in array
    inc     r11
    jmp     loop_2nd_pass
add_space_2nd:
    cmp     r10, r11
    jnz     loop_2nd_pass
    mov     byte [rdi + rcx], 32
    inc     rcx
    jmp     loop_2nd_pass


;add_space_in_description:
;    mov     byte [rdi + rcx], 32
;    inc     rcx
;    jmp     loop_2nd_pass


set_function:
    mov     r15, 1
    mov     al, byte [rsi + rbx]
    cmp     al, 10                  ; new line moet na colon
    jnz     end
    inc     rbx
is_new_line:
    mov     byte [rdi + rcx], 58
    xor     rcx, rcx
    ;xor     r11, r11

    xor     r14, r14
    xor     r13, r13 ;;;;


    xor     r8, r8
    call    pre_count_spaces
    ;
    cmp     r15, 3 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; comment
    jz      handle_comment_mode
    cmp     r15, 2
    jz      pre_add_any_parameters
    cmp     r15, 0
    jnz     function_checks
    jmp     main___is_function_call_with_or_without_arguments_or_binary
function_checks:
    xor     r11, r11
    cmp     r10, r13
    jnz     layered_or_not
    xor     r15, r15
    ;add     r10, 4 moet bij de is_last_argument_or_without_arguments
    jmp     loop_2nd_pass
layered_or_not:
    cmp     r10, 0
    jz      loop_2nd_pass
    add     r10, 4 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; comment
    xor     r15, r15
    jmp     loop_2nd_pass
handle_comment_mode:
    ; r13 has the new line's indentation (space count)
    ; comment_layer has the indentation where comment was called
    ; If r13 > comment_layer, we're still in comment content - skip
    ; If r13 <= comment_layer, we've returned to same/shallower level - resume
    cmp     r13, [comment_layer]
    jg      .stay_in_comment
    ; Return to normal processing
    xor     r15, r15
    jmp     main___is_function_call_with_or_without_arguments_or_binary
.stay_in_comment:
    ; Stay in comment mode, skip this line
    jmp     loop_2nd_pass

; spaces altijd per vier
; colon:
;   add r10, 4
;   spaces < r10:   kan terug function zijn en dan fallthrough, dus sub r10, 4 en cmp spaces, r10 en loop_2nd_pass
;                   jne bla naar mov r10, spaces, goto loop_2nd_pass
;   spaces == r10:  is_parameter_or_function_call_with_or_without_arguments_or_function_or_binary
;                   misschien gewoon loop_2nd_pass opnieuw??
;   spaces > r10:   goto end
; no colon:
;   spaces < r10:   is_function_call_with_or_without_arguments_or_function_or_binary
;   spaces == r10:  is_parameter_or_function_call_with_or_without_arguments_or_function_or_binary
;                   misschien gewoon loop_2nd_pass opnieuw??

; de comment nog verwerken: function_names_array[0] then r10 moet gelijk zijn aan spaces

; rbx moet teruggezet worden na de jump, met en zonder argumenten
; na het lezen van de funcion with or without args, set rbx in knit_stream

pre_count_spaces:
    push    rbx
count_spaces:
    mov     al, byte [rsi + rbx]
    cmp     al, 32
    jnz     ret_count_spaces
    inc     rbx
    inc     r8
    inc     r13
    cmp     r8, 4
    jz      xor_r8
    jmp     count_spaces
ret_count_spaces:
    pop     rbx
    cmp     r8, 0
    jnz     end             ; not allowed
    ret
xor_r8:
    xor     r8, r8
    jmp     count_spaces
main___is_function_call_with_or_without_arguments_or_binary:
    mov     r12, knit_stream
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; hier gebeurt een verkeerde keuze
    ;; lookup_function wordt niet bereikt bij xor
    xor     rdx, rdx
    mov     r8, [offset_knit_stream]
    cmp     r13, r10
    jz      is_last_argument_or_without_arguments
    cmp     r11, r10
    jg      is_argument
    xor     r11, r11
    ;
pre_lookup_function:
    xor     rcx, rcx
    mov     r12, function_names_array
lookup_function:
    mov     al, byte [r12 + rcx] ;
    mov     ah, byte [rdi + rdx] ; intermediary
    cmp     al, 0
    jz      is_binary
    cmp     al, ah
    jz      char_equal_maybe_function
    jmp     inc_rcx
is_binary:
    xor     rcx, rcx
    xor     r14, r14
    xor     r15, r15
    
    ;
    ; rbx moet naar de eerste met r13 0 in knitstream
    ; dus knit_stream - 8 == 0 dan -16 == 0 anders +8 en rbx lezen
    ;
    call    set_rbx

    mov     r9, [offset_knit_bin_stream]    ; offset in knit_bin_stream
    mov     r12, knit_bin_stream
.loop:
    mov     al, [rdi + rcx]
    cmp     al, 58 ; colon
    jz      set_offset
    mov     [r12 + r9], al
    inc     rcx
    inc     r9              ; offset in knit_bin_stream
    jmp     .loop
set_offset:
    mov     [offset_knit_bin_stream], r9
    xor     rcx, rcx
    xor     r9, r9
    jmp     loop_2nd_pass   ; op naar de volgende binary

set_rbx:
    mov     r9, [offset_knit_stream]
    mov     r12, knit_stream
    sub     r9, 8
.loop:
    cmp     r9, 0
    jl      set_offset_knit_stream
    mov     r15, [r12 + r9] ;;; r9 mag niet kleiner dan nul
    sub     r9, 16
    cmp     r15, 0
    jz      .loop  ;// iets mis in samenspraak met is_argument
set_offset_knit_stream:
    add     r9, 8 ;;;;;;;;;;;; of 24????
    mov     rbx, [r12 + r9]

    mov     [offset_knit_stream], r9        ; reset
    xor     r15, r15
    ret


char_equal_maybe_function:
    inc     rcx
    inc     rdx
    cmp     byte [rdi + rdx], 58
    jz      lookup_offset
    jmp     lookup_function
inc_rcx:
    xor     rdx, rdx
    inc     rcx
    cmp     byte [r12 + rcx], 58
    jnz     inc_rcx
    inc     rcx
    inc     r14
    jmp     lookup_function
lookup_offset:
    xor     rcx, rcx ;; comment TODO: mov r15, 3 en rbx onveranderd if als offset comment is
    cmp     r13, r10
    jnz     push_rbx
    cmp     qword [functions_offset_array + (r14 * 8)], 9
    jz      set_r15
    mov     rbx, [functions_offset_array + (r14 * 8)]
    xor     r14, r14
    jmp     loop_2nd_pass
push_rbx:
    push    qword [functions_offset_array + (r14 * 8)]
    xor     r14, r14
    jmp     loop_2nd_pass
set_r15:
    mov     [comment_layer], r10  ; save current layer for comment mode
    mov     r15, 3 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; comment
    jmp     loop_2nd_pass

is_last_argument_or_without_arguments:
    ;
    ; hier zit rbx niet goed
    ;
    cmp     r9, 0
    jz      add_to_knit_stream_to_pre_lookup_function         ; function call without arguments or binary
    inc     r9
    push    r9
    mov     r9, -1
is_argument:
    xor     r11, r11
    mov     al, [rdi + rdx]
    mov     [r12 + r8], al
    inc     r8
    inc     rdx
    cmp     al, 58
    jnz     is_argument
    mov     [offset_knit_stream], r8
    cmp     r9, -1 ;_______________hier moet add_any_parameters ingegaan worden of zo
    jz      goto_parameters ; of rbx setten en dit terug laten lopen geen idee
    inc     r9
    jmp     loop_2nd_pass

goto_parameters:
    add     r10, 4
    pop     r9      ; aantal argumenten
    pop     r8      ; einde function after lookup_offset
    push    rbx     ; einde argumenten
    mov     rbx, r8
    push    r9      ; aantal argumenten
    push    r9
    mov     r15, 2  ; is parameter
    xor     r8, r8
    xor     r9, r9
    jmp     loop_2nd_pass
pre_add_any_parameters;
    pop     r13
    xor     rdx, rdx
    mov     r8, [offset_knit_stream]
add_any_parameters:
    mov     al, [rdi + rdx]
    mov     [r12 + r8], al
    inc     r8
    inc     rdx
    cmp     al, 58
    jnz     add_any_parameters
    mov     [offset_knit_stream], r8
    dec     r13
    push    r13
    cmp     r13, 0
    jnz     loop_2nd_pass
add_to_knit_stream:   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov     r8, [offset_knit_stream]
    pop     r9 ; is nul
    pop     r9 ; aantal argumenten
    mov     qword [r12 + r8], rbx
    add     r8, 8
    mov     qword [r12 + r8], r9
    add     r8, 8
    mov     [offset_knit_stream], r8
    xor     r8, r8
    xor     r9, r9
    xor     r15, r15
    jmp     loop_2nd_pass
add_to_knit_stream_to_pre_lookup_function:
    xor     r15, r15
    mov     r8, [offset_knit_stream]
    mov     qword [r12 + r8], rbx ;;;;;;;;;;;;;;;;;__________ne concatenate moet hier, r8 dus
    add     r8, 8                   ;;;;;;;;;;;;;;;__________en dan in is_binary de eerste van knit_stream kiezen
    mov     qword [r12 + r8], r13 ;:::::::::::::::::__________klopt nog niet
    add     r8, 8 ; moet dat?
    mov     [offset_knit_stream], r8
    xor     r8, r8
    jmp     pre_lookup_function

; 't moet naar de voorlaatste nul of de laatste als er geen voorlaatste is
; dat is nul argumenten in knit_stream

end: 
    hlt 
    jmp end     ; Infinite loop.



len_array equ 4096                          ;4096 rows and 2 colums of each 64 bit

knit_stream: resb len_array
knit_bin_stream: resb len_array
intermediary: resb len_array

function_names_array: resb len_array*8
functions_offset_array: resq len_array

spaces_array: resq len_array

function_calls_and_arguments_array: resb len_array

output: resb len_array

binary_name: db "knitter_______", 0

offset_knit_bin_stream: resq 1
offset_knit_stream: resq 1
offset_knitter: resq 1
function_call: resq 1
comment_layer: resq 1

knitter2:  db  "xor:", 10, \
              "xor", 10, \
              "    rax", 10, \
              "    address", 10, \
              "    rax", 10, \
              "    address", 10, \
              "end:", 10, \
              0   ;End of string

knitter:  db  "comment:", 10, \
              "nop:", 10, \
              "    0110011010010000", 10, \
              "address:", 10, \
              "    11", 10, \
              "al:", 10, \
              "rax:", 10, \
              "    000", 10, \
              "xor:", 10, \
              "    reg1", 10, \
              "    goal1", 10, \
              "    reg2", 10, \
              "    goal2", 10, \
              "    prefix:", 10, \
              "        01001000", 10, \
              "    opcode:", 10, \
              "        00011111", 10, \
              "    modrm:", 10, \
              "        comment", 10, \
              "            reg1 en reg2 moeten misschien omgewisseld worden", 10, \
              "        address", 10, \
              "        reg1", 10, \
              "        reg2", 10, \
              "10011", 10, \
              "rax", 10, \
              "xor", 10, \
              "    rax", 10, \
              "    address", 10, \
              "    rax", 10, \
              "    address", 10, \
              "end:", 10, \
              0   ;End of string

knitter_10:  db  "comment:", 10, \
              "nop:", 10, \
              "    0110011010010000", 10, \
              "contents:", 10, \
              "    00", 10, \
              "address:", 10, \
              "    11", 10, \
              "al:", 10, \
              "rax:", 10, \
              "    000", 10, \
              "cl:", 10, \
              "rcx:", 10, \
              "    001", 10, \
              "dl:", 10, \
              "rdx:", 10, \
              "    010", 10, \
              "bl:", 10, \
              "rbx:", 10, \
              "    011", 10, \
              "rsp:", 10, \
              "    100", 10, \
              "rbp:", 10, \
              "    101", 10, \
              "rsi:", 10, \
              "    110", 10, \
              "rdi:", 10, \
              "    111", 10, \
              "r8:", 10, \
              "    0001", 10, \
              "r9:", 10, \
              "    0011", 10, \
              "r10:", 10, \
              "    0101", 10, \
              "r11:", 10, \
              "    0111", 10, \
              "r12:", 10, \
              "    1001", 10, \
              "r13:", 10, \
              "    1011", 10, \
              "r14:", 10, \
              "    1101", 10, \
              "r15:", 10, \
              "    1111", 10, \
              "cmp:", 10, \
              "    reg1", 10, \
              "    reg2", 10, \
              "    prefix:", 10, \
              "        01001000", 10, \
              "    opcode:", 10, \
              "        00100111", 10, \
              "    modrm:", 10, \
              "        address", 10, \
              "        reg1", 10, \
              "        reg2", 10, \
              "jnz:", 10, \
              "    label", 10, \
              "    comment", 10, \
              "        offset berekenen in volgende iteratie --> TODO change the offset", 10, \
              "    opcode:", 10, \
              "        0000111110000101", 10, \
              "    offset:", 10, \
              "        0000", 10, \
              "xor:", 10, \
              "    reg1", 10, \
              "    goal1", 10, \
              "    reg2", 10, \
              "    goal2", 10, \
              "    cmp", 10, \
              "        goal1", 10, \
              "        address", 10, \
              "    jnz", 10, \
              "        end", 10, \
              "    cmp", 10, \
              "        goal2", 10, \
              "        address", 10, \
              "    jnz", 10, \
              "        end", 10, \
              "    prefix:", 10, \
              "        01001000", 10, \
              "    opcode:", 10, \
              "        00011111", 10, \
              "    modrm:", 10, \
              "        comment", 10, \
              "            reg1 en reg2 moeten misschien omgewisseld worden", 10, \
              "        address", 10, \
              "        reg1", 10, \
              "        reg2", 10, \
              "00011", 10, \
              "rax", 10, \
              "xor", 10, \
              "    rax", 10, \
              "    address", 10, \
              "    rax", 10, \
              "    address", 10, \
              "end:", 10, \
              0   ;End of string
len_knitter equ $ - knitter

; rdi = intermediary
; rsi = knitter code
; r14 = xor::bla::cmp::ook::bla --> goal1 vervangen door address --> of is dat nu in reg --> of op de stack?
; r15 = 4 3 3 ff ff --> amount_of_arguments --> of op de stack???
; eerst argumenten/parameters aflopen, dan functions, dan heb je binary, add to intermediary

; is ook address dus vergelijk lijnnumer van address, cmp toevoegen
; count arguments, pass parameter, read cmp, read argument, cmp met parameter, fill in xor argument
; take layers into account
; je zou binaries kunnen controleren, maar 1 binary moet leiden naar 1 lijn
; misschien push to stack if layers build up
; controleer layer bij elke parameter in vergelijking met de argumenten

;https://stackoverflow.com/questions/32705369/nasm-how-to-print-a-number-using-int-080h
;https://stackoverflow.com/questions/8287181/how-to-do-source-level-debugging-of-x86-code-with-gdb-inside-qemu
;https://stackoverflow.com/questions/46511449/printing-numbers-in-nasm
;https://stackoverflow.com/questions/35927302/how-to-compare-a-char-in-a-string-with-another-char-in-nasm-x86-64-linux-assembl
;https://blog.stalkr.net/2014/10/tiny-elf-3264-with-nasm.html

;back:
;inc rbx
;if colon
;    if r9 == r11 inc rdx back
;if space inc r11 back
;if \n
;    if r9 < r11
;        if rdx xor r11 back
;        else add array xor r11 back
;    else
;        inc r10
;        if rdx < r10 xor rdx xor r11 xor r10 add array back
;store char
;back

;b:
;  c
;  c
;b:
;b:
;  c
;b:
;  c
;  d:
;    e
;  d
;    e
;b:
;  c
;b
;  c
;  c
