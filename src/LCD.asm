; * ********************************************************************************* *
; * ************                   Fichero: LCD_LM016.INC                ************ *
; * ********************************************************************************* *
IFNDEF     LCD_LM016_asm          ;  ENDIF al final del fichero
#define    LCD_LM016_asm          ;  Si se llama dos veces al fichero, la 2� no se incluye
;
; * *************************************** *
; * Constantes y definiciones               *
; * *************************************** *
IFNDEF  _XTAL_FREQ
   #define _XTAL_FREQ 4000000            // Reloj a 4Mhz       
ENDIF

IFNDEF LCD_BUS_PORT
     #define  LCD_BUS_PORT   PORTB
ENDIF
IFNDEF LCD_E_PORT
     #define  LCD_E_PORT     PORTB
ENDIF
IFNDEF LCD_RS_PORT
     #define  LCD_RS_PORT    PORTB
ENDIF
IFNDEF LCD_BUS_PINES
     #define  LCD_BUS_PINES   b'00001111'            ; Bits <0:3> de LCD_BUS_PORT=PORTB
ENDIF
IFNDEF LCD_E_PIN
     #define  LCD_E_PIN              2
ENDIF
IFNDEF LCD_RS_PIN
     #define  LCD_RS_PIN             3
ENDIF

#define LCD_E   LCD_E_PORT,LCD_E_PIN 
#define LCD_RS  LCD_RS_PORT,LCD_RS_PIN 

#define LCD_var_envia   FSR          ; Utilizada solo en la rutina LCD_envia_4bits



; * *************************************** *
; * Variables globales                      *
; * *************************************** *
     CBLOCK
     LCD_var_dato         ; Utilizada solo por LCD_enviaCaracter y LCD_enviaComando
     LCD_var_TRIS         ; Utilizada en la rutina LCD_ini y LCD_envia_4bits
     LCD_var_aux1
     LCD_var_aux2
     LCD_var_cursor       ; Fila y columna del cursor:  LCD_var_cursor=b'f000cccc'
                          ; El bit m�s significativo indica la fila: f=0->superior, 
                          ; f=1->inferior, Los 4 bits menos significativos especifican 
                          ; la columna
     retardo_a
     retardo_b
     ENDC


; * *************************************** *
; * Rutinas de retardos                     *
; * *************************************** *
; =================================================================================
; Rutinas de retardos: 
;  - retardo_4us  :  call: 2us,  return: 2us.
;  - retardo_50us :  8 + 3*retardo_b =    50 �s. (retardo_b= 14). (para 4Mhz)
;  - retardo_20us :  5 + 3*retardo_b =    20 �s. (retardo_b=  5).
;
;    Instrucciones de 2 ciclos m�quina: call, return y goto.
; =================================================================================
retardo_4us
  IF  _XTAL_FREQ == 8000000
     nop
     nop
     nop
     nop
  ENDIF
     ;----------------------      ------------------------------------------
     banksel PORTA                ; [RP1,RP0]=00. Selecciona el banco 0
     ;----------------------      ------------------------------------------
     return

retardo_50us                      ; duraci�n= 2cm (llamada 'call').
     banksel  retardo_b
     nop                          ; duraci�n= 1cm.
     movlw    d'14'               ; duraci�n= 1cm. retardo_b=14.
     goto     retardo_us          ; duraci�n= 2cm y contin�a
retardo_us                        ; Ciclos desde esta etiqueta hasta el final: 2+3*retardo_b
     movwf    retardo_b           ; duraci�n= 1cm.
retardo_us1
  IF  _XTAL_FREQ == 8000000
     nop
     nop
  ENDIF
     decfsz   retardo_b,F         ; (retardo_b-1)*1 cm (si no salta) + 2 cm (si salta).
     goto     retardo_us1         ; retardo_b-1)*2.
     ;----------------------      ------------------------------------------
     banksel PORTA                ; [RP1,RP0]=00. Selecciona el banco 0
     ;----------------------      ------------------------------------------
     return                       ; El salto del retorno 2cm.

     
retardo_150us                     ; duraci�n= 2cm (llamada 'call').
    call retardo_50us
    call retardo_50us
    call retardo_50us
    return


