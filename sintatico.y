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
    char tipo[10];
} Simbolo;

Simbolo tabela[100];
int contador = 0;
int temp_count = 1;

int adicionar_simbolo(char *nome, char *tipo) {
    for (int i = 0; i < contador; i++) {
        if (strcmp(tabela[i].nome, nome) == 0) {
            return tabela[i].endereco;
        }
    }
    strcpy(tabela[contador].nome, nome);
    tabela[contador].endereco = temp_count++;
    strcpy(tabela[contador].tipo, tipo);
    return tabela[contador++].endereco;
}

int obter_endereco(char *nome) {
    for (int i = 0; i < contador; i++) {
        if (strcmp(tabela[i].nome, nome) == 0) {
            return tabela[i].endereco;
        }
    }
    fprintf(stderr, "Erro: Variável '%s' não declarada.\n", nome);
    exit(1);
}
%}

%union {
    int ival;
    char *str;
}

%token <ival> NUM
%token <str> ID
%token <str> TIPO
%token ATRIB
%token MAIS MENOS VEZES DIV
%token ABRE_P FECHA_P

%left MAIS MENOS
%left VEZES DIV

%type <ival> expr

%%

programa: lista_comandos
;

lista_comandos:
    lista_comandos comando
  | comando
;

comando:
    decl
  | atribuicao
;

decl:
    TIPO ID ';' {
        int endereco = adicionar_simbolo($2, $1);
        printf("// Declarando variável %s do tipo %s em T%d\n", $2, $1, endereco);
        printf("%s T%d;\n", $1, endereco);
    }
;

atribuicao:
    ID ATRIB expr ';' {
        int endereco = obter_endereco($1);
        printf("T%d = T%d;\n", endereco, $3);
    }
;

expr:
    expr MAIS expr {
        int res = temp_count++;
        printf("int T%d;\n", res);
        printf("T%d = T%d + T%d;\n", res, $1, $3);
        $$ = res;
    }
  | expr MENOS expr {
        int res = temp_count++;
        printf("int T%d;\n", res);
        printf("T%d = T%d - T%d;\n", res, $1, $3);
        $$ = res;
    }
  | expr VEZES expr {
        int res = temp_count++;
        printf("int T%d;\n", res);
        printf("T%d = T%d * T%d;\n", res, $1, $3);
        $$ = res;
    }
  | expr DIV expr {
        int res = temp_count++;
        printf("int T%d;\n", res);
        printf("T%d = T%d / T%d;\n", res, $1, $3);
        $$ = res;
    }
  | ABRE_P expr FECHA_P {
        $$ = $2;
    }
  | NUM {
        int res = temp_count++;
        printf("int T%d;\n", res);
        printf("T%d = %d;\n", res, $1);
        $$ = res;
    }
  | ID {
        int endereco = obter_endereco($1);
        $$ = endereco;
    }
;

%%

int main() {
    yyparse();
    return 0;
}
