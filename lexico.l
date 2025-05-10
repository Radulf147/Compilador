%{
using System;
%}

DIGITO [0-9]+

%%

{DIGITO}     { yylval = int.Parse(yytext); return NUMERO; }
"+"          { return SOMA; }
[ \t\n]+     { /* ignora espaços e quebras de linha */ }

.            { Console.WriteLine($"Caractere inválido: {yytext}"); }

%%
