# Bomba-com-senha-em-ASSEMBLY
Jogo de bomba com senha. - Um jogador arma a bomba com uma senha e outro desarma no tempo estimado.

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