; =======================================================================================
; Rutinas: 
;  - retardo_20ms :  2(nop)+ [18+6*retardo_b+1542*retardo_a] =  20000 cm=    20ms. (retardo_a=12  y retardo_b=246).
;  - retardo_5ms  :  2(nop)+ [18+6*retardo_b+1542*retardo_a] =   5000 cm=     5ms. (retardo_a=3   y retardo_b=59).
;  - retardo_2ms  :  2(nop)+ [18+6*retardo_b+1542*retardo_a] =   2000 cm=     2ms. (retardo_a=1   y retardo_b=73).
;  - retardo_1ms  :  4(nop)+ [18+6*retardo_b+1542*retardo_a] =   1000 cm=     1ms. (retardo_a=0   y retardo_b=163).
;
;    Seudoc�digo:
;      1. retardo_a=x,  retardo_b=y
;      2. nop (2 o 4 seg�n la rutina)
;      3. �retardo_b=0?  (bucle)
;          3.1. Si. Ir a 4.
;          3.2. No. > retardo_b--.  
;                    > Ir a 3 (repetir bucle)
;      4. �retardo_a=0?
;          4.1. Si. Ir a 9.  (Salir ya que [retardo_a,retardo_b]=0x0000)
;          4.2. No. > retardo_a--;  
;                    > retardo_b=0xff.
;      5. Ir a 3. (repetir bucle)
;      9. fin
;
;    Instrucciones de 2 ciclos m�quina: call, return y goto.
; =======================================================================================
retardo_20ms                    ; duraci�n= 2cm (llamada 'call').
    banksel  retardo_b
    movlw    d'12'              ; duraci�n= 1cm. 
    movwf    retardo_a          ; duraci�n= 1cm. retardo_a=12.
    movlw    d'246'             ; duraci�n= 1cm.
    movwf    retardo_b          ; duraci�n= 1cm. retardo_b=246.
    goto     retardo_ms_nop     ; duraci�n= 2cm y contin�a
retardo_5ms                     ; duraci�n= 2cm (llamada 'call').
    banksel  retardo_b
    movlw    d'3'               ; duraci�n= 1cm.
    movwf    retardo_a          ; duraci�n= 1cm. retardo_a=3.
    movlw    d'59'              ; duraci�n= 1cm.
    movwf    retardo_b          ; duraci�n= 1cm. retardo_b=59.
    goto     retardo_ms_nop     ; duraci�n= 2cm y contin�a
retardo_2ms                     ; duraci�n= 2cm (llamada 'call').
    banksel  retardo_b
    movlw    d'1'               ; duraci�n= 1cm.
    movwf    retardo_a          ; duraci�n= 1cm. retardo_a=1.
    movlw    d'73'              ; duraci�n= 1cm.
    movwf    retardo_b          ; duraci�n= 1cm. retardo_b=73.
    goto     retardo_ms_nop     ; duraci�n= 2cm y contin�a
retardo_1ms                     ; duraci�n= 2cm (llamada 'call').
    banksel  retardo_b
    movlw    d'0'               ; duraci�n= 1cm. 
    movwf    retardo_a          ; duraci�n= 1cm. retardo_a=0. 
    movlw    d'163'             ; duraci�n= 1cm. 
    movwf    retardo_b          ; duraci�n= 1cm. retardo_b=163. 
    goto     retardo_ms_nop     ; duraci�n= 4cm y contin�a
retardo_ms_nop
    nop                         ; duraci�n= 1cm.
    nop                         ; duraci�n= 1cm.
    nop                         ; duraci�n= 1cm.
    nop                         ; duraci�n= 1cm.
retardo_ms_bucle                ; Ciclos desde aqu� hasta el final: 10+6*retardo_b+1542*retardo_a
    movf     retardo_b,F        ; duraci�n= (retardo_b+retardo_a*255)*1 + [(retardo_a*1)+1]
    btfsc    STATUS,Z           ; duraci�n= (retardo_b+retardo_a*255)*2 + [(retardo_a*1)+1]
    goto     retardo_ms_bucle1  ; duraci�n= (retardo_a+1)*2
    decf     retardo_b,F        ; duraci�n= (retardo_b+retardo_ax255)*1
    goto     retardo_ms_bucle   ; duraci�n= (retardo_b+retardo_ax255)*2
