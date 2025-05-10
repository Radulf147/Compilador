%{
#include <stdio.h>
#include <stdlib.h>

int tempVar = 1;

void gera(char* instr, char* a, char* b, char* result) {
    printf("%s = %s %s %s;\n", result, a, instr, b);
}

void geraAtrib(char* a, char* b) {
    printf("%s = %s;\n", a, b);
}

char* novaTemp() {
    char* nome = malloc(10);
    sprintf(nome, "T%d", tempVar++);
    return nome;
}
%}

%union {
    int ival;
    char* str;
}

%token <ival> NUM
%token MAIS
%token PONTOVIRG

%left MAIS

%type <str> expressao

%%

programa:
    expressao PONTOVIRG { printf("// Fim do programa\n"); }
;

expressao:
    NUM                     {
                              char* temp = novaTemp();
                              printf("%s = %d;\n", temp, $1);
                              $$ = temp;
                            }
  | expressao MAIS expressao {
                              char* temp = novaTemp();
                              gera("+", $1, $3, temp);
                              $$ = temp;
                            }
;

%%
int yylex(void);
int yyerror(char* s);

int main() {
    return yyparse();
}

int yyerror(char* s) {
    fprintf(stderr, "Erro: %s\n", s);
    return 1;
}
