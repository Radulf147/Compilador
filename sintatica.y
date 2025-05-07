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

void yyerror(const char *s) {
    fprintf(stderr, "Erro sintático: %s\n", s);
}
%}

%union {
    int inteiro;
    float flutuante;
    char caractere;
    char* str;
}

/* Tokens e seus tipos */
%token <str> IDENTIFICADOR
%token <inteiro> NUM_INT
%token <flutuante> NUM_FLOAT
%token <caractere> CARACTERE

%token <str> TIPO_INTEIRO TIPO_FLOAT TIPO_CHAR TIPO_BOOLEAN
%token PRINCIPAL RETORNE
%token SE SENAO ENQUANTO

%token IGUAL DIFERENTE MENOR MAIOR MENORIGUAL MAIORIGUAL
%token E_LOGICO OU_LOGICO NAO_LOGICO

%token ATRIBUICAO MAIS MENOS VEZES DIV
%token ABRE_PARENTESES FECHA_PARENTESES
%token ABRE_CHAVES FECHA_CHAVES
%token PONTOVIRGULA VIRGULA

%token ERRO

/* Tipos não-terminais */
%type <str> tipo

/* Precedência e associatividade */
%left OU_LOGICO
%left E_LOGICO
%nonassoc IGUAL DIFERENTE MENOR MAIOR MENORIGUAL MAIORIGUAL
%left MAIS MENOS
%left VEZES DIV
%right NAO_LOGICO
%right UMINUS

/* Símbolo inicial */
%start programa

%%

programa:
    TIPO_INTEIRO PRINCIPAL ABRE_PARENTESES FECHA_PARENTESES ABRE_CHAVES comandos retorne_stmt FECHA_CHAVES
;

comandos:
    comandos comando
    | /* vazio */
;

comando:
    declaracao PONTOVIRGULA
    | atribuicao PONTOVIRGULA
    | comando_se
    | comando_enquanto
;

declaracao:
    tipo IDENTIFICADOR {
        adicionar_simbolo($2, $1);
    }
;

atribuicao:
    IDENTIFICADOR ATRIBUICAO expressao {
        if (!procurar_simbolo($1)) {
            printf("Erro: variável '%s' não declarada.\n", $1);
            exit(1);
        }
    }
;

comando_se:
    SE ABRE_PARENTESES expressao FECHA_PARENTESES ABRE_CHAVES comandos FECHA_CHAVES
    | SE ABRE_PARENTESES expressao FECHA_PARENTESES ABRE_CHAVES comandos FECHA_CHAVES SENAO ABRE_CHAVES comandos FECHA_CHAVES
;

comando_enquanto:
    ENQUANTO ABRE_PARENTESES expressao FECHA_PARENTESES ABRE_CHAVES comandos FECHA_CHAVES
;

retorne_stmt:
    RETORNE expressao PONTOVIRGULA
;

tipo:
    TIPO_INTEIRO   { $$ = $1; }
    | TIPO_FLOAT   { $$ = $1; }
    | TIPO_CHAR    { $$ = $1; }
    | TIPO_BOOLEAN { $$ = $1; }
;

expressao:
    expressao MAIS expressao
    | expressao MENOS expressao
    | expressao VEZES expressao
    | expressao DIV expressao
    | expressao IGUAL expressao
    | expressao DIFERENTE expressao
    | expressao MENOR expressao
    | expressao MAIOR expressao
    | expressao MENORIGUAL expressao
    | expressao MAIORIGUAL expressao
    | expressao E_LOGICO expressao
    | expressao OU_LOGICO expressao
    | NAO_LOGICO expressao %prec NAO_LOGICO
    | MENOS expressao %prec UMINUS
    | ABRE_PARENTESES expressao FECHA_PARENTESES
    | IDENTIFICADOR
    | NUM_INT
    | NUM_FLOAT
    | CARACTERE
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