retardo_ms_bucle1
    movf     retardo_a,F        ; duraci�n= retardo_a*1 + 1
    btfsc    STATUS,Z           ; duraci�n= retardo_a*2 + 1
    goto     retardo_ms_fin     ; duraci�n= 2
    decf     retardo_a,F        ; duraci�n= retardo_a*1
    movlw    0xff               ; duraci�n= retardo_a*1
    movwf    retardo_b          ; duraci�n= retardo_a*1
  IF  _XTAL_FREQ == 8000000     ; 8Mhz
    nop
    nop
    nop
    nop
    nop
  ENDIF
    goto     retardo_ms_bucle   ; duraci�n= retardo_a*2
retardo_ms_fin
    ;----------------------        ------------------------------------------
    banksel PORTA                  ; [RP1,RP0]=00. Selecciona el banco 0
    ;----------------------        ------------------------------------------
    return                      ; duraci�n= 2cm.


     
; * *************************************** *
; * Rutinas                                                      *
; * *************************************** *

;=====================================================================================================
; LCD_ini
;
;  - Memoriza la configuraci�n de los 6 pines del puerto conectado al LCD
;     - El pin E es un pin exclusivo para el LCD por lo que se fijar� de salida
;  - Inicio del LCD seg�n especifica el fabricante:
;        * Retardo superior a 15ms para que se estabilice la tensi�n de alimentaci�n.
;        * Env�a b'0011'.
;        * Retardo superior a 4,1ms.
;        * Env�a b'0011'
;        * Retardo superior a 100us.
;        * Env�a b'0011'
;        * Retardo superior a 40us.
;        * Env�a b'0010'                      (Este valor configura el bus de 4 bits)
;  - Configuraci�n del resto de par�metros
;        * LCD de 2 l�neas, bus de 4 l�neas y caracteres de 5x7 puntos.
;        * Borra el contenido y sit�a el cursor al principio.
;        * Enciende la pantalla y cursor no visible.
;        * Cursor configurado en modo incremental y sin desplazamiento.
;=====================================================================================================
LCD_ini                           ;  void LCD_ini()
     ;------------------------    ;  {
     banksel TRISA   ; banco 1    ;
     ;------------------------    ;
     IFDEF __16F88                ;
       movlw  LCD_RS_PORT         ;     if (LCD_RS_PORT == PORTA)      //  �Es el puerto A (direcci�n 5 en los registros)?
       sublw  PORTA               ;     {
       btfss  STATUS,Z            ;
       goto   LCD_ini1            ;
       movlw  d'5'                ;
       sublw  LCD_RS_PIN          ;
       btfsc  STATUS,C            ;        if (LCD_RS_PIN<5)          
       goto   LCD_ini2            ;        {
       bcf    ANSEL,LCD_RS_PIN    ;           ANSEL[LCD_RS_PIN]=0;         // El pin SCL ser� digital
       goto   LCD_ini2            ;        }      
                                  ;     }             
LCD_ini1                          ;     else                        //  Es el puerto B (direcci�n 6 en los registros) para SCL
       movlw  d'6'                ;     {
       sublw  LCD_RS_PIN          ;
       btfsc  STATUS,C            ;        if (LCD_RS_PIN>=6)  {
       bcf    ANSEL,LCD_RS_PIN-1  ;           ANSEL[LCD_RS_PIN-1]=0;       // El pin SCL ser� digital  (RB6 que es AN5  �  RB7 que es AN6)
                                  ;        }      
LCD_ini2                          ;     }             
                                  ;
       movlw  LCD_E_PORT          ;     if (LCD_E_PORT == PORTA)      //  �Es el puerto A (direcci�n 5 en los registros)?
       sublw  PORTA               ;     {
       btfss  STATUS,Z            ;
       goto   LCD_ini3            ;
       movlw  d'5'                ;
       sublw  LCD_E_PIN           ;
       btfsc  STATUS,C            ;        if (LCD_E_PIN<5)          
       goto   LCD_ini4            ;        {
       bcf    ANSEL,LCD_E_PIN     ;           ANSEL[LCD_E_PIN]=0;         // El pin SDA ser� digital
       goto   LCD_ini4            ;        }      
                                  ;     }             
LCD_ini3                          ;     else                        //  Es el puerto B (direcci�n 6 en los registros) para SDA
       movlw  d'6'                ;     {
       sublw  LCD_E_PIN           ;
       btfsc  STATUS,C            ;        if (LCD_E_PIN>=6)  {
       bcf    ANSEL,LCD_E_PIN-1   ;           ANSEL[LCD_E_PIN-1]=0;       // El pin SDA ser� digital  (RB6 que es AN5  �  RB7 que es AN6)
                                  ;        }      
                                  ;     }     
LCD_ini4                          ;
       movlw  LCD_BUS_PORT        ;     if (LCD_BUS_PORT == PORTA)      //  �Es el puerto A (direcci�n 5 en los registros)?
       sublw  PORTA               ;     {
       btfss  STATUS,Z            ;
       goto   LCD_ini5            ;
       movlw  LCD_BUS_PINES       ;
       sublw  b'00001111'         ;
       btfss  STATUS,Z            ;        if (LCD_BUS_PINES==0b00001111)          
       goto   LCD_ini6            ;        {
       movlw  ~LCD_BUS_PINES      ;           
       andwf  ANSEL,F             ;           ANSEL= ANSEL & 0b11110000;    // Los 4 pines bajos de A son digitales
       goto   LCD_ini6            ;        }      
                                  ;     }             
LCD_ini5                          ;     else                        //  Es el puerto B (direcci�n 6 en los registros) para SDA
       movlw  LCD_BUS_PINES       ;
       sublw  b'11110000'         ;
       btfss  STATUS,Z            ;        if (LCD_BUS_PINES==0b11110000) 
       goto   LCD_ini6            ;      
       movlw  b'10011111'         ;           
       andwf  ANSEL,F             ;           ANSEL= ANSEL & 0b10011111;    // RB6,RB7 digitales, AN5,AN6
                                  ;        }      
