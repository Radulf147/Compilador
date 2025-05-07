%{
#include "sintatica.tab.h"
#include <string.h>
%}

%%

"inteiro"      { yylval.str = strdup("inteiro"); return TIPO_INTEIRO; }
"float"        { yylval.str = strdup("float"); return TIPO_FLOAT; }
"char"         { yylval.str = strdup("char"); return TIPO_CHAR; }
"booleano"     { yylval.str = strdup("boolean"); return TIPO_BOOLEAN; }

"principal"    { return PRINCIPAL; }
"retorne"      { return RETORNE; }
"se"           { return SE; }
"senao"        { return SENAO; }
"enquanto"     { return ENQUANTO; }

"&&"           { return E_LOGICO; }
"||"           { return OU_LOGICO; }
"!"            { return NAO_LOGICO; }

"=="           { return IGUAL; }
"!="           { return DIFERENTE; }
"<"            { return MENOR; }
">"            { return MAIOR; }
"<="           { return MENORIGUAL; }
">="           { return MAIORIGUAL; }

"="            { return ATRIBUICAO; }
"+"            { return MAIS; }
"-"            { return MENOS; }
"*"            { return VEZES; }
"/"            { return DIV; }

"("            { return ABRE_PARENTESES; }
")"            { return FECHA_PARENTESES; }
"{"            { return ABRE_CHAVES; }
"}"            { return FECHA_CHAVES; }
";"            { return PONTOVIRGULA; }
","            { return VIRGULA; }

[0-9]+"."[0-9]+ { yylval.flutuante = atof(yytext); return NUM_FLOAT; }
[0-9]+          { yylval.inteiro = atoi(yytext); return NUM_INT; }

\'[^\']\'       { yylval.caractere = yytext[1]; return CARACTERE; }

[a-zA-Z_][a-zA-Z0-9_]* {
    yylval.str = strdup(yytext);
    return IDENTIFICADOR;
}

[ \t\n]+        { /* Ignora espaços e quebras de linha */ }

.               { return ERRO; }

%%
int yywrap(void) { return 1; }
