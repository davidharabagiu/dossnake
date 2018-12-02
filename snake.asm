title	SNAKE
.486

stck	segment para stack 'stack' use16
		dw	64 dup(?)
stck	ends

data	segment para public 'data' use16

prevt	dw	?				;used to store the time of the last frame
colors	db	7h, 1h, 2h, 3h, 4h, 5h, 6h, 9h, 0eh, 0fh	;color codes that can be used to draw with
colorsl	equ	$ - colors		;length of the colors array
ccolori	db	0				;index of the color code that is currently in use
ccolor	db	7h				;color code that is currently in use

rndx	dw 	1
rndy 	dw 	1

snksegx	dw 	100 dup(0)
snksegy	dw 	100 dup(0)
snksegc dw 	?
snkdirx	dw 	?
snkdiry	dw 	?
foodx	dw 	?
foody 	dw 	?

data	ends

code	segment para public 'code' use16
	assume cs:code, ds:data, es:data, fs:data, ss:stck

start:
	mov		ax, data
	mov		ds, ax			;initialize data segment
	mov		ax, 13h
	int		10h				;set video mode to 13h
	mov		ax, 0a000h		;initialize extra segment
	mov		es, ax			;the pixels that are stored here are drawn on screen automatically in video mode 13h
	mov		ax, 0b000h		;initialize a second extra segment, used to store the frame while it is prepared
	mov		fs, ax			;the frame is first built here, then copied in es (double buffering)
							;this is done to avoid flickering

	call 	resetgame

gameloop:
	call	getkb			;read from the keyboard

	mov		ah, 0
	int		1ah				;get system time
	mov 	ax, prevt
	add 	ax, 2
	cmp		dx, ax			;check if enough time has passed since the last update
	jb		gameloop		;if there is no change, wait more
	mov		prevt, dx		;update prevt

	call	clrscr			;clear screen
	
update:
	;add game logic here

; check snake collision
	mov 	ax, snksegx
	mov 	dx, snksegy
	lea 	si, snksegx
	lea 	di, snksegy
	add 	si, 2
	add 	di, 2
	mov 	cx, snksegc
.check_snake_collision_loop:
	cmp 	ax, [si]
	jne 	.check_snake_collision_failed
	cmp 	dx, [di]
	jne 	.check_snake_collision_failed
	call 	resetgame
	jmp 	.check_snake_collision_done
.check_snake_collision_failed:
	add 	si, 2
	add 	di, 2
	dec 	cx
	cmp 	cx, 0
	jne 	.check_snake_collision_loop
.check_snake_collision_done:

; check food collision
	mov 	ax, snksegx
	mov 	dx, foodx
	cmp 	ax, dx
	jne		.food_collision_test_done
	mov 	ax, snksegy
	mov 	dx, foody
	cmp 	ax, dx
	jne 	.food_collision_test_done
; collides with food, add segment, reset food
	lea		bx, snksegx
	mov 	si, snksegc
	shl		si, 1
	mov 	ax, [bx + si - 2]
	mov 	[bx + si], ax
	lea 	bx, snksegy
	mov 	ax, [bx + si - 2]
	mov 	[bx + si], ax
	shr 	si, 1
	inc 	si
	mov 	snksegc, si
	mov 	bx, 40
	call 	rand
	mov 	foodx, dx
	mov 	bx, 25
	call 	rand
	mov 	foody, dx
.food_collision_test_done:

; move snake
	lea 	si, snksegx
	lea 	di, snksegy
	mov 	bx, snksegc
	dec 	bx
	shl		bx, 1
move_snake_loop:
	mov 	ax, [si + bx - 2]
	mov 	[si + bx], ax
	mov 	ax, [di + bx - 2]
	mov 	[di + bx], ax
	dec 	bx
	cmp 	bx, 0
	jne 	move_snake_loop

; move head
	mov 	ax, snksegx
	add 	ax, snkdirx
	jns 	.test_head_outside1
	mov 	ax, 39
.test_head_outside1:
	cmp 	ax, 39
	jng 	.test_head_outside2
	mov 	ax, 0
.test_head_outside2:
	mov 	snksegx, ax
	mov 	ax, snksegy
	add 	ax, snkdiry
	jns 	.test_head_outside3
	mov 	ax, 24
.test_head_outside3:
	cmp 	ax, 24
	jng 	.test_head_outside4
	mov 	ax, 0
.test_head_outside4:
	mov 	snksegy, ax

	
draw:													;game state is 1 (in game)
	;draw game objects here
	
	lea 	si, snksegx
	lea 	di, snksegy
	mov 	cx, snksegc
	mov 	dl, ccolor
draw_snake_segments:
	mov 	ax, [di]
	mov 	bx, [si]
	call 	drawpt
	add 	di, 2
	add 	si, 2
	loop 	draw_snake_segments

	mov 	ax, foody
	mov 	bx, foodx
	call 	drawpt
	
	jmp		applydraw
	
applydraw:
	call	drawframe		;draw the frame on screen
	jmp		gameloop

