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

%token <ival> NUM
%token <fval> FNUM
%token <str> ID
%token <str> TIPO
%token <str> CARACTERE
%token ATRIB
%token MAIS MENOS VEZES DIV
%token ABRE_P FECHA_P
%token <ival> BOOLLIT

%token MENOR MAIOR MENORIG IGUAL MAIORIG DIF
%token AND OR NOT

%left OR
%left AND
%left MAIS MENOS
%left VEZES DIV
%left MENOR MAIOR MENORIG MAIORIG IGUAL DIF
%right NOT

%type <expr_attr> expr

%%

programa: lista_comandos ;

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
    int t1 = $1.temp_id;
    int t3 = $3.temp_id;
    char tipo[10];

    // Conversão de tipos, se necessário
    if (strcmp($1.tipo, "float") == 0 || strcmp($3.tipo, "float") == 0) {
        strcpy(tipo, "float");

        if (strcmp($1.tipo, "int") == 0) {
            int cast_temp = temp_count++;
            printf("float T%d;\n", cast_temp);
            printf("T%d = (float) T%d;\n", cast_temp, $1.temp_id);
            t1 = cast_temp;
        }
        if (strcmp($3.tipo, "int") == 0) {
            int cast_temp = temp_count++;
            printf("float T%d;\n", cast_temp);
            printf("T%d = (float) T%d;\n", cast_temp, $3.temp_id);
            t3 = cast_temp;
        }

        printf("float T%d;\n", res);
    } else {
        strcpy(tipo, "int");
        printf("int T%d;\n", res);
    }

    printf("T%d = T%d + T%d;\n", res, t1, t3);
    $$.temp_id = res;
    strcpy($$.tipo, tipo);
    $$.nome[0] = '\0';
}

  | expr MENOS expr {
        int res = temp_count++;
        char tipo[10];
        if (strcmp($1.tipo, "float") == 0 || strcmp($3.tipo, "float") == 0) {
            // Conversão explícita de int para float
            if (strcmp($1.tipo, "int") == 0) {
                printf("float T%d;\n", res);
                printf("T%d = (float) T%d;\n", res, $1.temp_id);
                strcpy(tipo, "float");
            } else if (strcmp($3.tipo, "int") == 0) {
                printf("float T%d;\n", res);
                printf("T%d = (float) T%d;\n", res, $3.temp_id);
                strcpy(tipo, "float");
            }
            else {
                printf("float T%d;\n", res);
                strcpy(tipo, "float");
            }
        } else {
            printf("int T%d;\n", res);
            strcpy(tipo, "int");
        }
        printf("T%d = T%d - T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, tipo);
        $$.nome[0] = '\0';
    }
  | expr VEZES expr {
        int res = temp_count++;
        char tipo[10];
        if (strcmp($1.tipo, "float") == 0 || strcmp($3.tipo, "float") == 0) {
            // Conversão explícita de int para float
            if (strcmp($1.tipo, "int") == 0) {
                printf("float T%d;\n", res);
                printf("T%d = (float) T%d;\n", res, $1.temp_id);
                strcpy(tipo, "float");
            } else if (strcmp($3.tipo, "int") == 0) {
                printf("float T%d;\n", res);
                printf("T%d = (float) T%d;\n", res, $3.temp_id);
                strcpy(tipo, "float");
            }
            else {
                printf("float T%d;\n", res);
                strcpy(tipo, "float");
            }
        } else {
            printf("int T%d;\n", res);
            strcpy(tipo, "int");
        }
        printf("T%d = T%d * T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, tipo);
        $$.nome[0] = '\0';
    }
  | expr DIV expr {
        int res = temp_count++;
        char tipo[10];
        if (strcmp($1.tipo, "float") == 0 || strcmp($3.tipo, "float") == 0) {
            // Conversão explícita de int para float
            if (strcmp($1.tipo, "int") == 0) {
                printf("float T%d;\n", res);
                printf("T%d = (float) T%d;\n", res, $1.temp_id);
                strcpy(tipo, "float");
            } else if (strcmp($3.tipo, "int") == 0) {
                printf("float T%d;\n", res);
                printf("T%d = (float) T%d;\n", res, $3.temp_id);
                strcpy(tipo, "float");
            }
            else {
                printf("float T%d;\n", res);
                strcpy(tipo, "float");
            }
        } else {
            printf("int T%d;\n", res);
            strcpy(tipo, "int");
        }
        printf("T%d = T%d / T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, tipo);
        $$.nome[0] = '\0';
    }

  | expr AND expr {
        int res = temp_count++;
        printf("int T%d;\n", res);
        if (strcmp($1.tipo, "bool") != 0 || strcmp($3.tipo, "bool") != 0) {
            printf("// Erro: operadores AND requerem bool, recebido %s e %s\n", $1.tipo, $3.tipo);
        }
        printf("T%d = T%d && T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, "bool");
        $$.nome[0] = '\0';
    }
  | expr OR expr {
        int res = temp_count++;
        printf("int T%d;\n", res);
        if (strcmp($1.tipo, "bool") != 0 || strcmp($3.tipo, "bool") != 0) {
            printf("// Erro: operadores OR requerem bool, recebido %s e %s\n", $1.tipo, $3.tipo);
        }
        printf("T%d = T%d || T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, "bool");
        $$.nome[0] = '\0';
    }
  | NOT expr {
        int res = temp_count++;
        printf("int T%d;\n", res);
        if (strcmp($2.tipo, "bool") != 0) {
            printf("// Erro: operador NOT requer bool, recebido %s\n", $2.tipo);
        }
        printf("T%d = !T%d;\n", res, $2.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, "bool");
        $$.nome[0] = '\0';
    }

  | expr MENOR expr {
        int res = temp_count++;
        printf("int T%d;\n", res);
        printf("T%d = T%d < T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, "bool");
        $$.nome[0] = '\0';
    }
  | expr MAIOR expr {
        int res = temp_count++;
        printf("int T%d;\n", res);
        printf("T%d = T%d > T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, "bool");
        $$.nome[0] = '\0';
    }
  | expr MENORIG expr {
        int res = temp_count++;
        printf("int T%d;\n", res);
        printf("T%d = T%d <= T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, "bool");
        $$.nome[0] = '\0';
    }
  | expr MAIORIG expr {
        int res = temp_count++;
        printf("int T%d;\n", res);
        printf("T%d = T%d >= T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, "bool");
        $$.nome[0] = '\0';
    }
  | expr IGUAL expr {
        int res = temp_count++;
        printf("int T%d;\n", res);
        printf("T%d = T%d == T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, "bool");
        $$.nome[0] = '\0';
    }
  | expr DIF expr {
        int res = temp_count++;
        printf("int T%d;\n", res);
        printf("T%d = T%d != T%d;\n", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, "bool");
        $$.nome[0] = '\0';
    }

  | ABRE_P expr FECHA_P {
        $$.temp_id = $2.temp_id;
        strcpy($$.tipo, $2.tipo);
        strcpy($$.nome, $2.nome);
    }
  | NUM {
        int res = temp_count++;
        printf("int T%d;\n", res);
        printf("T%d = %d;\n", res, $1);
        $$.temp_id = res;
        strcpy($$.tipo, "int");
        $$.nome[0] = '\0';
    }
  | FNUM {
        int res = temp_count++;
        printf("float T%d;\n", res);
        printf("T%d = %.2f;\n", res, $1);
        $$.temp_id = res;
        strcpy($$.tipo, "float");
        $$.nome[0] = '\0';
    }
  | CARACTERE {
        int res = temp_count++;
        printf("char T%d;\n", res);
        printf("T%d = %s;\n", res, $1);
        $$.temp_id = res;
        strcpy($$.tipo, "char");
        $$.nome[0] = '\0';
    }
  | BOOLLIT {
        int res = temp_count++;
        printf("int T%d;\n", res);
        printf("T%d = %d;\n", res, $1);
        $$.temp_id = res;
        strcpy($$.tipo, "bool");
        $$.nome[0] = '\0';
    }
  | ID {
        int endereco = obter_endereco($1);
        strcpy($$.tipo, obter_tipo($1));
        $$.temp_id = endereco;
        strcpy($$.nome, $1);
    }
;

%%

int main() {
    yyparse();
    return 0;
}
