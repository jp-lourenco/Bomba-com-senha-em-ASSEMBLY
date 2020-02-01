;
; Projeto de bomba caseira com senha
;
; MCU: PIC16F87A     Clock: 4MHz
;
; Autor: João Pedro Lourenço  Data: 15/11/2018

list p=16f877
include <P16F877.inc>

;========================================================================================
; --- FUSE Bits ---
; - Cristal de 4MHz
; - Desabilitamos o Watch Dog Timer
; - Habilita o Power Up Timer
; - Brown Out desabilitado
; - Sem programação em baixa tensão, sem proteção de código, sem proteção da memória EEPROM
	__config _XT_OSC & _WDT_OFF & _PWRTE_OFF & _CP_OFF & _LVP_OFF & _BODEN_OFF
	
	
;========================================================================================
; --- Paginação de Memória ---
	#define		bank0	bcf	STATUS,RP0		;Cria um mnemônico para selecionar o banco 0 de memória
	#define		bank1	bsf	STATUS,RP0		;Cria um mnemônico para selecionar o banco 1 de memória
	

;========================================================================================
; --- Mapeamento de Hardware ---
	#define		DISPLAY 	PORTD			;dados DISPLAY
	#define		LED			PORTC,7			;LED VERMELHO
	#define		LED2		PORTC,6			;LED VERDE
	#define		LED3		PORTC,4			;LED AMARELO
	#define		LED4		PORTC,5			;LED AZUL
	#define		LED5		PORTC,3			;LED RESET
	#define		Col1		PORTB,1			;Coluna 1 do teclado
	#define		Col2		PORTB,2			;Coluna 2 do teclado
	#define		Col3		PORTB,3			;Coluna 3 do teclado
	#define		LinA		PORTB,4			;Linha A do teclado
	#define		LinB		PORTB,5			;Linha B do teclado
	#define		LinC		PORTB,6			;Linha C do teclado
	#define		LinD		PORTB,7			;Linha D do teclado

	
	
;========================================================================================
; --- Registradores de Uso Geral ---
	cblock		H'20'						;Início da memória disponível para o usuário

	
	W_TEMP									;Registrador para armazenar o conteúdo temporário de work
	STATUS_TEMP								;Registrador para armazenar o conteúdo temporário de STATUS
	Controle								;Registrador de controle dos jogadores
	Control									;Registrador de controle dos numeros
	T0										;Registrador auxiliar para temporização
	T1										;Registrador auxiliar para temporização	
	J1										;Registrador auxiliar para guardar a senha da BOMBA
 
	endc									;Final da memória do usuário
	
	
;========================================================================================
;--- Vetor de RESET ---

org 0x00
goto inicio

;========================================================================================
; --- Vetor de Interrupção ---
	org			0x04						;As interrupções deste processador apontam para este endereço
	
; -- Salva Contexto --
	movwf 		W_TEMP						;Copia o conteúdo de Work para W_TEMP
	swapf 		STATUS,W  					;Move o conteúdo de STATUS com os nibbles invertidos para Work
	bank0									;Seleciona o banco 0 de memória (padrão do RESET) 
	movwf 		STATUS_TEMP					;Copia o conteúdo de STATUS com os nibbles invertidos para STATUS_TEMP
; -- Final do Salvamento de Contexto --
	
	btfsc 0x0B,1							;Verifica se a interrupçao foi do RB0
	call RESETHI							;RESETA O JOGO
	btfsc 0x0B, 2							;Verifica se a interrupçao foi do Timer 0
	call TIMER0								;APAGA/ACENDE O LED
	btfsc 0x0C,0							;Verifica se a interrupçao foi do Timer 1
	call TIMER1								;Configura o Timer 1 (TEMPO DA BOMBA) 

; -- Recupera Contexto (Saída da Interrupção) --
exit_ISR:

	swapf 		STATUS_TEMP,W				;Copia em Work o conteúdo de STATUS_TEMP com os nibbles invertidos
	movwf 		STATUS 						;Recupera o conteúdo de STATUS
	swapf 		W_TEMP,F 					;W_TEMP = W_TEMP com os nibbles invertidos 
	swapf 		W_TEMP,W  					;Recupera o conteúdo de Work
	
	retfie									;Retorna da interrupção
	
	
