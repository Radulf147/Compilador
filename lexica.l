%{
#include "y.tab.h"
%}

DIGITO      [0-9]
LETRA       [a-zA-Z_]
IDENT       {LETRA}({LETRA}|{DIGITO})*
NUM_INT     {DIGITO}+
NUM_DEC     {DIGITO}+"."{DIGITO}+

%%

"OCTETO"           { return OCTETO; }
"OCTETO_SSINAL"    { return OCTETO_SSINAL; }
"CURTO"            { return CURTO; }
"CURTO_SSINAL"     { return CURTO_SSINAL; }
"INTEIRO"          { return INTEIRO; }
"INT_SSINAL"       { return INT_SSINAL; }
"LONGO"            { return LONGO; }
"LONGO_SSINAL"     { return LONGO_SSINAL; }
"FLUTUANTE"        { return FLUTUANTE; }
"DOBRO"            { return DOBRO; }
"DECIMAIS"         { return DECIMAIS; }
"CARACTERE"        { return CARACTERE; }
"CARACTERES"       { return CARACTERES; }
"BOOLEANO"         { return BOOLEANO; }

"se"               { return SE; }
"senao"            { return SENAO; }
"enquanto"         { return ENQUANTO; }
"para"             { return PARA; }
"retorna"          { return RETORNA; }

// Comentários
"#".*                     { /* ignora comentário de linha */ }
"//".*                    { /* ignora comentário de linha */ }
/\*([^*]|\*+[^*/])*\*/     { /* ignora comentário de bloco */ }

{NUM_INT}          { yylval.intval = atoi(yytext); return NUM_INT; }
{NUM_DEC}          { yylval.fval = atof(yytext); return NUM_DEC; }
\"([^\\\"]|\\.)*\" { yylval.sval = strdup(yytext); return STRING; }
{IDENT}            { yylval.sval = strdup(yytext); return IDENT; }

"=="               { return IGUAL; }
"!="               { return DIFERENTE; }
"<="               { return MENOR_IGUAL; }
">="               { return MAIOR_IGUAL; }
"&&"               { return E_LOGICO; }
"||"               { return OU_LOGICO; }
"!"                { return NAO_LOGICO; }
"="                { return ATRIB; }
"<"                { return MENOR; }
">"                { return MAIOR; }
"+"                { return MAIS; }
"-"                { return MENOS; }
"*"                { return MULT; }
"/"                { return DIV; }
"%"                { return MOD; }
";"                { return PONTO_VIRG; }
","                { return VIRG; }
"("                { return ABRE_P; }
")"                { return FECHA_P; }
"{"                { return ABRE_CH; }
"}"                { return FECHA_CH; }

[ \t\n\r]+         { /* ignora espaços em branco */ }
.                  { return yytext[0]; }

%%

int yywrap() { return 1; }

