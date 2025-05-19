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
    fprintf(stderr, "Erro: Tipo da variavel '%s' nao encontrado.\n", nome);
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
        char nome[50];
    } expr_attr;
}
%token NEG
%token <ival> NUM
%token <fval> FNUM
%token <str> ID
%token <str> TIPO
%token <str> CARACTERE
%token ATRIB
%token MAIS MENOS VEZES DIV
%token ABRE_P FECHA_P
%token IGUAL DIFERENTE MENOR MAIOR MENORIGUAL MAIORIGUAL
%token E OU
%token <ival> BOOLLIT

%right NEG
%left OU
%left E
%left IGUAL DIFERENTE
%left MENOR MAIOR MENORIGUAL MAIORIGUAL
%left MAIS MENOS
%left VEZES DIV

%type <expr_attr> expr fator

%%

programa: lista_comandos ;

lista_comandos:
    lista_comandos comando
  | comando
;

comando:
    decl
  | atribuicao
  | expr ';' {
        printf("// Resultado em T%d do tipo %s\n", $1.temp_id, $1.tipo);
    }
;

decl:
    TIPO ID ';' {
        int endereco = adicionar_simbolo($2, $1);
        printf("%s T%d;\n", $1, endereco);
    }
;

atribuicao:
    ID ATRIB expr ';' {
        int endereco = obter_endereco($1);
        char* tipo_var = obter_tipo($1);
        if (strcmp(tipo_var, $3.tipo) != 0) {
            printf("// Aviso: conversao de tipo de %s para %s\n", $3.tipo, tipo_var);
        }
        printf("T%d = T%d;\n", endereco, $3.temp_id);
        printf("%s = T%d;\n", $1, endereco);
    }
;

expr:
    expr MAIS expr {
        int res = temp_count++;
        char tipo[10];
        if (strcmp($1.tipo, "float") == 0 || strcmp($3.tipo, "float") == 0) {
            printf("float T%d;\n", res);
            strcpy(tipo, "float");
        } else {
            printf("int T%d;\n", res);
            strcpy(tipo, "int");
        }
        printf("T%d = T%d + T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, tipo);
    }
  | NEG expr {
        int res = temp_count++;
        printf("bool T%d;\n", res);
        printf("T%d = !T%d;\n", res, $2.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, "bool");
    }

  | expr MENOS expr {
        int res = temp_count++;
        char tipo[10];
        if (strcmp($1.tipo, "float") == 0 || strcmp($3.tipo, "float") == 0) {
            printf("float T%d;\n", res);
            strcpy(tipo, "float");
        } else {
            printf("int T%d;\n", res);
            strcpy(tipo, "int");
        }
        printf("T%d = T%d - T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, tipo);
    }
  | expr VEZES expr {
        int res = temp_count++;
        char tipo[10];
        if (strcmp($1.tipo, "float") == 0 || strcmp($3.tipo, "float") == 0) {
            printf("float T%d;\n", res);
            strcpy(tipo, "float");
        } else {
            printf("int T%d;\n", res);
            strcpy(tipo, "int");
        }
        printf("T%d = T%d * T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, tipo);
    }
  | expr DIV expr {
        int res = temp_count++;
        char tipo[10];
        if (strcmp($1.tipo, "float") == 0 || strcmp($3.tipo, "float") == 0) {
            printf("float T%d;\n", res);
            strcpy(tipo, "float");
        } else {
            printf("int T%d;\n", res);
            strcpy(tipo, "int");
        }
        printf("T%d = T%d / T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, tipo);
    }

  // Relacionais
  | expr IGUAL expr {
        int res = temp_count++;
        printf("bool T%d;\n", res);
        printf("T%d = T%d == T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, "bool");
    }
  | expr DIFERENTE expr {
        int res = temp_count++;
        printf("bool T%d;\n", res);
        printf("T%d = T%d != T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, "bool");
    }
  | expr MENOR expr {
        int res = temp_count++;
        printf("bool T%d;\n", res);
        printf("T%d = T%d < T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, "bool");
    }
  | expr MAIOR expr {
        int res = temp_count++;
        printf("bool T%d;\n", res);
        printf("T%d = T%d > T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, "bool");
    }
  | expr MENORIGUAL expr {
        int res = temp_count++;
        printf("bool T%d;\n", res);
        printf("T%d = T%d <= T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, "bool");
    }
  | expr MAIORIGUAL expr {
        int res = temp_count++;
        printf("bool T%d;\n", res);
        printf("T%d = T%d >= T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, "bool");
    }

  // Lógicos
  | expr E expr {
        int res = temp_count++;
        printf("bool T%d;\n", res);
        printf("T%d = T%d && T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, "bool");
    }
  | expr OU expr {
        int res = temp_count++;
        printf("bool T%d;\n", res);
        printf("T%d = T%d || T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, "bool");
    }

  | fator
;

fator:
    ABRE_P expr FECHA_P {
        $$.temp_id = $2.temp_id;
        strcpy($$.tipo, $2.tipo);
    }
  | ABRE_P TIPO FECHA_P fator {
        int res = temp_count++;
        printf("%s T%d;\n", $2, res);
        printf("T%d = (%s) T%d;\n", res, $2, $4.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, $2);
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
  | CARACTERE {
        int res = temp_count++;
        printf("char T%d;\n", res);
        printf("T%d = %s;\n", res, $1);
        $$.temp_id = res;
        strcpy($$.tipo, "char");
    }
  | BOOLLIT {
        int res = temp_count++;
        printf("bool T%d;\n", res);
        printf("T%d = %d;\n", res, $1);
        $$.temp_id = res;
        strcpy($$.tipo, "bool");
    }
  | ID {
        int endereco = obter_endereco($1);
        strcpy($$.tipo, obter_tipo($1));
        $$.temp_id = endereco;
    }
;

%%

int main() {
    yyparse();
    return 0;
}