;========================================================================================	
; --- Principal ---

inicio:
	bank1		;Seleciona banco 1
	clrf 0x85 	;Configura PortA como saida
	movlw 0xF1	;move o literal F0h para Work
	movwf 0x86	;Configura o RB7, RB6, RB5, RB4, RB0 como entrada
	clrf 0x87	;Configura PortC como saida
	clrf 0x88	;Configura PortD como saida
	clrf 0x89	;Configura PortE como saida
	movlw 0x87	;move o literal 87h para Work
	movwf 0x81	;Configura option_reg definindo o pré do timer 0 (111)= 1:256 
	clrf 0x8C	; PIE1
	bsf 0x8C,0	; PIE1,0 = 1 / Para interrupcao do timer 1
	
	bank0			;Seleciona Banco 0
	clrf 0x05		;Limpa PORTA
	clrf 0x06		;Limpa PORTB
	clrf 0x07		;Limpa PORTC
	clrf DISPLAY	;Limpa PORTD (DISPLAY)
	clrf 0x09		;Limpa PORTE 	
	clrf 0x10		;Limpa o T1CON. DESATIVANDO O TIMER1
	bcf 0x0B,5 		;DESATIVA O TIMER0
	bsf 0x0B,4		;Liga a interrupcao do RB0
	bsf 0x0B,7		;Habilita as Interrupções
	movlw 0x02		;move o literal 02h para Work
	movwf Controle	;Configura o valor da variavel de controle do jogador
	movwf Control 	;Configura o valor da variavel de controle do numero
;========================================================================================	
; --- Loop Infinito para ler o teclado (VARREDURA DAS COLUNAS) ---

	loop:
		bcf Col1
	    bsf Col2
	    bsf Col3
			btfss LinA
			goto b1
			btfss LinB
			goto b4
			btfss LinC
			goto b7
			btfss LinD
			goto ASTERISCO
	
		bsf Col1
	    bcf Col2
	    bsf Col3
			btfss LinA
			goto b2
			btfss LinB
			goto b5
			btfss LinC
			goto b8
			btfss LinD
			goto b0
			
		bsf Col1
	    bsf Col2
	    bcf Col3
			btfss LinA
			goto b3
			btfss LinB
			goto b6
			btfss LinC
			goto b9
			btfss LinD
			goto ENVIA
		
		btfsc LED5
			goto inicio
		goto loop
		
;========================================================================================	
; --- Desenvolvimento das Sub Rotinas dos Timers ---	
	
;========================================================================================
; --- Sub Rotina para o TIMER1 (TEMPO PARA BOMBA EXPLODIR) ---	
	TIMER1:
		bcf 0x0C,0		;Abaixa a flag do TIMER 1
		movlw 0xDC		;Move o literal DCh para o Work
		movwf 0x0E		;Configura o TIMER1L
		movlw 0x0B		;Move o literal 0Bh para o Work
		movwf 0x0F		;Configura o TIMER1H
		decfsz T1,1		;Se T1=0 pule. A bomba explodiu.
		RETURN			;T1!=0 (AINDA NÃO EXPLODIU)
		bsf LED			;T1=0. ACENDE LED VERMELHO (BOMBA EXPLODIU)
		clrf 0x10		;Limpa o T1CON. DESATIVANDO O TIMER1
		bcf 0x0B,5 		;DESATIVA O TIMER0
		loop1:
			btfsc LED5	;Se LED RESET=0 pule.
			goto inicio	;LED=1 (RESETA O JOGO)		;loop infinito 
		goto loop1		;
		
;========================================================================================
; --- Sub Rotina para TIMER 0 (LED VERMELHO PISCANDO) ---	
	TIMER0:
		bcf 0x0B,2		;abaixa a flag do TIMER0
		decfsz T0,1		;Se T0=0 pule.
		goto ACENDER	;T=1. (ACENDE LED)
		goto APAGAR		;T=0. (APAGA LED)

	ACENDER:
		bsf LED		;Acende Led
		return
		
	APAGAR:
		bcf LED		;Apaga Led
		movlw 0x02	;move o literal 02h para o Work
		movwf T0	;configura o T0 novamente
		return
			