LCD_ini6                          ;     }     
   ENDIF                          ;
     bcf     LCD_E                ;     TRISx[LCD_E_PIN]=0;         // Pin E de salida todo el tiempo
     bcf     LCD_RS               ;     TRISx[LCD_RS_PIN]=0;        // Pin E de salida todo el tiempo
     movf    LCD_BUS_PORT,W       ; 
     movwf   LCD_var_TRIS         ;     LCD_var_TRIS= TRISx;        // Guarda la config. del puerto de datos
                                  ;
     ;------------------------    ;
     banksel PORTA   ; banco 0    ;
     ;------------------------    ;
     bcf     LCD_E                ;     E=0                         // Deshabilita el LCD
     bcf     LCD_RS               ;     RS=0                        // Activa el modo comando
     call    retardo_20ms         ;                                 // Retardo de 20ms  (superior a 15 ms). 
     movlw   b'00000011'          ;
     call    LCD_envia_4bits_cmd  ;     LCD_envia_4bits_cmd(0x03);  // Primer dato al LCD
     call    retardo_5ms          ;                                 // Retardo de 5ms (superior a 4,1ms)
     movlw   b'00000011'          ; 
     call    LCD_envia_4bits_cmd  ;     LCD_envia_4bits_cmd(0x03);  // Segundo dato al LCD
     call    retardo_150us        ;                                 // Retardo de 150us (superior a 100us)
     movlw   b'00000011'          ;
     call    LCD_envia_4bits_cmd  ;     LCD_envia_4bits_cmd(0x03);  // Tercer dato al LCD
     call    retardo_50us         ;                                 // Retardo de 50us (superior a 40us)
     movlw   b'00000010'          ;
     call    LCD_envia_4bits_cmd  ;     LCD_envia_4bits_cmd(0x02);  // configurado con bus de 4 bits,
     ;----------------------      ;                                 // 2 l�neas en el display
     call    LCD_enciende         ;     LCD_enciende();             // 5x7, cursor no visible e incremental
     ;----------------------      ;
     return                       ;  }

;=====================================================================================================
; Rutinas:
;     LCD_envia_4bits_cmd
;        - Env�a 4 bits de un comando almacenado en los 4 bits superiores de W
;        - Fija RS=0 (modo comando) y salta a LCD_envia_4bits
;     LCD_envia_4bits_car
;        - Env�a 4 bits de un car�cter almacenado en los 4 bits superiores de W
;        - Fija RS=0 (modo caracter) y salta a LCD_envia_4bits
;     LCD_envia_4bits
;        - Configura temporalmente de salida los 4 pines del puerto conectado al bus del LCD
;        - Pone el dato en el puerto (4 bits superiores) respetando los 2 bits inferiores
;        - Pulso a nivel alto en E para que el LCD capture el dato.
;        - Se restaura la configuraci�n original del puerto conectado al bus del LCD (entrada/salida)
;=====================================================================================================
LCD_envia_4bits_cmd                 ;  void LCD_envia_4bits_cmd(byte W)
     ;------------------------      ;  {
     banksel PORTA   ; banco 0      ;
     ;------------------------      ;
     bcf    LCD_RS                  ;      RS=0;                           // Modo comando
     goto   LCD_envia_4bits         ;      
                                    ;      LCD_envia_4bits(W);
                                    ;  }
