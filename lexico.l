%{
#include "sintatico.tab.h"
#include <string.h>
#include <stdlib.h>
%}

%%

[0-9]+              { yylval.ival = atoi(yytext); return NUM; }
[A-Za-z_][A-Za-z0-9_]* { yylval.str = strdup(yytext); return ID; }

[ \t\r\n]+          ;  // ignora espaços e quebras de linha
"="                 { return ATRIB; }
"+"                 { return MAIS; }
"-"                 { return MENOS; }
"*"                 { return VEZES; }
"/"                 { return DIV; }
"("                 { return ABRE_P; }
")"                 { return FECHA_P; }
";"                 { return ';'; }  // usa o caractere literal, já que não há token PONTOVIRG

.                   { printf("Caractere inválido: %s\n", yytext); return 0; }

%%

int yywrap() { return 1; }
