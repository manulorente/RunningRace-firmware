; * *************************************** *
; * Encabezados                             *
; * *************************************** *

;-------------------------
LIST  P=16F84A
;-------------------------
;--LIST  P=16F88
;-------------------------

;===========================
; Palabra de configuraci�n 
;===========================
IFDEF __16F84A
   INCLUDE     <P16F84A.INC>
   __CONFIG    _CP_OFF &  _WDT_OFF & _PWRTE_OFF & _XT_OSC
   
ELSE
   INCLUDE   <P16F88.INC>
   __CONFIG  _CONFIG1, _XT_OSC & _CP_OFF & _CCP1_RB0 & _DEBUG_OFF & _WRT_PROTECT_OFF & _CPD_OFF & _LVP_OFF & _BODEN_OFF & _MCLR_ON & _PWRTE_OFF & _WDT_OFF ;  & _INTRC_IO  
   __CONFIG  _CONFIG2, _IESO_OFF & _FCMEN_OFF 
   
   ;---------------------------------------------
   ; En el 16F88 cambia el nombre de estos 2 bits
   ;---------------------------------------------
   #define T0IF   TMR0IF  
   #define T0IE   TMR0IE  

ENDIF


; * ************************************************************************ *
; * Configuraci�n Timer 0: temporizaci�n a 1 segundo (Fosc=4Mhz)
; *
; * Tiempo= 4.Tosc.(256-TMR0).Preescalador
; *      Si Tosc=0.25us (Fosc=4Mhz),  TMR0=12  y Preescalador= 1:256  ([PS2:PS0]=111)->
; *      Tiempo= 4.(0.25us).(256-12).256= 0,062464 seg. -> (16,00 hz)
; * 
; * Cada 16 interrupciones se tiene 16x 0,062464 seg.= 0.9992 seg.
; * ************************************************************************ *

    
; * *************************************** *
; * Variables globales                      *
; * *************************************** *
IFDEF __16F84A
   CBLOCK H'0C'
      W_TEMP, STATUS_TEMP, FSR_TEMP, PCLATH_TEMP   ; para las interrupciones
      cuenta5           ; N�mero de interrupciones para tener una centesima de segundo
      cuenta100         ; N�mero de centesimas de segundo para tener 1 segundo
      segundos          ; Segundos transcurridos
      centesimas        ; Cent�simas de segundo transcurridas
      tr_centesimas     ; tiempo de reacci�n cent�simas de segundo
      tr_segundos       ; tiempo de reacci�n segundos
      tt_centesimas     ; tiempo total cent�simas de segundos
      tt_segundos       ; tiempo total segundo
      decena            ; decenas
      unidad            ; unidades
      fin               ; bandera de fin de carrera
      var_aux1          ; variable auxiliar
                        ; -------------------------------------------------------------------------
                        ;  Registro   | Byte  | Direcci�n | Equivalencia C (dos byte por proceso) |
                        ; .........................................................................              
      estadoAct:2       ; estadoAct+0 |  alto |   0x--    |                                       |
                        ; estadoAct+1 |  bajo |   0x--    | estadoAct(estadoAct+0,estadoAct+1)   |
                        ; .........................................................................              
      estadoSig:2       ; estadoSig+0 |  alto |   0x--    |                                       |
                        ; estadoSig+1 |  bajo |   0x--    | estadoSig(0x0E, 0x0F)                |
                        ; -------------------------------------------------------------------------
   ENDC 
ELSE
   ; En el rango H'70' a H'7F' los 4 bancos redireccionan
   ; a las mismas variables del banco 0 para el PIC16F88.
   
   CBLOCK H'70'   ;van desde H'70' hasta H'7F' 
      W_TEMP, STATUS_TEMP, FSR_TEMP, PCLATH_TEMP   ; para las interrupciones
      segundos          ; N�mero que se muestra en el display
      cuenta5           ; N�mero de interrupciones para tener una centesima de segundo
      cuenta100         ; N�mero de centesimas de segundo para tener 1 segundo
      centesimas        ; cent�simas de segundo
                        ; -------------------------------------------------------------------------
                        ;  Registro   | Byte  | Direcci�n | Equivalencia C (dos byte por proceso) |
                        ; .........................................................................              
      estadoAct:2       ; estadoAct+0 |  alto |   0x0C    |                                       |
                        ; estadoAct+1 |  bajo |   0x0D    | estadoAct(estadoAct+0,estadoAct+1)   |
                        ; .........................................................................              
      estadoSig:2       ; estadoSig+0 |  alto |   0x0E    |                                       |
                        ; estadoSig+1 |  bajo |   0x0F    | estadoSig(0x0E, 0x0F)                |
                        ; -------------------------------------------------------------------------
  ENDC 
ENDIF



; * *************************************** *
; * Macros                                             *
; * *************************************** *
; PUSH: guarda temporalmente  W, FSR, STATUS y PCLATH 
PUSH  MACRO 
        MOVWF    W_TEMP            ; W_TEMP     = W;         // intercambia nibbles
        SWAPF    STATUS,W          ;                         // No afecta las banderas
        MOVWF    STATUS_TEMP       ; STATUS_TEMP= STATUS;    
        MOVF     PCLATH,W          ;
        MOVWF    PCLATH_TEMP       ; PCLATH_TEMP= PCLATH;
        CLRF     PCLATH            ; PCLATH     = 0; 
        MOVF     FSR,W             ;
        MOVWF    FSR_TEMP          ; FSR_TEMP   = FSR;
        ENDM 