;--------------------------         ;  ---------------------------------------------------------------                                    
LCD_envia_4bits_car                 ;  void LCD_envia_4bits_car(byte W)
                                    ;  {
     bsf    LCD_RS                  ;      RS=1;                           // Modo car�cter
                                    ;
                                    ;      LCD_envia_4bits(W);             // Siguiente instrucci�n a ejecutar
                                    ;  }     
;--------------------------         ;  ---------------------------------------------------------------                                    
LCD_envia_4bits                     ;  void LCD_envia_4bits(byte W)
                                    ;  {
     IF LCD_BUS_PINES == b'11110000';      // Si el bus est� conectado a los 4 pines superiores de un puerto  
          movwf LCD_var_envia       ;      // del pic entonces se intercambian Nibbles en W  
          swapf LCD_var_envia,W     ;       
     ENDIF                          ;
     andlw  LCD_BUS_PINES           ;      W= W & LCD_BUS_PINES;      // Se filtran los 4 bits a enviar (un nibble)
     movwf  LCD_var_envia           ;      LCD_var_envia= W;          // Se almacena temporalmente el nibble a enviar
                                    ;
     movf   LCD_BUS_PORT,W          ;      // Lectura de los pines sobrantes del puerto conectado al LCD.
     andlw  ~LCD_BUS_PINES          ;      // Estos pines no se alterar�n al escribir en el puerto
     iorwf  LCD_var_envia,F         ;      LCD_var_envia|=  (PORTx &  ~LCD_BUS_PINES)       
     ;------------------------      ;
     banksel TRISA   ; banco 1      ;
     ;------------------------      ;
     movlw  ~LCD_BUS_PINES          ;      // Las 4 l�neas conectadas al bus del LCD se configuran     
     andwf  LCD_BUS_PORT,F          ;      TRISx= ~LCD_BUS_PINES;      // temporalmente de salida. 
     call   retardo_2ms             ;
     ;------------------------      ;  
     banksel PORTA   ; banco 0      ;
     ;------------------------      ;
     movf   LCD_var_envia,W         ;      // dato a enviar respetando el valor de los 2 pines inferiores del puerto
     movwf  LCD_BUS_PORT            ;      PORTx= LCD_var_envia;  // Env�a el dato de 4 bits al LCD. 
     BSF    LCD_E                   ;      E=1;                   //Pulso en el pin E de un microseg. que habilita el LCD
     call   retardo_4us             ;
     BCF    LCD_E                   ;      E=0;       
     call   retardo_2ms             ;
     ;------------------------      ;
     banksel TRISA   ; banco 1      ;
     ;------------------------      ;
     movf   LCD_var_TRIS,W          ;                                 // Lee la config. original del puerto
     movwf  LCD_BUS_PORT            ;      TRISx= ~LCD_var_TRIS;      // Restaura dicha configuraci�n
     call   retardo_2ms             ;
     ;------------------------      ;
     banksel PORTA   ; banco 0      ;
     ;------------------------      ;
     IF LCD_BUS_PINES == b'00001111';      // Si el bus est� conectado a los 4 pines inferiores de un puerto  
          call retardo_1ms          ;
     ENDIF                          ;
     return                         ;  }

;=====================================================================================================
; LCD_enviaComando
;  - Entrada: W. Contiene los 8 bits del comando a enviar al LCD
;  - Env�a primero el nibble alto del comando y despu�s el bajo
;=====================================================================================================
LCD_enviaComando                    ;  void LCD_enviaComando(byte dato)
     ;------------------------      ;  {
     banksel PORTA   ; banco 0      ;
     ;------------------------      ;
     movwf  LCD_var_dato            ;     LCD_var_dato= dato; 
                                    ;
     swapf  LCD_var_dato,W          ;     // Se env�a el nibble alto del comando que est� en el nibble bajo de W                                    
     call   LCD_envia_4bits_cmd     ;     LCD_envia_4bits_cmd(W); 
     movf   LCD_var_dato,W          ;      
     call   LCD_envia_4bits_cmd     ;     LCD_envia_4bits_cmd(W);    // Se env�a el nibble bajo del comando
     movf   LCD_var_dato,W          ;     
     andlw  b'11111100'             ;     // Comprobamos si el comando tiene mas de 2 bits �tiles (los inferiores)
     xorlw  b'00000000'             ;     if (LCD_var_dato <= 0b0000011)
     btfss  STATUS,Z                ;     { 
     goto   LCD_enviaComando1       ;        // El comando puede ser: b'00000001' � b'0000001*' -> (retardo > 1.64ms)
     call   retardo_2ms             ;        retardo_2ms();
     goto   LCD_enviaComando2       ;     }
LCD_enviaComando1                   ;     else {   
     call   retardo_50us            ;        retardo_50us();    // El comando tiene 3 o m�s bits �tiles -> (retardo > 40us)
LCD_enviaComando2                   ;     }
     return                         ;  }

