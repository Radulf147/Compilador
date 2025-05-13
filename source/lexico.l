%{
#include "sintatico.tab.h"
#include <string.h>
#include <stdlib.h> // necessário para atof
%}

DIGITO   [0-9]
LETRA    [a-zA-Z_]
ESPACO   [ \t\n\r]

%%

int         { yylval.str = strdup("int"); return TIPO; }
float       { yylval.str = strdup("float"); return TIPO; }

{LETRA}({LETRA}|{DIGITO})*    { yylval.str = strdup(yytext); return ID; }
{DIGITO}+                     { yylval.ival = atoi(yytext); return NUM; }
{DIGITO}+"."{DIGITO}+         { yylval.fval = atof(yytext); return FNUM; }  // <-- Adicionado

"+"         { return MAIS; }
"-"         { return MENOS; }
"*"         { return VEZES; }
"/"         { return DIV; }
"="         { return ATRIB; }
"("         { return ABRE_P; }
")"         { return FECHA_P; }
";"         { return ';'; }

{ESPACO}    ; // ignora espaços

.           { printf("Caractere inesperado: %s\n", yytext); return -1; }

%%

int yywrap(void) {
    return 1;
}