resetgame	proc near
	mov 	snksegc, 4
	lea 	si, snksegx
	lea 	di, snksegy
	mov 	word ptr [si], 20
	mov 	word ptr [si + 2], 19
	mov 	word ptr [si + 4], 18
	mov 	word ptr [si + 6], 17
	mov 	word ptr [di], 12
	mov 	word ptr [di + 2], 12
	mov 	word ptr [di + 4], 12
	mov 	word ptr [di + 6], 12
	mov 	bx, 4
	call 	rand
.dirtest1:
	cmp 	dx, 0
	jne 	.dirtest2
	mov 	snkdirx, 1
	mov 	snkdiry, 0
.dirtest2:
	cmp 	dx, 1
	jne 	.dirtest3
	mov 	snkdirx, -1
	mov 	snkdiry, 0
.dirtest3:
	cmp 	dx, 2
	jne 	.dirtest4
	mov 	snkdirx, 0
	mov 	snkdiry, 1
.dirtest4:
	cmp 	dx, 3
	jne 	.dirtest_end
	mov 	snkdirx, 0
	mov 	snkdiry, -1
.dirtest_end:
	mov 	bx, 40
	call 	rand
	mov 	foodx, dx
	mov 	bx, 25
	call 	rand
	mov 	foody, dx
	ret
resetgame 	endp

drawpt 		proc near
	push 	cx
	shl 	ax, 3
	shl 	bx, 3
	mov 	cx, 8
drawpt_loop_y:
	push 	cx
	push 	bx
	mov 	cx, 8
drawpt_loop_x:
	call 	putpixel
	inc 	bx
	loop 	drawpt_loop_x
	pop 	bx
	pop 	cx
	inc 	ax
	loop 	drawpt_loop_y
	pop 	cx
	ret
drawpt 		endp

putpixel	proc near
	;proceure to set a pixel
	;ax = Y coord
	;bx = X coord
	;dl = color
	pusha
	push	dx				;save dx before it is altered by the multiplication
	mov		cx, 320			;get the address of pixel
	mul		cx
	add		ax, bx
	mov		di, ax
	pop		dx				;restore dx
	mov		fs:[di], dl		;set the pixel in the frame to be drawn
putpixelret:
	popa
	ret
putpixel	endp

drawframe	proc near
	;procedure to move the frame from fs to es so that is displayed on screen
	mov		cx, 0fa00h
	mov		di, 0
drawframeloop:
	mov		ax, fs:[di]
	mov		es:[di], ax
	inc		di
	loop	drawframeloop
	ret
drawframe	endp

clrscr		proc near
	;set all pixels to black
	mov		cx, 0fa00h
	mov		di, 0
	mov		dl, 0
clrscrloop:
	mov		fs:[di], dl
	inc		di
	loop	clrscrloop
	ret
clrscr		endp

getkb		proc near
    in      al, 60h 			;read keyboard scan code

; check input
	cmp		al, 11h						;check if W is pressed
	jne		.input_check1
	; up, check if going down
	cmp 	snkdiry, 1
	je 		.input_check_done
	mov 	snkdirx, 0
	mov 	snkdiry, -1
.input_check1:
	cmp		al, 1eh						;check if A is pressed
	jne		.input_check2
	; left, check if going right
	cmp 	snkdirx, 1
	je 		.input_check_done
	mov 	snkdirx, -1
	mov 	snkdiry, 0
.input_check2:
	cmp 	al, 1fh						;check if S is pressed
	jne		.input_check3
	; down, check if going up
	cmp 	snkdiry, -1
	je 		.input_check_done
	mov 	snkdirx, 0
	mov 	snkdiry, 1
.input_check3:
	cmp 	al, 20h						;check if D is pressed
	jne		.input_check_done
	; right, check if going left
	cmp 	snkdirx, -1
	je 		.input_check_done
	mov 	snkdirx, 1
	mov 	snkdiry, 0
.input_check_done:

.colortest:
	cmp		al, 2eh						;check if C is pressed
	jnz		.end_color_test
	inc		ccolori						;change the color
	cmp		ccolori, colorsl
	jb		.applynewcolor
	mov		ccolori, 0
.applynewcolor:
	push 	ax
	mov		al, ccolori
	lea		bx, colors
	xlat
	mov		ccolor, al
	pop 	ax
.end_color_test:

	cmp		al, 1						;check if ESC is pressed
	je		exitgame					;exit game

	ret
getkb		endp

exitgame 	proc near
	mov		ax, 3
	int		10h							;set video mode back to normal
	mov		ah, 4ch
	int		21h							;return to os
	ret
exitgame	endp

rand		proc near
	push 	ax
	push 	cx
	push 	bx
	mov		ah, 0
	int		1ah			;get system time
	pop 	bx
	mov		ax, dx
	xor		dx, dx
	div		bx

	;generate random number in randge 0 - (bx-1)
	;restult in dx
	pop 	cx
	pop 	ax
	ret
rand		endp

	
code	ends
end		start