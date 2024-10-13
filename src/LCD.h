; * ********************************************************************************* *
; * ************                   Fichero: LCD_LM016.h                  ************ *
; * ********************************************************************************* *
IFNDEF     LCD_LM016_h          ;  ENDIF al final del fichero
#define    LCD_LM016_h          ;  Si se llama dos veces al fichero, la 2� no se incluye
;
;---------------------
; Listado de rutinas:
;        - LCD_ini
;        - LCD_enviaCaracter
;        - LCD_irLineaInf     ; El cursor lo pone al principio
;        - LCD_irLineaSup     ; El cursor lo pone al principio
;        - LCD_lineaEnBlanco  ; Borra la l�nea y sit�a el curso al principio de ella
;        - LCD_1_blanco
;        - LCD_2_blancos
;        - LCD_3_blancos
;        - LCD_4_blancos
;          ----------------
;        - LCD_irFilCol
;        - LCD_enciende
;        - LCD_apaga
;        - LCD_enviaComando
     
;
; La librer�a est� preparada para que los 4 pines de datos (salidas para el PIC) puedan
; ser compartidos por otro perif�rico pero como entradas (ej.: filas de un teclado).
;
; Librer�a de rutinas para la gesti�n de un LCD de 2 l�neas x 16 caracteres gestionado 
; con un bus de datos 4 l�neas para optimizar el n�mero de pines empleados.
;
; El bus de datos del LCD (configurado para 4 bits) se conectar� bien a las 4 l�neas 
; inferiores de un puerto del PIC (en este caso la constante LCD_BUS_PINES=b'00001111')
; o bien a los 4 bits superiores del puerto (en este caso la constante 
; LCD_BUS_PINES=b'11110000'). Estos pines se ponen en alta impedancia cuando el pin E del
; LCD se pone a '0'. Por tanto, pueden conectarse a otros dispositivos y tener m�s
; de una funci�n ya que el pin E solo se pone a '1' cuando el pic se dirige al LCD.
;     Los pines E y RS pueden asignarse a cualquier otro pin libre 
; del mismo puerto o de cualquier otro puerto del PIC. Las posibilidades de conexi�n del
; 16F84 son m�ltiples. En el caso de un pic con m�s de 2 puertos aumentan aun m�s. 
; En esta librer�a se pueden elegir entre 5 opciones cambiando el valor de la constante 
; LCD_OPCION para un pic de dos puertos (PORTA y PORTB).
;     
; Todos los pines del PIC que van a l LCD se configurar�n de salida. 
;  - El �nico pin dedicado es el pin E (su direcci�n ser� siempre de salida).
;  - El resto de pines (RS y <DB7:DB4>) pueden tener otra funci�n alternativa bien
;      como entradas bien como salidas.        
;



ENDIF    ; LCD_LM016_h