;========================================================================================	
; --- Desenvolvimento das Sub Rotinas de RESET ---	
;========================================================================================
; --- Sub Rotina para BOTÃO RB0 ---
RESETHI:
	bcf 0x0B,1		;Abaixa a flag do RB0
	bsf LED5		;LIGA LED RESET
	return
	

;========================================================================================	
; --- Desenvolvimento das Sub Rotinas dos Botões ---	
;========================================================================================
; --- Sub Rotina para BOTÃO 0 ---
b0:
decfsz Control			;Decrementa a variavel de controle dos numeros
goto B01				;Foi o primeiro Numero digitado?
goto B02				;Foi o segundo Numero digitado?

B01:call BOTAOAPERTADO7	;Espera o botão parar de ser apertado
	movlw 0x00			;move o literal 20h para o Work
	movwf DISPLAY		;Configura o display
	goto loop			;Chama o teclado novamente para o segundo numero

B02:call BOTAOAPERTADO7	;Espera o botão parar de ser apertado
	movlw 0x00			;move o literal 02h para o Work
	addwf DISPLAY,1		;Configura o display
	movlw 0x02			;move o literal 02h para o Work
	movwf Control		;Configura novamente o Controle dos Numeros
	goto SALVASENHA		;SALVA A SENHA DIGITADA
;========================================================================================
; --- Sub Rotina para BOTÃO 1 ---
b1:
decfsz Control			;Decrementa a variavel de controle dos numeros
goto B11				;Foi o primeiro Numero digitado?
goto B12				;Foi o segundo Numero digitado?

B11:call BOTAOAPERTADO	;Espera o botão parar de ser apertado
	movlw 0x10			;move o literal 10h para o Work
	movwf DISPLAY		;Configura o display
	goto loop			;Chama o teclado novamente para o segundo numero

B12:call BOTAOAPERTADO	;Espera o botão parar de ser apertado
	movlw 0x01			;move o literal 01h para o Work
	addwf DISPLAY,1		;Configura o display
	movlw 0x02			;move o literal 02h para o Work
	movwf Control		;Configura novamente o Controle dos Numeros
	goto SALVASENHA		;SALVA A SENHA DIGITADA
;========================================================================================
; --- Sub Rotina para BOTÃO 2 ---
b2:
decfsz Control			;Decrementa a variavel de controle dos numeros
goto B21				;Foi o primeiro Numero digitado?
goto B22				;Foi o segundo Numero digitado?

B21:call BOTAOAPERTADO	;Espera o botão parar de ser apertado
	movlw 0x20			;move o literal 20h para o Work
	movwf DISPLAY		;Configura o display
	goto loop			;Chama o teclado novamente para o segundo numero

B22:call BOTAOAPERTADO	;Espera o botão parar de ser apertado
	movlw 0x02			;move o literal 02h para o Work
	addwf DISPLAY,1		;Configura o display
	movlw 0x02			;move o literal 02h para o Work
	movwf Control		;Configura novamente o Controle dos Numeros
	goto SALVASENHA		;SALVA A SENHA DIGITADA
;========================================================================================
; --- Sub Rotina para BOTÃO 3 ---
b3:
decfsz Control			;Decrementa a variavel de controle dos numeros
goto B31				;Foi o primeiro Numero digitado?
goto B32				;Foi o segundo Numero digitado?

B31:call BOTAOAPERTADO	;Espera o botão parar de ser apertado
	movlw 0x30			;move o literal 30h para o Work
	movwf DISPLAY		;Configura o display
	goto loop			;Chama o teclado novamente para o segundo numero

B32:call BOTAOAPERTADO	;Espera o botão parar de ser apertado
	movlw 0x03			;move o literal 03h para o Work
	addwf DISPLAY,1		;Configura o display
	movlw 0x02			;move o literal 02h para o Work
	movwf Control		;Configura novamente o Controle dos Numeros
	goto SALVASENHA		;SALVA A SENHA DIGITADA	
;========================================================================================
; --- Sub Rotina para BOTÃO 4 ---	
b4:
decfsz Control			;Decrementa a variavel de controle dos numeros
goto B41				;Foi o primeiro Numero digitado?
goto B42				;Foi o segundo Numero digitado?