;=====================================================================================================
; LCD_enviaCaracter
;  - Entrada: W. Contiene los 8 bits del car�cter a enviar al LCD
;  - Env�a primero el nibble alto del car�cter y despu�s el bajo
;=====================================================================================================
LCD_enviaCaracter                   ;  void LCD_enviaCaracter(byte dato)
     ;------------------------      ;  {
     banksel PORTA   ; banco 0      ;
     ;------------------------      ;
     movwf  LCD_var_dato            ;     LCD_var_dato= dato; 
     movf   LCD_var_cursor,W        ;
     andlw  b'00010000'             ;     if (LCD_var_cursor==16)
     btfss  STATUS,Z                ;     {
     goto   LCD_enviaCaracter9      ;         return;           // No caben m�s caracteres en la l�nea
                                    ;     }
     incf   LCD_var_cursor,F        ;     LCD_var_cursor++;
     ;-----------------------       ; 
     movf   LCD_var_dato,W          ;
     call   LCD_codigoCGROM         ;     // Obtiene el c�digo para correcta visualizaci�n.
     movwf  LCD_var_dato            ;     LCD_var_dato= LCD_codigoCGROM(LCD_var_dato);
                                    ;
     swapf  LCD_var_dato,W          ;     // Se env�a el nibble alto del comando que est� en el nibble bajo de W                                    
     call   LCD_envia_4bits_car     ;     LCD_envia_4bits_cmd(W); 
     movf   LCD_var_dato,W          ;      
     call   LCD_envia_4bits_car     ;     LCD_envia_4bits_cmd(W);    // Se env�a el nibble bajo del comando
     call   retardo_50us            ;                                // retardo de 50us en modo car�cter
LCD_enviaCaracter9                  ;
     return                         ;  }

;=====================================================================================================
; LCD_codigoCGROM
;  - Entrada: registro W. Contiene el c�digo ASCII del car�cter
;  - Salida:  registro W. Contiene el c�digo de la tabla CGROM. Hasta el 127 coinciden los c�digos.
;
;  Hay 3 c�digos ASCII por encima del 127 que son aprovechables (motivo de esta rutina):
;        - C�digo ASCII '�':  el c�digo CGROM es b'11101110' que muestra una � min�scula.
;        - C�digo ASCII '�':  el c�digo CGROM es b'11101110'.
;        - C�digo ASCII '�':  el c�digo CGROM es b'11011111'.
;=====================================================================================================
LCD_codigoCGROM                     ;  byte LCD_codigoCGROM(dato)
                                    ;  {
     movwf  LCD_var_dato            ;     LCD_var_dato= dato;   // Salvaguarda el c�digo ASCII del car�cter en la variabl LCD_var_dato
     sublw  '�'                     ;     if ( (dato == '�') || (dato == '�') )
     btfsc  STATUS,Z                ;     {
     goto   LCD_codigoCGROM_1       ;      
     movf   LCD_var_dato,W          ;     
     sublw  '�'                     ; 
     btfss  STATUS,Z                ;         
     goto   LCD_codigoCGROM_2       ;      
LCD_codigoCGROM_1                   ;
     movlw  b'11101110'             ;         W = 0b11101110;    // c�digo CGROM de la "�"
     goto   LCD_codigoCGROM_9       ;        
LCD_codigoCGROM_2                   ;     }
     movf   LCD_var_dato,W          ;     
     sublw  '�'                     ;     else if ( dato == '�') 
     btfss  STATUS,Z                ;     {
     goto   LCD_codigoCGROM_8       ;     
     movlw  b'11011111'             ;         W= 0b11011111;    // c�digo CGROM de la "�"
     goto   LCD_codigoCGROM_9       ;     }
LCD_codigoCGROM_8                   ;     else {
     movf   LCD_var_dato,W          ;         W= dato;          // Se queda como est�
LCD_codigoCGROM_9                   ;     }
                                    ;     return (W);
     return                         ;  }

