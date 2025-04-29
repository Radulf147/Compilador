%{
#include "y.tab.h"
%}

DIGITO      [0-9]
LETRA       [a-zA-Z_]
IDENT       {LETRA}({LETRA}|{DIGITO})*
NUM_INT     {DIGITO}+
NUM_DEC     {DIGITO}+"."{DIGITO}+

%%

// Tipos
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

// Palavras-chave
"se"               { return SE; }
"senao"            { return SENAO; }
"enquanto"         { return ENQUANTO; }
"para"             { return PARA; }
"retorna"          { return RETORNA; }

// Booleanos
"verdadeiro"       { return VERDADEIRO; }
"falso"            { return FALSO; }

// Conversão (opcional, se for usar)
"converte_para"    { return CONVERTE_PARA; }
"como"             { return COMO; }

// Comentários
"#".*                     { /* ignora comentário de linha */ }
"//".*                    { /* ignora comentário de linha */ }
/\*([^*]|\*+[^*/])*\*/     { /* ignora comentário de bloco */ }

// Literais e identificadores
{NUM_INT}          { yylval.intval = atoi(yytext); return NUM_INT; }
{NUM_DEC}          { yylval.fval = atof(yytext); return NUM_DEC; }
\"([^\\\"]|\\.)*\" { yylval.sval = strdup(yytext); return STRING; }
{IDENT}            { yylval.sval = strdup(yytext); return IDENT; }

// Operadores relacionais
"=="               { return IGUAL; }
"!="               { return DIFERENTE; }
"<="               { return MENOR_IGUAL; }
">="               { return MAIOR_IGUAL; }
"<"                { return MENOR; }
">"                { return MAIOR; }

// Operadores lógicos
"&&"               { return E_LOGICO; }
"||"               { return OU_LOGICO; }
"!"                { return NAO_LOGICO; }

// Operadores aritméticos e outros
"="                { return ATRIB; }
"+"                { return MAIS; }
"-"                { return MENOS; }
"*"                { return MULT; }
"/"                { return DIV; }
"%"                { return MOD; }

// Pontuação
";"                { return PONTO_VIRG; }
","                { return VIRG; }
"("                { return ABRE_P; }
")"                { return FECHA_P; }
"{"                { return ABRE_CH; }
"}"                { return FECHA_CH; }

// Espaços
[ \t\n\r]+         { /* ignora espaços em branco */ }

// Qualquer outro caractere
.                  { return yytext[0]; }

%%

int yywrap() { return 1; }