B41:call BOTAOAPERTADO5	;Espera o botão parar de ser apertado
	movlw 0x40			;move o literal 40h para o Work
	movwf DISPLAY		;Configura o display
	goto loop			;Chama o teclado novamente para o segundo numero

B42:call BOTAOAPERTADO5	;Espera o botão parar de ser apertado
	movlw 0x04			;move o literal 04h para o Work
	addwf DISPLAY,1		;Configura o display
	movlw 0x02			;move o literal 02h para o Work
	movwf Control		;Configura novamente o Controle dos Numeros
	goto SALVASENHA		;SALVA A SENHA DIGITADA	
;========================================================================================
; --- Sub Rotina para BOTÃO 5 ---	
b5:
decfsz Control			;Decrementa a variavel de controle dos numeros
goto B51				;Foi o primeiro Numero digitado?
goto B52				;Foi o segundo Numero digitado?

B51:call BOTAOAPERTADO5	;Espera o botão parar de ser apertado
	movlw 0x50			;move o literal 50h para o Work
	movwf DISPLAY		;Configura o display
	goto loop			;Chama o teclado novamente para o segundo numero

B52:call BOTAOAPERTADO5	;Espera o botão parar de ser apertado
	movlw 0x05			;move o literal 05h para o Work
	addwf DISPLAY,1		;Configura o display
	movlw 0x02			;move o literal 02h para o Work
	movwf Control		;Configura novamente o Controle dos Numeros
	goto SALVASENHA		;SALVA A SENHA DIGITADA
;========================================================================================
; --- Sub Rotina para BOTÃO 6 ---
b6:
decfsz Control			;Decrementa a variavel de controle dos numeros
goto B61				;Foi o primeiro Numero digitado?
goto B62				;Foi o segundo Numero digitado?

B61:call BOTAOAPERTADO5	;Espera o botão parar de ser apertado
	movlw 0x60			;move o literal 60h para o Work
	movwf DISPLAY		;Configura o display
	goto loop			;Chama o teclado novamente para o segundo numero

B62:call BOTAOAPERTADO5	;Espera o botão parar de ser apertado
	movlw 0x06			;move o literal 06h para o Work
	addwf DISPLAY,1		;Configura o display
	movlw 0x02			;move o literal 02h para o Work
	movwf Control		;Configura novamente o Controle dos Numeros
	goto SALVASENHA		;SALVA A SENHA DIGITADA
;========================================================================================
; --- Sub Rotina para BOTÃO 7 ---
b7:
decfsz Control			;Decrementa a variavel de controle dos numeros
goto B71				;Foi o primeiro Numero digitado?
goto B72				;Foi o segundo Numero digitado?

B71:call BOTAOAPERTADO6	;Espera o botão parar de ser apertado
	movlw 0x70			;move o literal 70h para o Work
	movwf DISPLAY		;Configura o display
	goto loop			;Chama o teclado novamente para o segundo numero

B72:call BOTAOAPERTADO6	;Espera o botão parar de ser apertado
	movlw 0x07			;move o literal 07h para o Work
	addwf DISPLAY,1		;Configura o display
	movlw 0x02			;move o literal 02h para o Work
	movwf Control		;Configura novamente o Controle dos Numeros
	goto SALVASENHA		;SALVA A SENHA DIGITADA	
;========================================================================================
; --- Sub Rotina para BOTÃO 8 ---
b8:
decfsz Control			;Decrementa a variavel de controle dos numeros
goto B81				;Foi o primeiro Numero digitado?(DEZENA)
goto B82				;Foi o segundo Numero digitado? (UNIDADE)

B81:call BOTAOAPERTADO6	;Espera o botão parar de ser apertado
	movlw 0x80			;move o literal 80h para o Work
	movwf DISPLAY		;Configura o display
	goto loop			;Chama o teclado novamente para o segundo numero

B82:call BOTAOAPERTADO6	;Espera o botão parar de ser apertado
	movlw 0x08			;move o literal 08h para o Work
	addwf DISPLAY,1		;Configura o display
	movlw 0x02			;move o literal 02h para o Work
	movwf Control		;Configura novamente o Controle dos Numeros
	goto SALVASENHA		;SALVA A SENHA DIGITADA	
