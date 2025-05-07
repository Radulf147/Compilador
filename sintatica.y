%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    char id[32];
    char tipo[10];
} Simbolo;

Simbolo tabela_simbolos[100];
int num_simbolos = 0;

char tipo_atual[10]; // ✅ DECLARADA AQUI!

void adicionar_simbolo(char* id, char* tipo) {
    for (int i = 0; i < num_simbolos; i++) {
        if (strcmp(tabela_simbolos[i].id, id) == 0) {
            printf("Erro: variável '%s' já declarada.\n", id);
            exit(1);
        }
    }
    strcpy(tabela_simbolos[num_simbolos].id, id);
    strcpy(tabela_simbolos[num_simbolos].tipo, tipo);
    num_simbolos++;
}

int procurar_simbolo(char* id) {
    for (int i = 0; i < num_simbolos; i++) {
        if (strcmp(tabela_simbolos[i].id, id) == 0) {
            return 1;
        }
    }
    return 0;
}

%}

%token INT FLOAT CHAR BOOL
%token IF ELSE WHILE
%token ID INT_LITERAL FLOAT_LITERAL CHAR_LITERAL TRUE FALSE
%token ASSIGN ADD SUB MUL DIV
%token EQ NEQ LT LTE GT GTE
%token AND OR NOT
%token LPAREN RPAREN LBRACE RBRACE SEMI COMMA

%%

programa:
    lista_comandos
    ;

lista_comandos:
    lista_comandos comando
    | comando
    ;

comando:
    declaracao
    | atribuicao SEMI
    | condicional
    | repeticao
    | bloco
    ;

declaracao:
    tipo lista_ids SEMI
    ;

lista_ids:
    lista_ids COMMA ID { adicionar_simbolo($3, tipo_atual); }
    | ID { adicionar_simbolo($1, tipo_atual); }
    ;

tipo:
    INT { strcpy(tipo_atual, "int"); }
    | FLOAT { strcpy(tipo_atual, "float"); }
    | CHAR { strcpy(tipo_atual, "char"); }
    | BOOL { strcpy(tipo_atual, "bool"); }
    ;

atribuicao:
    ID ASSIGN expr {
        if (!procurar_simbolo($1)) {
            printf("Erro: variável '%s' não declarada.\n", $1);
            exit(1);
        }
        printf("%s = %s\n", $1, $3);
    }
    ;

condicional:
    IF LPAREN log_expr RPAREN comando
    | IF LPAREN log_expr RPAREN comando ELSE comando
    ;

repeticao:
    WHILE LPAREN log_expr RPAREN comando
    ;

bloco:
    LBRACE lista_comandos RBRACE
    ;

expr:
    expr ADD termo
    | expr SUB termo
    | termo
    ;

termo:
    termo MUL fator
    | termo DIV fator
    | fator
    ;

fator:
    ID { if (!procurar_simbolo($1)) { printf("Erro: variável '%s' não declarada.\n", $1); exit(1); } }
    | INT_LITERAL
    | FLOAT_LITERAL
    | CHAR_LITERAL
    | TRUE
    | FALSE
    | LPAREN expr RPAREN
    ;

rel_expr:
    expr EQ expr
    | expr NEQ expr
    | expr LT expr
    | expr LTE expr
    | expr GT expr
    | expr GTE expr
    ;

log_expr:
    log_expr AND rel_expr
    | log_expr OR rel_expr
    | NOT rel_expr
    | rel_expr
    ;

%%

int main() {
    yyparse();
    return 0;
}

int yyerror(char* s) {
    printf("Erro de sintaxe: %s\n", s);
    return 0;
}
