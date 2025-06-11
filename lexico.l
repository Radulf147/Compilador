%{
#include "sintatico.tab.h"
#include <string.h>
#include <stdlib.h>
%}

%option noyywrap

%%

^"#include"[ \t]*<[^>]+> { yylval.str = strdup(yytext); return INCLUDE_DIRECTIVE; }
^"#include"[ \t]*\"[^\"]+\" { yylval.str = strdup(yytext); return INCLUDE_DIRECTIVE; }

"main"      { return KWD_MAIN; }
"return"    { return KWD_RETURN; }
"if"        { return KWD_IF; }
"else"      { return KWD_ELSE; }
"printf"    { return KWD_PRINTF; }
"scanf"     { return KWD_SCANF; }
"while"     { return KWD_WHILE; }
"do"        { return KWD_DO; }
"string"    { return KWD_STRING; }
"switch"    { return KWD_SWITCH; }   
"case"      { return KWD_CASE; }    
"default"   { return KWD_DEFAULT; }  
"continue"  { return KWD_CONTINUE; } 

"int"       { yylval.str = strdup(yytext); return TIPO; }
"float"     { yylval.str = strdup(yytext); return TIPO; }
"char"      { yylval.str = strdup(yytext); return TIPO; }
"bool"      { yylval.str = strdup(yytext); return TIPO; }

"true"      { yylval.ival = 1; return BOOLLIT; }
"false"     { yylval.ival = 0; return BOOLLIT; }

\"(\\.|[^"\\])*\" {
    yylval.str = (char*) malloc(yyleng - 1);
    strncpy(yylval.str, yytext + 1, yyleng - 2);
    yylval.str[yyleng - 2] = '\0';
    return STRING_LITERAL;
}

"&"         { return AMPERSAND; }
"="         { return ATRIB; }
"=="        { return IGUAL; }
"!="        { return DIFERENTE; }
"<="        { return MENORIGUAL; }
">="        { return MAIORIGUAL; }
"<"         { return MENOR; }
">"         { return MAIOR; }
"&&"        { return E; }
"||"        { return OU; }
"!"         { return NEG; }
"+"         { return MAIS; }
"-"         { return MENOS; }
"*"         { return VEZES; }
"/"         { return DIV; }

"("         { return ABRE_P; }
")"         { return FECHA_P; }
"{"         { return ABRE_CHAVE; }
"}"         { return FECHA_CHAVE; }
"["         { return ABRE_COL; }    
"]"         { return FECHA_COL; }   
";"         { return ';'; }
":"         { return ':'; }        
","         { return ','; }

[0-9]+\.[0-9]+  { yylval.fval = atof(yytext); return FNUM; }
[0-9]+          { yylval.ival = atoi(yytext); return NUM; }
\'[^\']\'       { yylval.str = strdup(yytext); return CARACTERE; }


[a-zA-Z_][a-zA-Z0-9_]* {
    yylval.str = strdup(yytext);
    return ID;
}


[ \t\n]+

. { fprintf(stderr, "LEXER WARN: Caractere não reconhecido no lexico: '%s' (ASCII: %d)\n", yytext, (int)yytext[0]); }

%%