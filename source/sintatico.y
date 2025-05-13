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

char* obter_tipo(char *nome) {
    for (int i = 0; i < contador; i++) {
        if (strcmp(tabela[i].nome, nome) == 0) {
            return tabela[i].tipo;
        }
    }
    fprintf(stderr, "Erro: Tipo da variável '%s' não encontrado.\n", nome);
    exit(1);
}
%}

%union {
    int ival;
    float fval;
    char *str;
    struct {
        int temp_id;
        char tipo[10];
    } expr_attr;
}

%token <ival> NUM
%token <fval> FNUM
%token <str> ID
%token <str> TIPO
%token ATRIB
%token MAIS MENOS VEZES DIV
%token ABRE_P FECHA_P

%left MAIS MENOS
%left VEZES DIV

%type <expr_attr> expr

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
        char* tipo_var = obter_tipo($1);
        if (strcmp(tipo_var, $3.tipo) != 0) {
            printf("// Aviso: conversão de tipo de %s para %s\n", $3.tipo, tipo_var);
        }
        printf("T%d = T%d;\n", endereco, $3.temp_id);
    }
;

expr:
    expr MAIS expr {
        int res = temp_count++;
        if (strcmp($1.tipo, "float") == 0 || strcmp($3.tipo, "float") == 0) {
            printf("float T%d;\n", res);
            strcpy($$.tipo, "float");
        } else {
            printf("int T%d;\n", res);
            strcpy($$.tipo, "int");
        }
        printf("T%d = T%d + T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
    }
  | expr MENOS expr {
        int res = temp_count++;
        if (strcmp($1.tipo, "float") == 0 || strcmp($3.tipo, "float") == 0) {
            printf("float T%d;\n", res);
            strcpy($$.tipo, "float");
        } else {
            printf("int T%d;\n", res);
            strcpy($$.tipo, "int");
        }
        printf("T%d = T%d - T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
    }
  | expr VEZES expr {
        int res = temp_count++;
        if (strcmp($1.tipo, "float") == 0 || strcmp($3.tipo, "float") == 0) {
            printf("float T%d;\n", res);
            strcpy($$.tipo, "float");
        } else {
            printf("int T%d;\n", res);
            strcpy($$.tipo, "int");
        }
        printf("T%d = T%d * T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
    }
  | expr DIV expr {
        int res = temp_count++;
        if (strcmp($1.tipo, "float") == 0 || strcmp($3.tipo, "float") == 0) {
            printf("float T%d;\n", res);
            strcpy($$.tipo, "float");
        } else {
            printf("int T%d;\n", res);
            strcpy($$.tipo, "int");
        }
        printf("T%d = T%d / T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
    }
  | ABRE_P expr FECHA_P {
        $$.temp_id = $2.temp_id;
        strcpy($$.tipo, $2.tipo);
    }
  | NUM {
        int res = temp_count++;
        printf("int T%d;\n", res);
        printf("T%d = %d;\n", res, $1);
        $$.temp_id = res;
        strcpy($$.tipo, "int");
    }
  | FNUM {
        int res = temp_count++;
        printf("float T%d;\n", res);
        printf("T%d = %.2f;\n", res, $1);
        $$.temp_id = res;
        strcpy($$.tipo, "float");
    }
  | ID {
        int endereco = obter_endereco($1);
        $$.temp_id = endereco;
        strcpy($$.tipo, obter_tipo($1));
    }
;

%%

int main() {
    yyparse();
    return 0;
}