; PULL: restaura  W, FSR, STATUS y PCLATH 
PULL  MACRO 
        MOVF     FSR_TEMP,W        ;  
        MOVWF    FSR               ; FSR   = FSR_TEMP; 
        MOVF     PCLATH_TEMP,W     ;
        MOVWF    PCLATH            ; PCLATH= PCLATH_TEMP;
        SWAPF    STATUS_TEMP,W     ;                         // intercambia nibbles
        MOVWF    STATUS            ; STATUS= STATUS_TEMP;    // No afecta las banderas
        SWAPF    W_TEMP,F          ;                 
        SWAPF    W_TEMP,W          ; W     = W_TEMP;
        ENDM 
; * **************************************************** *
; * Librer�as (cabeceras. Despues de Variables globales) *
; * **************************************************** *
                        
INCLUDE  <LCD.h>

        
; * *************************************** *
; * Vector de interrupci�n: RESET           *
; * *************************************** *
reset   ORG   0                 ; El programa comienza en la direcci�n 0.
        goto  inicio            ; Saltamos justo despu�s del vector de interrupci�n (direcci�n 4)
    
; * *************************************** *
; * Vector de interrupci�n: interrupcion    *
; * *************************************** *
        ORG    04               ; Debera saltar a la subrutina de interrupcion 
        PUSH                    ; Macro PUSH: Guarda los registros 
           call   interrupcion  ; Llama a la rutina llamada "interrupcion"
        PULL                    ; Macro PULL: restaura los registros 
        retfie                  ; Retorno de interrupci�n: 
                                ;    (a) Recupera de la pila la direcci�n de retorno y la pone en PC
                                ;    (b) Reactiva el bit GIE=1 que se puso a 0 durante la interrupci�n 
     
    
    
    
; * *************************************** *
; * M�dulo inicial                          *
; * *************************************** *
inicio                              ;
   call    iniciaRegistros          ;   iniciaRegistros();
    
    
; * *************************************** *
; * M�dulo Principal. Bucle infinito        *
; * *************************************** *
inf                                 ; while (1)
                                    ; {
     ;------------------         ;  {
     call    estado              ;      estado();
     ;------------------         ;
 
      goto    inf                   ; } 

;*******************************************
; Rutinas de estados
;*******************************************
estado
   movf    estadoSig+0,W         ;
   movwf   estadoAct+0           ; // estadoAct(byte alto)= estadoSig(byte alto)
   movwf   PCLATH                ; // PCLATH = estadoAct(byte alto).  Registro auxiliar
                                 ;
   movf    estadoSig+1,W         ;
   movwf   estadoAct+1           ; // estadoAct(byte bajo)= estadoSig(byte bajo)
   movwf   PCL                   ; // PCL = estadoAct(byte bajo). Esta asignaci�n implica
                                 ; //   que PCH= PCLATH a la vez. El registro PC actualiza
                                 ; //   sus dos bytes de golpe con los registros PCLATH,PCL
                                 ; //   PC (2bytes)= [PCH,PCL]= [PCLATH,PCL]
                                 ;
                                 ; estadoAct= estadoSig;    
                                 ; PC= estadoAct;           // El contador de programa ir� a 
                                 ;                          // la direcci�n dada por "estadoAct"
      
      
      
; * *************************************** *
; * Rutinas                                 *
; * *************************************** *

;*******************************************
; Rutinas para los procesos
;*******************************************   
INCLUDE "inicializacion.asm"         ; Rutina de la atenci�n a la interrupci�n
INCLUDE "maq_estado.asm"             ; Rutina de la m�quina de estados
INCLUDE "interrupcion.asm"           ; Rutina de la atenci�n a la interrupci�n
INCLUDE  <LCD.asm>                   ; ======================================================  ========================
                                     ; Variables globales   | Posici�n (en esta aplicacion) |  |  Rutinas             |
                                     ; ------------------------------------------------------  -----------------------+
                                     ; LCD_var_dato         |  0x14                         |  | LCD_ini              |
                                     ; LCD_var_TRIS         |  0x15                         |  | LCD_enviaCaracter(W) |
                                     ; LCD_var_aux1         |  0x16                         |  | LCD_irLineaInf       |
                                     ; LCD_var_aux2         |  0x17                         |  | LCD_irLineaSup       |
                                     ; LCD_var_cursor       |  0x18                         |  | LCD_lineaEnBlanco    |
                                     ; retardo_a            |  0x19                         |  | LCD_1_blanco         |
                                     ; retardo_b            |  0x1A                         |  | LCD_2_blancos        |
                                     ; ======================================================  | LCD_3_blancos        |
                                     ;                                                         | LCD_4_blancos        |
                                     ; ===============================================         +----------------------+
                                     ; define             | Ubicaci�n (posici�n)     |         | LCD_irFilCol(W)      |
                                     ; -------------------+--------------------------|         | LCD_apaga            |
                                     ; LCD_BUS_PORT       | PORTA, PORTB             |         | LCD_enviaComando     |
                                     ; LCD_E_PORT         | PORTA, PORTB             |         ========================
                                     ; LCD_RS_PORT        | PORTA, PORTB             |
                                     ; LCD_BUS_PINES      | b'00001111', b'11110000' |
                                     ; LCD_E_PIN          | 0,1,2,3,4,5,6,7          |
                                     ; LCD_RS_PIN         | 0,1,2,3,4,5,6,7          |
                                     ; ===============================================

    END