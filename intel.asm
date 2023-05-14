
.MODEL small

.STACK 1024							; pilha padrão é 1k byte

.DATA

	QuebraLinha 	EQU 0AH
	CarriageReturn	EQU 0DH
	FimString		EQU 00H
	Espaco			EQU 20H
	
	FileName		DB 256 DUP (FimString)		; Nome do arquivo a ser lido
	FileBuffer		DB 10 DUP (?)				; Buffer de leitura do arquivo
	FileHandle		DW 0						; Handler do arquivo
	
	StringPrompt	DB 100 DUP(FimString)
	TokenPrompt		DB 100 DUP(FimString)
	tokenChar		DB ?
	nextTokenChar	DB ?
	
	FlagG			  DB 0
	FlagV			  DB 0
	vVerificationCode DB 16 DUP (FimString)
	StringX			  DB 17 DUP (FimString)
	X1				  DW 0
	X2				  DW 0
	X3				  DW 0
	X4				  DW 0
	sw_n	dw	0
	sw_f	db	0
	sw_m	dw	0
	
	MsgParamentrosIguais DB "codigos iguais", CarriageReturn, QuebraLinha, FimString
	MsgParamentrosdiferentes DB "codigos diferentes", CarriageReturn, QuebraLinha, FimString
	MsgSemComandoGV DB "Comando -g nem -v identificados", CarriageReturn, QuebraLinha, FimString
	MsgErroOpenFile DB "Erro na abertura do arquivo.", CarriageReturn, QuebraLinha, FimString
	MsgErroReadFile	DB "Erro na leitura do arquivo.", CarriageReturn, QuebraLinha, FimString
	MsgErroCloseFile DB "Erro no fechamento do arquivo.", CarriageReturn, QuebraLinha, FimString
	
	

.CODE	
			
.STARTUP 	
	
	CALL Funcao_CR_LF
	
	MOV FlagG, 0			; inicializando flags
	MOV FlagV, 0
	
	CALL GetPrompt
	
	LEA SI, StringPrompt	; transforma o prompt em token
	LEA DI, TokenPrompt
	CALL stringToToken		
	
	LEA SI, TokenPrompt		; pega o nome do arquivo
	CALL getAFileName

	CALL GetArqVerificationCode ; criando código do arquivo
	CALL setStringFromArqCode
	
	LEA SI, TokenPrompt	  ; PROCURA G
	CALL getGCode
	
	LEA SI, TokenPrompt	  ; PROCURA V
	CALL getVCode
	
	CALL ReturnSomething
	
	CALL Funcao_CR_LF
