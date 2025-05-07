%{
#include "sintatica.tab.h"
%}

%%

"int"           { return INT; }
"float"         { return FLOAT; }
"char"          { return CHAR; }
"bool"          { return BOOL; }
"true"          { yylval.ival = 1; return BOOL_LITERAL; }
"false"         { yylval.ival = 0; return BOOL_LITERAL; }
\'[^\']\'       { yylval.cval = yytext[1]; return CHAR_LITERAL; }
[0-9]+"."[0-9]* { yylval.fval = atof(yytext); return FLOAT_LITERAL; }

"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return TIMES; }
"/"             { return DIVIDE; }
"="             { return ASSIGN; }
";"             { return SEMI; }
"("             { return LPAREN; }
")"             { return RPAREN; }
"{"             { return LBRACE; }
"}"             { return RBRACE; }

"<"             { return LT; }
"<="            { return LE; }
">"             { return GT; }
">="            { return GE; }
"=="            { return EQ; }
"!="            { return NEQ; }

"&&"            { return AND; }
"||"            { return OR; }
"!"             { return NOT; }

[0-9]+          { yylval.ival = atoi(yytext); return INT_LITERAL; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.sval = strdup(yytext); return ID; }

[ \t\n]+        ;
.               { printf("Caractere inválido: %s\n", yytext); }

%%

int yywrap(void) { return 1; }
