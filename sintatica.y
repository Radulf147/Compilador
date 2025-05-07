%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
%}

%token INT FLOAT CHAR BOOL
%token INT_LITERAL FLOAT_LITERAL CHAR_LITERAL BOOL_LITERAL
%token ID
%token PLUS MINUS TIMES DIVIDE ASSIGN SEMI LPAREN RPAREN LBRACE RBRACE
%token LT LE GT GE EQ NEQ
%token AND OR NOT

%%

programa:
    declaracoes
    ;

declaracoes:
    declaracoes declaracao
    | declaracao
    ;

declaracao:
    tipo ID SEMI { /* inserir variável na tabela */ }
    ;

tipo:
    INT { $$ = "int"; }
    | FLOAT { $$ = "float"; }
    | CHAR { $$ = "char"; }
    | BOOL { $$ = "bool"; }
    ;

exp:
    exp PLUS exp { /* ação semântica + */ }
    | exp MINUS exp { /* ação semântica - */ }
    | exp TIMES exp { /* ação semântica * */ }
    | exp DIVIDE exp { /* ação semântica / */ }
    | exp LT exp { /* ação semântica < */ }
    | exp LE exp { /* ação semântica <= */ }
    | exp GT exp { /* ação semântica > */ }
    | exp GE exp { /* ação semântica >= */ }
    | exp EQ exp { /* ação semântica == */ }
    | exp NEQ exp { /* ação semântica != */ }
    | exp AND exp { /* ação semântica && */ }
    | exp OR exp { /* ação semântica || */ }
    | NOT exp { /* ação semântica ! */ }
    | LPAREN exp RPAREN { $$ = $2; }
    | INT_LITERAL { $$ = $1; }
    | FLOAT_LITERAL { $$ = $1; }
    | CHAR_LITERAL { $$ = $1; }
    | BOOL_LITERAL { $$ = $1; }
    | ID { /* busca na tabela */ }
    ;

factor:
    LPAREN tipo RPAREN factor { /* cast explícito */ }
    | exp
    ;

%%

int main(void) {
    yyparse();
    return 0;
}

int yyerror(char *s) {
    fprintf(stderr, "Erro: %s\n", s);
    return 0;
}