;========================================================================================
; --- Sub Rotina para BOTÃO 9 ---
b9:
decfsz Control			;Decrementa a variavel de controle dos numeros
goto B91				;Foi o primeiro Numero digitado?(DEZENA)
goto B92				;Foi o segundo Numero digitado? (UNIDADE)

B91:call BOTAOAPERTADO6	;Espera o botão parar de ser apertado
	movlw 0x90			;move o literal 90h para o Work
	movwf DISPLAY		;Configura o display
	goto loop			;Chama o teclado novamente para o segundo numero

B92:call BOTAOAPERTADO6	;Espera o botão parar de ser apertado
	movlw 0x09			;move o literal 09h para o Work
	addwf DISPLAY,1		;Configura o display
	movlw 0x02			;move o literal 02h para o Work
	movwf Control		;Configura novamente o Controle dos Numeros
	goto SALVASENHA		;SALVA A SENHA DIGITADA	
;========================================================================================
; --- Sub Rotina para BOTÃO * ---
ASTERISCO:
	clrf DISPLAY		;Limpa o DISPLAY
	movlw 0x02			;move o literal 02h para o Work
	movwf Control		;Configura novamente o Controle dos Numeros
	goto loop			;Volta pro loop do teclado
;========================================================================================
; --- Sub Rotina para BOTÃO # ---
ENVIA:
	bcf LED3
	bcf LED4
	movlw 0x02			;move o literal 02h para o Work
	movwf Control		;Configura novamente o Controle dos Numeros
	movf DISPLAY, 0		;w=DISPLAY
	decfsz Controle		;Se Controle=0 pule.
	goto START			;Controle=1 (VEZ DO JOGADOR 1)
	goto CONFERIR		;Controle=0 (VEZ DO JOGADOR 2)

;========================================================================================	
; --- Desenvolvimento das Sub Rotinas para esperar o botão parar de ser pressionado ---
;========================================================================================
; --- Sub Rotina para Linha A ---
BOTAOAPERTADO:
			btfss LinA			;Se LinA=1 pule. (Botão não está pressionado)
			goto BOTAOAPERTADO	;LinA=0 (Botão pressionado)
			return				;LinA=1 (Botão não está pressionado)
;========================================================================================
; --- Sub Rotina para Linha B ---			
BOTAOAPERTADO5:
			btfss LinB			;Se LinB=1 pule. (Botão não está pressionado)
			goto BOTAOAPERTADO5	;LinB=0 (Botão pressionado)
			return				;LinB=1 (Botão não está pressionado)
;========================================================================================
; --- Sub Rotina para Linha C ---				
BOTAOAPERTADO6:		
			btfss LinC			;Se LinC=1 pule. (Botão não está pressionado)
			goto BOTAOAPERTADO6	;LinC=0 (Botão pressionado)
			return				;LinC=1 (Botão não está pressionado)
;========================================================================================
; --- Sub Rotina para Linha D ---
BOTAOAPERTADO7:
			btfss LinD			;Se LinD=1 pule. (Botão não está pressionado)
			goto BOTAOAPERTADO7	;LinD=0 (Botão pressionado)
			return				;LinD=1 (Botão não está pressionado)
			
;========================================================================================	
; --- Desenvolvimento das Sub Rotinas para controlar o jogo ---
;========================================================================================
; --- Sub Rotina para salvar a senha ---
SALVASENHA:
	movf DISPLAY, 0 ;W=DISPLAY
	decfsz Controle ;Se Controle=0 pule.(VEZ DO JOGADOR2) 
	goto ENTER		;Controle=1 (VEZ DO JOGADOR1) 
	goto ENTER2		;Controle=0 (VEZ DO JOGADOR2)
;========================================================================================
; --- Sub Rotina para esperar o # OU * DO PRIMEIRO JOGADOR ---
ENTER:	
	bsf Col1
	bsf Col2
    bcf Col3
		btfss LinD
		goto START
	bcf Col1
	bsf Col2
    bsf Col3
		btfss LinD
		goto ASTERISCO1
		
		btfsc LED5	;Se LED RESET=0 pule.
		goto inicio	;LED=1 (RESETA O JOGO)
	goto ENTER
