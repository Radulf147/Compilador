%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
void yyerror(const char *s) {
    fprintf(stderr, "Erro: %s\n", s);
}

typedef struct Simbolo {
    char nome[50];
    int endereco;
} Simbolo;

Simbolo tabela[100];
int contador = 0;
int temp_count = 1;

int adicionar_simbolo(char *nome) {
    for (int i = 0; i < contador; i++) {
        if (strcmp(tabela[i].nome, nome) == 0) {
            return tabela[i].endereco;
        }
    }
    strcpy(tabela[contador].nome, nome);
    tabela[contador].endereco = temp_count++;
    return tabela[contador++].endereco;
}
%}

%union {
    int ival;
    char *str;
}

%token <ival> NUM
%token <str> ID
%token ATRIB
%token MAIS MENOS VEZES DIV
%token ABRE_P FECHA_P
%token TIPO

%left MAIS MENOS
%left VEZES DIV

%type <ival> expr

%%

programa: decl atribuicao
;

decl: TIPO ID ';' {
    int endereco = adicionar_simbolo($2);
    printf("// Declarando variável %s em T%d\n", $2, endereco);
    printf("int T%d;\n", endereco);
}
;

atribuicao: ID ATRIB expr ';' {
    int endereco = adicionar_simbolo($1);
    printf("T%d = T%d;\n", endereco, $3);
}
;

expr: expr MAIS expr {
    int temp = temp_count++;
    printf("int T%d;\n", temp);
    printf("T%d = T%d + T%d;\n", temp, $1, $3);
    $$ = temp;
}
| expr VEZES expr {
    int temp = temp_count++;
    printf("int T%d;\n", temp);
    printf("T%d = T%d * T%d;\n", temp, $1, $3);
    $$ = temp;
}
| NUM {
    int temp = temp_count++;
    printf("int T%d;\n", temp);
    printf("T%d = %d;\n", temp, $1);
    $$ = temp;
}
| ID {
    $$ = adicionar_simbolo($1);
}
;

%%

int main() {
    yyparse();
    return 0;
}
