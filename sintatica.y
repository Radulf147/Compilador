%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_TEMP 100
#define MAX_SYM 100

int temp_count = 0;
int sym_count = 0;
char *symbols[MAX_SYM];

void geraTemp(char *s) {
    temp_count++;
    sprintf(s, "t%d", temp_count);
}

void insereSimbolo(char *id) {
    symbols[sym_count] = strdup(id);
    sym_count++;
}

void imprimeDeclaracoes() {
    int i;
    for (i = 1; i <= temp_count; i++) {
        printf("int t%d;\n", i);
    }
    for (i = 0; i < sym_count; i++) {
        printf("int %s;\n", symbols[i]);
    }
}
%}

%token ID NUM
%token INT
%left '+' '-' 
%left '*' '/'

%%
programa: declaracoes lista_comandos {
              imprimeDeclaracoes();
              printf("%s\n", $2);
          }
        ;

declaracoes: declaracoes declaracao
           | /* vazio */
           ;

declaracao: INT ID ';' {
               insereSimbolo($2);
           }
           ;

lista_comandos: lista_comandos comando
              | comando
              ;

comando: atribuicao ';' {
            $$ = $1;
         }
       ;

atribuicao: ID '=' expr {
                char res[100];
                sprintf(res, "%s = %s;\n", $1, $3);
                $$ = strdup(res);
            }
          ;

expr: expr '+' expr {
          char temp[100], res[100];
          geraTemp(temp);
          sprintf(res, "%s = %s + %s;\n", temp, $1, $3);
          $$ = strdup(temp);
          printf("%s", res);
      }
    | expr '-' expr {
          char temp[100], res[100];
          geraTemp(temp);
          sprintf(res, "%s = %s - %s;\n", temp, $1, $3);
          $$ = strdup(temp);
          printf("%s", res);
      }
    | expr '*' expr {
          char temp[100], res[100];
          geraTemp(temp);
          sprintf(res, "%s = %s * %s;\n", temp, $1, $3);
          $$ = strdup(temp);
          printf("%s", res);
      }
    | expr '/' expr {
          char temp[100], res[100];
          geraTemp(temp);
          sprintf(res, "%s = %s / %s;\n", temp, $1, $3);
          $$ = strdup(temp);
          printf("%s", res);
      }
    | '(' expr ')' { $$ = $2; }
    | ID { $$ = $1; }
    | NUM { $$ = $1; }
    ;
%%
int main() {
    yyparse();
    return 0;
}

int yyerror(char *s) {
    printf("Erro: %s\n", s);
    return 0;
}