.EXIT 0	

	;--------------------------FUNÇÃO getGCode--------------------------
	; passa um ponteiro para uma string por SI
	getGCode PROC NEAR
	
		CMP FlagV, 1
		JE getGCode_end
	
		MOV DL, [SI]
		MOV tokenChar, DL
		
		CMP tokenChar, FimString
		JE getGCode_end
		
		INC SI
		
		MOV DL, [SI]
		MOV nextTokenChar, DL
		
		CMP nextTokenChar, 'g'
		JE compareTokenCharG
		JMP getGCode
		
		compareTokenCharG:
			CMP tokenChar, '-'
			JE getGCode_continue
			JMP getGCode
	
		getGCode_continue:
		
			MOV FlagG, 1	; liga flag e encerra
	
		getGCode_end:
			RET
	getGCode ENDP
	;--------------------------FUNÇÃO getGCode--------------------------
	
	;--------------------------FUNÇÃO setStringFromArqCode--------------------------
	setStringFromArqCode PROC NEAR
	
		MOV AX, X1				
		LEA BX, StringX
		CALL sprintf_h
		
		MOV AX, X2
		LEA BX, [StringX+4]
		CALL sprintf_h
		
		MOV AX, X3
		LEA BX, [StringX+8]
		CALL sprintf_h
		
		MOV AX, X4
		LEA BX, [StringX+12]
		CALL sprintf_h
		MOV BYTE PTR[BX], 0
	
		RET
	setStringFromArqCode ENDP
	
	
	;--------------------------FUNÇÃO setStringFromArqCode--------------------------

	;--------------------------FUNÇÃO ReturnSomething--------------------------
	ReturnSomething PROC NEAR
	
		CMP FlagV, 1
		JE ReturnSomething_V
		
		CMP FlagG, 1
		JE ReturnSomething_G
		
		LEA BX, MsgSemComandoGV
		CALL printf_s
		JMP ReturnSomething_end
	
		ReturnSomething_V:			; compara se os códigos são iguais
		
			UpperV:
			
				LEA BX, vVerificationCode
				
				UpperV_Loop:
				
					CMP [BX], FimString
					JE Compara_X_V
					
					MOV AL, [BX]
					
					CMP	AL,'a'
					JB	UpperV_Ignora
					CMP	AL,'z'
					JA	UpperV_Ignora
					SUB	AL,20h
					MOV [BX], AL
				
				UpperV_Ignora:
					INC BX
					JMP UpperV_Loop
					
			Compara_X_V:			
				
				;LEA BX, vVerificationCode
				;CALL printf_s
				;CALL Funcao_CR_LF
				
				LEA BX, StringX
				
				Compara_X_V_loop:
				
					CMP BYTE PTR [BX], '0' 					; vai passando por X até achar um valor que não seja zero
					JNE ReturnSomething_V_begin 		
					
					INC BX
					JMP Compara_X_V_loop
				
				ReturnSomething_V_begin:
				
					; string X está em BX, string V está em DI
					LEA DI, vVerificationCode
					
						ReturnSomething_V_begin_loop:
						
							CMP BYTE PTR [DI], '0' 					; vai passando por V até achar um valor que não seja zero
							JNE ReturnSomething_V_loop 		
							
							INC DI
							JMP ReturnSomething_V_begin_loop
																	
					
					ReturnSomething_V_loop:
					
						MOV DL, BYTE PTR [DI]				; seta variavel de V
						MOV AL, BYTE PTR [BX]				; seta varial de X
						
						CMP DL, FimString
						JE codigosIguais
						
						CMP AL, DL
						JNE codigosDiferentes
						
						INC DI
						INC BX
						JMP ReturnSomething_V_loop
					
					codigosIguais:
						LEA BX, MsgParamentrosIguais
						CALL printf_s
						JMP ReturnSomething_end
				
					codigosDiferentes:
						LEA BX, MsgParamentrosdiferentes
						CALL printf_s	
					JMP ReturnSomething_end
		
		ReturnSomething_G:			; exibe na tela o código
	
			LEA BX, StringX
			CALL printf_s	
		
		ReturnSomething_end:
			RET
	ReturnSomething ENDP
	;--------------------------FUNÇÃO ReturnSomething--------------------------


	;--------------------------FUNÇÃO getVCode--------------------------
	; passa um ponteiro para uma string por SI
	; salva dois HEXA em um BYTE só
	; A9 => A = 0041 , 9 = 0039
	; BYTE = 4139

	getVCode PROC NEAR
	
		CMP FlagG, 1
		JE getVCode_end
	
		MOV DL, [SI]
		MOV tokenChar, DL
		
		CMP tokenChar, FimString		; se for o \0, encerra
		JE getVCode_end	
		
		INC SI
		
		MOV DL, [SI]				
		MOV nextTokenChar, DL
		
		CMP nextTokenChar, 'v'			; se o proximo for "v" e o anterior "-" significa que temos o comando
		JE compareTokenCharV
		JMP getVCode
		
		compareTokenCharV:
			CMP tokenChar, '-'
			JE getVCode_continue
			JMP getVCode
			
		getVCode_continue:
		
			MOV FlagV, 1
			LEA DI, vVerificationCode
							
			getVCode_loop:
									; como SI já está em V, basta dar um INC
									; precisa caminhar até encontrar um "-" do prox comando ou um "\0"
				INC SI
				MOV DL, [SI]
				MOV tokenChar, DL	; atualiza valor de tokenChar
				
				CMP tokenChar, '-'
				JE getVCode_loop_quaseEnd
				CMP tokenChar, FimString
				JE getVCode_loop_quaseEnd
	
				MOV [DI], DL
				INC DI
				JMP getVCode_loop
			
			getVCode_loop_quaseEnd:
				MOV [DI], FimString		; adiciona "\0" no final do arquivo
			
		getVCode_end:
			RET
	getVCode ENDP
	;--------------------------FUNÇÃO getVCode--------------------------

	;--------------------------FUNÇÃO getAFileName--------------------------
	; passa um ponteiro para uma string por SI
	getAFileName PROC NEAR
	
		MOV DL, [SI]
		MOV tokenChar, DL
		
		INC SI
		
		MOV DL, [SI]
		MOV nextTokenChar, DL
		
		CMP nextTokenChar, 'a'
		JE compareTokenChar
		JMP getAFileName
		
		compareTokenChar:
			CMP tokenChar, '-'
			JE getAFileName_continue
			JMP getAFileName
			
		getAFileName_continue:
		
			LEA DI, FileName
							
			getAFileName_loop:
									; como SI já está em V, basta dar um INC
									; precisa caminhar até encontrar um "-" do prox comando ou um "\0"
				INC SI
				MOV DL, [SI]
				MOV tokenChar, DL	; atualiza valor de tokenChar
				
				CMP tokenChar, '-'
				JE getAFileName_end
				CMP tokenChar, FimString
				JE getAFileName_end
	
				MOV [DI], DL
				INC DI
				JMP getAFileName_loop
			
		getAFileName_end:
			MOV [DI], FimString		; adiciona "\0" no final do arquivo
			RET
	getAFileName ENDP
	
	;--------------------------FUNÇÃO getAFileName--------------------------

	;--------------------------FUNÇÃO GETPROMPT--------------------------

	GetPrompt PROC NEAR
	
		PUSH DS 				; salva as informações de segmentos
		PUSH ES
		MOV AX, DS 				; troca DS <-> ES, para poder usa o MOVSB
		MOV BX, ES
		MOV DS, BX
		MOV ES, AX
		MOV SI, 80H 			; obtém o tamanho do string e coloca em CX
		MOV CH, 0
		MOV CL, [SI]
		MOV SI, 81H 			; inicializa o ponteiro de origem
		INC SI
		LEA DI, StringPrompt 	; inicializa o ponteiro de destino
		REP MOVSB
		POP ES 					; retorna as informações dos registradores de segmentos 
		POP DS

		RET
	
	GetPrompt ENDP

	;--------------------------FUNÇÃO GETPROMPT--------------------------
	
	;--------------------------FUNÇÃO stringToToken--------------------------
	; passa um ponteiro para uma string por SI
	; passa um ponteiro para um token por DI
	
	stringToToken PROC NEAR
	
		stringToToken_begin:
	
			MOV	DL, [SI]			; compara se chegou ao final
			CMP	DL, FimString
			JE	stringToToken_end
			CMP	DL, CarriageReturn
			JE	stringToToken_end
						
			INC SI
			CMP DL, Espaco
			JE stringToToken_begin		; se for espaço volta para o loop
			
			MOV [DI], DL				; coloca caracter no token
			INC DI
			
			JMP stringToToken_begin
		
		stringToToken_end:
			MOV [DI], FimString			; adiciona \0 no final
			RET
	stringToToken ENDP
	
	;--------------------------FUNÇÃO stringToToken--------------------------
	
	;--------------------------FUNÇÃO PRINTF--------------------------
	;Passar um ponteiro para BX como parâmetro
	Printf_s PROC NEAR
	
		MOV	DL, [BX]	; compara se chegou ao final
		CMP	DL, 0
		JE	Printf_s_fim
		
		PUSH BX
		MOV	 AH, 2
		INT	 21H
		POP	 BX
		
		INC	BX
		JMP	Printf_s
			
	Printf_s_fim:
		ret
		
	Printf_s ENDP
	;--------------------------FUNÇÃO PRINTF--------------------------
	
	;--------------------------FUNÇÃO QUEBRA LINHA E POSICIONA CURSOR--------------------------
	Funcao_CR_LF PROC NEAR
		MOV		ah, 2			; Envia CRLF
		MOV		dl, 13
		INT		21H
		MOV		AH, 2
		MOV		DL, 10
		INT		21H
		RET
	Funcao_CR_LF ENDP
	;--------------------------FUNÇÃO QUEBRA LINHA E POSICIONA CURSOR--------------------------
	
	;--------------------------FUNÇÃO OPENFILE--------------------------
	OpenFile PROC NEAR
	
		MOV		AL, 0				; modo read only
		LEA		DX, FileName
		MOV		AH, 3DH
		INT		21H
		JNC		OpenFileSucceed
		
		LEA		BX, MsgErroOpenFile
		CALL	printf_s
	
		.EXIT	1
	
		OpenFileSucceed:
			RET
			
	OpenFile ENDP
	
	;--------------------------FUNÇÃO OPENFILE--------------------------
	
	;--------------------------FUNÇÃO CLOSEFILE--------------------------
	
	CloseFile PROC NEAR
		MOV	BX, FileHandle		; Fecha o arquivo
		MOV	AH, 3EH
		INT	21H
		JNC CloseFileSucceed
		
		LEA BX, MsgErroCloseFile
		CALL Printf_s
		
		.EXIT 1
		
		CloseFileSucceed:
			RET 
	CloseFile ENDP
	
	;--------------------------FUNÇÃO CLOSEFILE--------------------------
	
	;--------------------------FUNÇÃO ReadFile--------------------------
	ReadFile PROC NEAR
	
		MOV FileHandle, AX
		
		ReadFileBegin:
		
			MOV BX, FileHandle
			MOV AH, 3FH
			MOV CX, 1
			LEA DX, FileBuffer
			INT 21H
			JNC ReadFileSucceed			; verifica se o caracter é lido com sucesso
			
			LEA BX, MsgErroReadFile
			CALL Printf_s
			
			MOV AL, 1					
			JMP CloseFile
			
			ReadFileSucceed:
			
				CMP AX, FimString				; verifica se é último caracter do arquivo
				JNE ReadFileContinue
				
				RET
				
				ReadFileContinue:
					
					MOV DH, 0
					MOV DL, FileBuffer
					LEA DI, X4
					
					ADD X4, DX
					JNC ReadFileBegin
					CLC
					ADD X3, 1
					JNC ReadFileBegin
					CLC
					ADD X2, 1
					JNC ReadFileBegin
					CLC
					ADD X1, 1
					JNC ReadFileBegin
					
    ReadFile ENDP						
	
	;--------------------------FUNÇÃO ReadFile--------------------------
	
	;--------------------------FUNÇÃO GetArqVerificationCode--------------------------
	
	GetArqVerificationCode PROC NEAR
	
		CALL OpenFile
		CALL ReadFile
		CALL CloseFile
		
		RET
	GetArqVerificationCode ENDP
	;--------------------------FUNÇÃO GetArqVerificationCode--------------------------
	
	sprintf_h	proc	near

		;void sprintf_w(char *string, WORD n) {
			mov		sw_n,ax
		
		;	k=5;
			mov		cx,4
			
		;	m=10000;
			mov		sw_m,1000h
			
		;	f=0;
			mov		sw_f,0
			
		;	do {
		sw_do:
		
		;		quociente = n / m : resto = n % m;	// Usar instrução DIV
			mov		dx,0				;zera dx pois a divisão usa dx como bytes mais significativos
			mov		ax,sw_n
			div		sw_m
			
		;		if (quociente || f) {
		;			*string++ = quociente+'0'
		;			f = 1;
		;		}
			cmp		al,9
			jg		sw_store2
			cmp		al,0
			jne		sw_store
			cmp		al,0
			je		sw_store3
			;cmp		sw_f,0
			;je		sw_continue
		sw_store:
			add		al,'0'
			mov		[bx],al
			inc		bx
			
			mov		sw_f,1
			jmp		sw_continue
			
		sw_store3:
			add		al,'0'
			mov		[bx],al
			inc		bx
			
			mov		sw_f,1
			jmp		sw_continue	
			
		sw_store2:
			add		al,'7'
			mov		[bx],al
			inc		bx
			
			mov		sw_f,1
			
		sw_continue:
			
		;		n = resto;
			mov		sw_n,dx				;divisão coloca o resto em dx
			
		;		m = m/10h;
			mov		dx,0
			mov		ax,sw_m
			mov		bp,10h
			div		bp					;divisão sempre usa o ax como parte de cima da divisão
			mov		sw_m,ax
			
		;		--k;
			dec		cx
			
		;	} while(k);
			cmp		cx,0
			jnz		sw_do
		
		;	if (!f)
		;		*string++ = '0';
			cmp		sw_f,0
			jnz		sw_continua2
			mov		[bx],'0'
			inc		bx
		sw_continua2:
		
		
		;	*string = '\0';
			
				
		;}
			ret
				
		sprintf_h	endp
	
END