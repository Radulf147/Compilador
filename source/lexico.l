%{
#include "sintatico.tab.h"
#include <string.h>
%}

%%

"int"     { yylval.str = "int"; return TIPO; }
"float"   { yylval.str = "float"; return TIPO; }
"char"    { yylval.str = "char"; return TIPO; }
"bool"    { yylval.str = "bool"; return TIPO; }

"true"    { yylval.ival = 1; return BOOLLIT; }
"false"   { yylval.ival = 0; return BOOLLIT; }

"&&"      { return AND; }
"||"      { return OR; }
"!"       { return NOT; }

"<"      { return MENOR; }
"<="     { return MENORIG; }
">"      { return MAIOR; }
">="     { return MAIORIG; }
"=="     { return IGUAL; }
"!="     { return DIF; }

"="       { return ATRIB; }
"+"       { return MAIS; }
"-"       { return MENOS; }
"*"       { return VEZES; }
"/"       { return DIV; }
"("       { return ABRE_P; }
")"       { return FECHA_P; }
";"       { return ';'; }

[0-9]+"."[0-9]+   { yylval.fval = atof(yytext); return FNUM; }
[0-9]+            { yylval.ival = atoi(yytext); return NUM; }
\'[^\']\'         { yylval.str = strdup(yytext); return CARACTERE; }

[a-zA-Z_][a-zA-Z0-9_]*  { yylval.str = strdup(yytext); return ID; }

[ \t\n]  // Ignora espaços e quebras de linha

.        { printf("Caractere não reconhecido: %s\n", yytext); return 0; }

%%

int yywrap(void) {
    return 1;
}
