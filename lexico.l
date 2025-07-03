%{
#include <string>
#include "y.tab.h"
%}

ESPACO      [ \t]
DIGITO      [0-9]
LETRA       [a-zA-Z_]
DELIM       {ESPACO}+
NUM         {DIGITO}+
REAL        {NUM}+("."{NUM}+)?
CHAR        \'({LETRA}|{NUM})\'
CADEIA_CHAR \"[^\"]*\"
ID          {LETRA}({LETRA}|{NUM})*
BOOL        ("true"|"false")
RELACIONAIS (">"|"<"|"<="|">="|"=="|"!=")
OU          ("||")
E           ("&&")
NEG         ("!")
CAST        ("(float)"|"(int)"|"(bool)"|"(char)")

%%

"\n"            {}
{DELIM}         {}
"//".* { /* Comentário de linha, não faz nada */ }
"if"            {return KWD_IF;}
"then"          {return KWD_THEN;}
"else"          {return KWD_ELSE;}
"while"         {return KWD_WHILE;}
"do"            {return KWD_DO;}
"for"           {return KWD_FOR;}
"break"         {return KWD_BREAK;}
"continue"      {return KWD_CONTINUE;}
"switch"        {return KWD_SWITCH;}
"case"          {return KWD_CASE;}
"default"       {return KWD_DEFAULT;}
"input"         {return KWD_INPUT;}
"output"        {return KWD_OUTPUT;}
"def"           {return KWD_DEF;}
"main"          {return KWD_MAIN;}
"var"           {return KWD_VAR;}
"+="            {return KWD_PLUS_EQ;}
"-="            {return KWD_MINUS_EQ;}
"*="            {return KWD_MULT_EQ;}
"/="            {return KWD_DIV_EQ;}
"++"            {return KWD_INC;}
"--"            {return KWD_DEC;}
[(){}\[\]:;,]   { return *yytext; }
[+\-*/]         { return *yytext; }
"="             { return '='; }
"strcpy"        {yylval.label = yytext; return KWD_CPY;}
"strcat"        {yylval.label = yytext; return KWD_CAT;}

"%d"            { yylval.label = yytext; yylval.tipo = "int";    return KWD_TIPO_INPUT; }
"%f"            { yylval.label = yytext; yylval.tipo = "float";  return KWD_TIPO_INPUT; }
"%s"            { yylval.label = yytext; yylval.tipo = "string"; return KWD_TIPO_INPUT; }
"%c"            { yylval.label = yytext; yylval.tipo = "char";   return KWD_TIPO_INPUT; }

{CAST}          { yylval.label = yytext; if(string(yylval.label)=="(float)") yylval.tipo="float"; else if(string(yylval.label)=="(int)") yylval.tipo="int"; else if(string(yylval.label)=="(char)") yylval.tipo="char"; else yylval.tipo="int"; return KWD_CAST;}
{BOOL}          { yylval.label = yytext; return KWD_BOOL;}
{NUM}           { yylval.label = yytext; return KWD_NUM;}
{ID}            { yylval.label = yytext; return KWD_ID;}
{REAL}          { yylval.label = yytext; return KWD_FLOAT;}
{OU}            { yylval.label = yytext; return KWD_OU;}
{E}             { yylval.label = yytext; return KWD_E;}
{NEG}           { yylval.label = yytext; return KWD_NEG;}
{RELACIONAIS}   { yylval.label = yytext; return KWD_RELACIONAL;}
{CHAR}          { yylval.label = yytext; return KWD_CHAR;}
{CADEIA_CHAR}   { yylval.label = unescape_string(yytext); return KWD_CADEIA_CHAR;}
.               { /* Ignora outros */ }
%%