;========================================================================================
; --- Sub Rotina para começar o jogo ---
START:
	call BOTAOAPERTADO7
	movwf J1		;Salva a senha do jogador na variavel J1
	clrf DISPLAY	;Limpa o DISPLAY
	movlw 0xF0		;move o literal E0h para Work
	movwf 0x0B		;Configura o INTCON B'11110000'
	clrf 0x0C		;Limpa PIR1
	movlw 0xDC 		;move o literal DCh para Work 
	movwf 0x0E 		;Configura o TIMER 1 L
	movlw 0x0B 		;move o literal OBh para Work
	movwf 0x0F		;Configura o TIMER 1 H 
	movlw 0x31		;move o literal 31h para Work
	movwf 0x10		;PRÉ TIMER1 11 = 1:8 E T1ON =1
	movlw .30  		;move o literal 30d para Work
	movwf T1		;Configura o valor da variavel auxiliar do timer 1
	movlw 0x02		;move o literal 02h para Work
	movwf T0		;Configura o valor da variavel auxiliar do timer 0
	goto loop	
;========================================================================================
; --- Sub Rotina para apagar a unidade do display ---	
ASTERISCO1:
call BOTAOAPERTADO7	;Espera o botão ser pressionado
bcf DISPLAY,0		;Apaga o display da unidade
bcf DISPLAY,1	
bcf	DISPLAY,2
bcf	DISPLAY,3
incf Controle		;configura o Controle do jogador
movlw 0x01			;move o literal 01h para o Work
movwf Control		;configura o Controle do Numero
goto loop			;volta para o loop do teclado
;========================================================================================
; --- Sub Rotina para esperar o # OU * DO SEGUNDO JOGADOR ---
ENTER2:
	bcf LED4	;APAGA O LED AZUL
	bcf LED3 	;APAGA O LED AMARELO
	bsf Col1	
	bsf Col2	
    bcf Col3	
		btfss LinD
		goto CONFERIR
	bcf Col1
	bsf Col2
    bsf Col3
		btfss LinD
		goto ASTERISCO1
	
		btfsc LED5	;Se LED RESET=0 pule.
		goto inicio	;LED=1 (RESETA O JOGO)
	goto ENTER2
;========================================================================================
; --- Sub Rotina para verificar se o segundo jogador acertou a senha ---	
CONFERIR:
	call BOTAOAPERTADO7 ; Espera Botão pressionado
	subwf J1,0		; (J1-J2) D=0 para não perder a senha do Jogador 1
	btfsc STATUS, Z ; Se Z = 0 pule. (J1 != "J2")
	goto ACERTOU	;Z = 1. (J1 == "J2")
	goto ERROU		;Z = 0. (J1 != "J2")
;========================================================================================
; --- Sub Rotina caso o SEGUNDO JOGADOR TENHA ERRADO A SENHA ---	
ERROU:	
	clrf DISPLAY	;LIMPA O DISPLAY
	movlw 0x01		;move o literar 01h para o Work
	movwf Controle	;Configura o controle do jogador
	btfss    STATUS, C   ; Se C = 1 pule. (J1 > "J2")
	goto MAIOR	;C = 0. (J1 > "J2")
	goto MENOR	;C = 1. (J1 < "J2")
MAIOR:
	bsf LED4    ;ACENDE O LED AZUL  
	goto loop	;JOGADOR 2 Digita outro numero
MENOR:	
	bsf LED3   	;ACENDE O LED AMARELO
	goto loop	;JOGADOR 2 Digita outro numero
;========================================================================================
; --- Sub Rotina caso o SEGUNDO JOGADOR TENHA ACERTADO A SENHA ---	
ACERTOU:	
	clrf 0x10	;Limpa o T1CON	(DESARMA A BOMBA)
	bcf 0x0B,5 	;DESATIVA O T0
	bsf LED2	;ACENDE LED VERDE
	bsf LED3	;ACENDE O LED AMARELO
	bsf LED4	;ACENDE O LED AZUL
	bcf LED		;APAGA O LED VERMELHO
	
	loop2:btfsc LED5	;Se LED RESET=0 pule.
			goto inicio	;LED=1 (RESETA O JOGO)
		goto loop2


;========================================================================================	
; --- Final do Programa ---	
END
;========================================================================================
