%{
#include "sintatico.tab.h"
#include <stdlib.h> // Para atoi
%}

%%

[0-9]+        { yylval.ival = atoi(yytext); return NUM; }
[ \t\r\n]+    ;  // ignora espaços e quebras de linha
"+"           { return MAIS; }
";"           { return PONTOVIRG; }

.             { printf("Caractere inválido: %s\n", yytext); return 0; }

%%
int yywrap() {
    return 1;
}