;=====================================================================================================
; Rutinas
;  - LCD_lineaEnBlanco: Env�a 16 espacios blancos para dejar en blanco la l�nea
;  - LCD_1_blanco:  Env�a 1 espacio  en blanco.
;  - LCD_2_blancos: Env�a 2 espacios en blanco.
;  - LCD_3_blancos: Env�a 3 espacios en blanco.
;  - LCD_4_blancos: Env�a 4 espacios en blanco.
;=====================================================================================================
LCD_lineaEnBlanco
     movlw  b'10000000'
     andwf  LCD_var_cursor,W
     call   LCD_irFilCol               ; Cursor al principio de la l�nea
     movlw  d'16'                      ; Una l�nea tiene 16 caracteres
     call   LCD_enviaBlancos
     movlw  b'10000000'
     andlw  LCD_var_cursor
     call   LCD_irFilCol               ; Cursor al principio de la l�nea
     return
     
LCD_1_blanco
     movlw  d'1'
     goto   LCD_enviaBlancos
LCD_2_blancos
     movlw d'2'
     goto   LCD_enviaBlancos
LCD_3_blancos
     movlw  d'3'
LCD_4_blancos
     movlw  d'4'
LCD_enviaBlancos
     movwf  LCD_var_aux1               ; contador que se decrementa hasta llegar a cero
LCD_enviaBlancos1 
     movlw  ' '                        ; W=' '
     call   LCD_enviaCaracter          ; Env�a un car�cter en blanco al LCD
     decfsz LCD_var_aux1,F             ; haya cargado en (LCD_Auxiliar1).
     goto   LCD_enviaBlancos1
     return



;=====================================================================================================
; LCD_enciende
;        * LCD de 2 l�neas, bus de 4 l�neas y caracteres de 5x7 puntos.
;        * Borra el contenido y sit�a el cursor al principio.
;        * Enciende la pantalla y cursor no visible.
;        * Cursor configurado en modo incremental y sin desplazamiento.
;=====================================================================================================
LCD_enciende
     movlw  b'00101000'             ; comando: b'001,DL,N,F,00' 
     call   LCD_enviaComando        ; DL=0 -> bus de 4bits, N=1 -> 2 l�neas, F=1 -> car�cter de 5x7 puntos
     ;----------------------        ------------------------------------------
     movlw  b'00000001'             
     call   LCD_enviaComando        ; Borra el contenido del LCD y sit�a el cursor al principio de la l�nea superior
     ;----------------------        ------------------------------------------
     movlw  b'00001110'             ; comando: b'00001,D,C,B'
     call   LCD_enviaComando        ; D=1 -> diplay encendido, C=1 -> cursor encendido, B=0 -> no parpadeo
     ;----------------------        ------------------------------------------
     movlw  b'00000110'             ; comando: b'000001,I/D,S'
     call   LCD_enviaComando        ; I/D=1 -> cursor incrementar, S=0 -> No desplazar display
     ;----------------------        ------------------------------------------
     clrf   LCD_var_cursor          ; Cursor en la fila=0 (superior), columna=0 (izquierda)
     return

;=====================================================================================================
; LCD_apaga
;        * Apaga temporalmente el display (no har� falta iniciarlo con posterioridad, solo encenderlo).
;=====================================================================================================
LCD_apaga
     movlw b'00001000'
     call  LCD_enviaComando         ; I/D=1 -> cursor incrementar, S=0 -> No desplazar display
     return

;=====================================================================================================
; Rutinas:
;  - LCD_irLineaSup: Sit�a el cursor al comienzo de la l�nea 1
;  - LCD_irLineaInf: Sit�a el cursor al comienzo de la l�nea 2
;  - LCD_irFilCol: Sit�a el cursor en la l�nea dada por Y y la posici�n dada por X
;        - Entrada (W): b'y000xxxx'. X= nibble inferior de (W), Y=nibble superior de (W)
;        - Ejemplo 1 w=b'10001111'.  X=1111 (posici�n 15),  Y=1 (l�nea 2, inferior)
;        - Ejemplo 2 w=b'10000111'.  X=0111 (posici�n 7),     Y=0 (l�nea 1, superior)
;        - Ejemplo 3 w=b'10000000'.  X=0000 (posici�n 0),     Y=0 (l�nea 1, superior)
;=====================================================================================================
LCD_irLineaSup
     movlw  b'00000000'
     goto   LCD_irFilCol
LCD_irLineaInf
     movlw  b'10000000'
LCD_irFilCol
     movwf  LCD_var_cursor              ; Almacenamos W en LCD_var_cursor
     btfsc  LCD_var_cursor,7            ; �Bit 7 de LCD_var_aux = '0' (l�nea superior)? 
     iorlw  b'01000000'                 ;      No. Es la l�nea inferior. El comando requiere que el bit 6 sea '1'
     iorlw  b'10000000'                 ;      Si. El bit 6 debe valer '0'. El bit '7' del comando debe ser '1'
     call   LCD_enviaComando
     return
     
;=====================================================================================================
; LCD_enviaCadena
;  - Esta rutina envia al LCD una cadena. Recibe en (W) el valor PCL del primer car�cter de la cadena. 
;     El car�cter fin de cadena ser� el d'0'.
;  - Una cadena se describe como una subrutina que retorna el car�cter fijado por el valor PCL del mismo
;    (contenido en W) cada vez que se la llama. 
;   - A continuaci�n se muestra la rutina "cadenas" que contiene diferentes cadenas denotadas por "cadena0",
;    "cadena1", ... Se ha incluido la etiqueta "cadenas_fin" que permite controlar el tama�o total de 
;    todas las cadenas para detectar que no supere el tama�o de una p�gina (256 bytes).
;
;        cadenas
;           movwf PCL
;        cadena0
;           DT       ".. .. ..", 0
;        cadena1
;           DT       ".. .. ..", 0
;        ...
;        ...
;        cadenas_fin
;
;  - La llamada a la subrutina LCD_enviaCadena para enviar la "cadena1" ser�a:
;           movlw cadena1
;           call  LCD_enviaCadena
;
;  - Las cadenas de caracteres se ubicar� al principio del programa justo despu�s de la interrupci�n
;    para que no haya saltos de p�gina (incremento del PCH) justo en mitad de una cadena. 
;
;  - Las siguientes variables auxiliares ser�n:
;        * LCD_var_aux1: valor PCL del car�cter que se quiere leer de la cadena seleccionada 
;
;  - Esta rutina se ensamblar� si existen las etiquetas "cadenas" y "cadenas_fin" en el fichero
;    principal. Por este motivo se utilizan las directivas del ensamblador IFDEF e IFNDEF
;
;=====================================================================================================
IFDEF cadenas_fin    ; Se ensamblar� este c�digo si existe esta etiqueta en el programa principal


LCD_enviaCadena
   movwf  LCD_var_aux1            ; PCL: posici�n absoluta de memoria del primer car�cter de la cadena
LCD_enviaCadena1
   call   cadenas                 ; Retorna en (W) el c�digo ASCII del car�cter apuntado por el �ndice LCD_var_aux1
   andlw  0x0ff                   ; Comprueba si el car�cter a enviar es el 0 (fin de la cadena)
   btfsc  STATUS,Z                ; �Z=0 (el car�cter a enviar no es 0)?
   goto   LCD_enviaCadena9        ;     No. Salir. El car�cter es 0 (fin de cadena).
   call   LCD_enviaCaracter       ;    Si. Env�a el car�cter almacenado en (W) al LCD
   incf   LCD_var_aux1,F          ; Incrementa el �ndice que recorre la cadena
   movf   LCD_var_aux1,W 
   goto   LCD_enviaCadena1        ; Vuelve a iterar para enviar un nuevo car�cter
LCD_enviaCadena9
   return

   
;---------------------------------------------------
IF ( (cadenas & 0x0FF) > (cadenas_fin & 0x0FF) )
   MESSG   "Aviso del usuario: La tabla de cadenas cruza el l�mite de una p�gina. Est� contemplado."
ENDIF
IF (  (cadenas_fin - cadenas) > 0x0100 )
   ERROR   "Error del usuario: La tabla de cadenas tiene un tama�o superior a una p�gina de 256 bytes."
ENDIF

ENDIF    ; cadenas_fin



ENDIF    ; LCD_LM016_asm
