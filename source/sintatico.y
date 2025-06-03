%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h> // Necessário para va_list em adicionar_operacao_cg

extern int yylex();
void yyerror(const char *s);

#define HASH_TABLE_SIZE 101

typedef struct Simbolo {
    char nome[50];
    char tipo[10];
    int temp_id;
    struct Simbolo *next;
} Simbolo;

Simbolo* hash_tabela[HASH_TABLE_SIZE];
int temp_count = 1;

// --- Estruturas para Geração de Código em Duas Fases ---
typedef struct CodegenDecl {
    char definicao[100]; // Ex: "int x_T1;" ou "float T5;"
    struct CodegenDecl *next;
} CodegenDecl;

typedef struct CodegenOp {
    char instrucao[200]; // Ex: "T1 = T2 + T3;"
    struct CodegenOp *next;
} CodegenOp;

CodegenDecl *head_declaracoes_cg = NULL;
CodegenDecl *tail_declaracoes_cg = NULL;
CodegenOp *head_operacoes_cg = NULL;
CodegenOp *tail_operacoes_cg = NULL;

// Funções auxiliares para as listas de código
void inicializar_listas_cg() {
    // Limpa listas anteriores (se houver) - importante se fosse para múltiplas funções
    CodegenDecl *decl_iter = head_declaracoes_cg;
    while (decl_iter) {
        CodegenDecl *temp = decl_iter;
        decl_iter = decl_iter->next;
        free(temp);
    }
    head_declaracoes_cg = tail_declaracoes_cg = NULL;

    CodegenOp *op_iter = head_operacoes_cg;
    while (op_iter) {
        CodegenOp *temp = op_iter;
        op_iter = op_iter->next;
        free(temp);
    }
    head_operacoes_cg = tail_operacoes_cg = NULL;
}

void adicionar_declaracao_cg_str(const char* declaracao_str) {
    CodegenDecl *novo = (CodegenDecl*)malloc(sizeof(CodegenDecl));
    if (!novo) { yyerror("Falha ao alocar memória para declaração CG"); exit(EXIT_FAILURE); }
    strncpy(novo->definicao, declaracao_str, sizeof(novo->definicao)-1);
    novo->definicao[sizeof(novo->definicao)-1] = '\0';
    novo->next = NULL;
    if (tail_declaracoes_cg) {
        tail_declaracoes_cg->next = novo;
    } else {
        head_declaracoes_cg = novo;
    }
    tail_declaracoes_cg = novo;
}

void adicionar_declaracao_cg(const char* tipo, const char* nome_cg) {
    char buffer[100];
    sprintf(buffer, "%s %s;", tipo, nome_cg);
    adicionar_declaracao_cg_str(buffer);
}

void adicionar_operacao_cg_str(const char* instrucao_str) {
    CodegenOp *novo = (CodegenOp*)malloc(sizeof(CodegenOp));
    if (!novo) { yyerror("Falha ao alocar memória para operação CG"); exit(EXIT_FAILURE); }
    strncpy(novo->instrucao, instrucao_str, sizeof(novo->instrucao)-1);
    novo->instrucao[sizeof(novo->instrucao)-1] = '\0';
    novo->next = NULL;
    if (tail_operacoes_cg) {
        tail_operacoes_cg->next = novo;
    } else {
        head_operacoes_cg = novo;
    }
    tail_operacoes_cg = novo;
}

void adicionar_operacao_cg(const char* formato, ...) {
    char buffer[200]; 
    va_list args;
    va_start(args, formato);
    vsnprintf(buffer, sizeof(buffer), formato, args);
    va_end(args);
    adicionar_operacao_cg_str(buffer);
}

void imprimir_codigo_cg() {
    CodegenDecl *decl = head_declaracoes_cg;
    while (decl) {
        printf("%s\n", decl->definicao);
        decl = decl->next;
    }
    // Opcional: linha em branco entre declarações e código se ambos existirem
    // if (head_declaracoes_cg && head_operacoes_cg) {
    //     printf("\n");
    // }
    CodegenOp *op = head_operacoes_cg;
    while (op) {
        printf("%s\n", op->instrucao);
        op = op->next;
    }
}

void liberar_listas_cg() { // Chamada ao final para limpar memória
    inicializar_listas_cg(); // Reutiliza a lógica de limpar as listas
}

// --- Fim das Estruturas para Geração de Código ---


unsigned int calcular_hash(char *nome) {
    unsigned int hash_val = 0;
    while (*nome) { hash_val = (hash_val << 5) + *nome++; }
    return hash_val % HASH_TABLE_SIZE;
}

int adicionar_simbolo(char *nome, char *tipo) {
    unsigned int indice = calcular_hash(nome);
    Simbolo *atual = hash_tabela[indice];
    while (atual != NULL) {
        if (strcmp(atual->nome, nome) == 0) { return atual->temp_id; }
        atual = atual->next;
    }
    Simbolo *novo_simbolo = (Simbolo*) malloc(sizeof(Simbolo));
    if (!novo_simbolo) { yyerror("Falha ao alocar memória para novo símbolo."); exit(EXIT_FAILURE); }
    strcpy(novo_simbolo->nome, nome); strcpy(novo_simbolo->tipo, tipo);
    novo_simbolo->temp_id = temp_count++; novo_simbolo->next = hash_tabela[indice];
    hash_tabela[indice] = novo_simbolo; return novo_simbolo->temp_id;
}

Simbolo* obter_simbolo(char *nome) {
    unsigned int indice = calcular_hash(nome); Simbolo *atual = hash_tabela[indice];
    while (atual != NULL) { 
        if (strcmp(atual->nome, nome) == 0) { return atual; } atual = atual->next; 
    }
    return NULL;
}

void inicializar_hash_tabela() { 
    for (int i = 0; i < HASH_TABLE_SIZE; i++) { 
        hash_tabela[i] = NULL; 
    } 
}

void limpar_hash_tabela() {
    for (int i = 0; i < HASH_TABLE_SIZE; i++) {
        Simbolo *atual = hash_tabela[i];
        while (atual != NULL) { Simbolo *proximo = atual->next; free(atual); atual = proximo; }
        hash_tabela[i] = NULL;
    }
}

void yyerror(const char *s) { 
    fprintf(stderr, "Erro: %s\n", s); 
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

%token <str> INCLUDE_DIRECTIVE
%token KWD_MAIN KWD_RETURN
%token ABRE_CHAVE FECHA_CHAVE

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
%left OU E IGUAL DIFERENTE MENOR MAIOR MENORIGUAL MAIORIGUAL
%left MAIS MENOS
%left VEZES DIV

%type <expr_attr> expr fator

%%

programa:
    includes_opt definicao_main
    ;

includes_opt:
    /* epsilon */
    | includes_opt include_stmt
    ;

include_stmt:
    INCLUDE_DIRECTIVE { printf("%s\n", $1); if ($1) free($1); } // Impressão direta de includes mantida
    ;

definicao_main:
    TIPO KWD_MAIN ABRE_P FECHA_P ABRE_CHAVE {
        if ($1 == NULL || strcmp($1, "int") != 0) {
            char error_msg[128];
            sprintf(error_msg, "Erro Semântico: Função main deve ser 'int', mas foi '%s'", ($1 ? $1 : "NULL"));
            yyerror(error_msg); YYABORT;
        }
        printf("int main() {\n"); // Impressão direta do cabeçalho do main
        if ($1) free($1);
        // inicializar_listas_cg(); // Movido para o main() do yacc.
    }
    lista_comandos_opt
    retorno_main
    FECHA_CHAVE {
        imprimir_codigo_cg(); // Imprime todas as declarações, depois todas as operações
        printf("}\n"); // Impressão direta do fechamento do main
        // liberar_listas_cg(); // Movido para o main() do yacc.
    }
    ;

lista_comandos_opt:
    /* epsilon */
    | lista_comandos
    ;

retorno_main:
    KWD_RETURN NUM ';' { adicionar_operacao_cg("return %d;", $2); }
    ;

lista_comandos:
    lista_comandos comando
    | comando
    ;

comando:
    decl
    | atribuicao
    | expr ';' { /* Expressões soltas não geram código visível além de seus componentes */ }
    ;

decl:
    TIPO ID ';' {
        int id_temp = adicionar_simbolo($2, $1);
        char nome_var_formatado[60];
        sprintf(nome_var_formatado, "%s_T%d", $2, id_temp);
        adicionar_declaracao_cg($1, nome_var_formatado);
        if ($1) free($1); if ($2) free($2);
    }
    ;

atribuicao:
    ID ATRIB expr ';' {
        Simbolo* s = obter_simbolo($1);
        if (!s) { /* ... erro ... YYABORT; */ 
            char error_msg[100]; sprintf(error_msg, "Variável '%s' não declarada.", $1); 
            yyerror(error_msg); if ($1) free($1); YYABORT; 
        }
        
        char var_name_cg[60];
        sprintf(var_name_cg, "%s_T%d", s->nome, s->temp_id);
        int expr_temp_id = $3.temp_id;
        char expr_tipo[10];
        strcpy(expr_tipo, $3.tipo);

        if (strcmp(s->tipo, "float") == 0 && strcmp(expr_tipo, "int") == 0) {
            int novo_temp_cast = temp_count++;
            char nome_novo_temp_cast_cg[10]; sprintf(nome_novo_temp_cast_cg, "T%d", novo_temp_cast);
            adicionar_declaracao_cg("float", nome_novo_temp_cast_cg);
            adicionar_operacao_cg("T%d = (float) T%d; // Conversao implicita int para float na atribuicao", novo_temp_cast, expr_temp_id);
            expr_temp_id = novo_temp_cast; // Usa o novo temporário convertido
            // strcpy(expr_tipo, "float"); // Não precisa alterar expr_tipo aqui, pois só usamos o id
        } else if (strcmp(s->tipo, expr_tipo) != 0 && !(strcmp(s->tipo, "int") == 0 && strcmp(expr_tipo, "float") == 0) ) {
             // Aviso: não vamos gerar código para o aviso, apenas para a atribuição.
             // O printf original do aviso foi removido para não poluir a lista de operações.
        }
        adicionar_operacao_cg("%s = T%d;", var_name_cg, expr_temp_id);
        if ($1) free($1);
    }
    ;

expr:
    expr MAIS expr {
        int res = temp_count++; char tipo_res[10];
        int id1 = $1.temp_id; char tipo1[10]; strcpy(tipo1, $1.tipo);
        int id3 = $3.temp_id; char tipo3[10]; strcpy(tipo3, $3.tipo);
        char nome_temp_res[10]; sprintf(nome_temp_res, "T%d", res);

        if (strcmp(tipo1, "float") == 0 && strcmp(tipo3, "int") == 0) {
            int conv_temp = temp_count++; char nome_conv_temp[10]; sprintf(nome_conv_temp, "T%d", conv_temp);
            adicionar_declaracao_cg("float", nome_conv_temp);
            adicionar_operacao_cg("T%d = (float) T%d;", conv_temp, id3);
            id3 = conv_temp; strcpy(tipo3, "float");
        } else if (strcmp(tipo1, "int") == 0 && strcmp(tipo3, "float") == 0) {
            int conv_temp = temp_count++; char nome_conv_temp[10]; sprintf(nome_conv_temp, "T%d", conv_temp);
            adicionar_declaracao_cg("float", nome_conv_temp);
            adicionar_operacao_cg("T%d = (float) T%d;", conv_temp, id1);
            id1 = conv_temp; strcpy(tipo1, "float");
        }
        if (strcmp(tipo1, "float") == 0 || strcmp(tipo3, "float") == 0) strcpy(tipo_res, "float"); else strcpy(tipo_res, "int");
        adicionar_declaracao_cg(tipo_res, nome_temp_res);
        adicionar_operacao_cg("T%d = T%d + T%d;", res, id1, id3);
        $$.temp_id = res; strcpy($$.tipo, tipo_res);
    }
    // Adapte MENOS, VEZES, DIV similarmente ao MAIS
    | expr MENOS expr {
        int res = temp_count++; char tipo_res[10];
        int id1 = $1.temp_id; char tipo1[10]; strcpy(tipo1, $1.tipo);
        int id3 = $3.temp_id; char tipo3[10]; strcpy(tipo3, $3.tipo);
        char nome_temp_res[10]; sprintf(nome_temp_res, "T%d", res);

        if (strcmp(tipo1, "float") == 0 && strcmp(tipo3, "int") == 0) { 
            int conv_temp = temp_count++; char nct[10]; 
            sprintf(nct, "T%d", conv_temp); 
            adicionar_declaracao_cg("float", nct); 
            adicionar_operacao_cg("T%d = (float) T%d;", conv_temp, id3); 
            id3 = conv_temp; 
            strcpy(tipo3, "float"); 
        }
        else if (strcmp(tipo1, "int") == 0 && strcmp(tipo3, "float") == 0) { 
            int conv_temp = temp_count++; char nct[10]; sprintf(nct, "T%d", conv_temp); 
            adicionar_declaracao_cg("float", nct); 
            adicionar_operacao_cg("T%d = (float) T%d;", conv_temp, id1); 
            id1 = conv_temp; strcpy(tipo1, "float"); 
        }
        if (strcmp(tipo1, "float") == 0 || strcmp(tipo3, "float") == 0){ 
        
            strcpy(tipo_res, "float");

        }
        else { 
            strcpy(tipo_res, "int"); 
        } 
        adicionar_declaracao_cg(tipo_res, nome_temp_res); 
        adicionar_operacao_cg("T%d = T%d - T%d;", res, id1, id3); 
        $$.temp_id = res; 
        strcpy($$.tipo, tipo_res);
    }
    | expr VEZES expr {
        int res = temp_count++; char tipo_res[10];
        int id1 = $1.temp_id; char tipo1[10]; strcpy(tipo1, $1.tipo);
        int id3 = $3.temp_id; char tipo3[10]; strcpy(tipo3, $3.tipo);
        char nome_temp_res[10]; sprintf(nome_temp_res, "T%d", res);
        if (strcmp(tipo1, "float") == 0 && strcmp(tipo3, "int") == 0) { 
            int conv_temp = temp_count++; 
            char nct[10]; sprintf(nct, "T%d", conv_temp); 
            adicionar_declaracao_cg("float", nct); 
            adicionar_operacao_cg("T%d = (float) T%d;", conv_temp, id3); 
            id3 = conv_temp; strcpy(tipo3, "float"); 
        }
        else if (strcmp(tipo1, "int") == 0 && strcmp(tipo3, "float") == 0) { 
            int conv_temp = temp_count++; char nct[10]; 
            sprintf(nct, "T%d", conv_temp); 
            adicionar_declaracao_cg("float", nct); 
            adicionar_operacao_cg("T%d = (float) T%d;", conv_temp, id1); 
            id1 = conv_temp; strcpy(tipo1, "float"); 
        }
        if (strcmp(tipo1, "float") == 0 || strcmp(tipo3, "float") == 0) {
            strcpy(tipo_res, "float"); 
        }
        else {
            strcpy(tipo_res, "int");
        }
        adicionar_declaracao_cg(tipo_res, nome_temp_res); 
        adicionar_operacao_cg("T%d = T%d * T%d;", res, id1, id3); 
        $$.temp_id = res; strcpy($$.tipo, tipo_res);
    }
    | expr DIV expr {
        int res = temp_count++; char tipo_res[10];
        int id1 = $1.temp_id; char tipo1[10]; 
        strcpy(tipo1, $1.tipo);
        int id3 = $3.temp_id; char tipo3[10]; 
        strcpy(tipo3, $3.tipo);
        char nome_temp_res[10]; 
        sprintf(nome_temp_res, "T%d", res);
        
        if (strcmp(tipo1, "float") == 0 && strcmp(tipo3, "int") == 0) { 
            int conv_temp = temp_count++; char nct[10]; 
            sprintf(nct, "T%d", conv_temp); 
            adicionar_declaracao_cg("float", nct); 
            adicionar_operacao_cg("T%d = (float) T%d;", conv_temp, id3); 
            id3 = conv_temp; strcpy(tipo3, "float"); 
        }
        else if (strcmp(tipo1, "int") == 0 && strcmp(tipo3, "float") == 0) { 
            int conv_temp = temp_count++; 
            char nct[10]; sprintf(nct, "T%d", conv_temp); 
            adicionar_declaracao_cg("float", nct); 
            adicionar_operacao_cg("T%d = (float) T%d;", conv_temp, id1); 
            id1 = conv_temp; strcpy(tipo1, "float"); 
        }
        if (strcmp(tipo1, "float") == 0 || strcmp(tipo3, "float") == 0) {
            strcpy(tipo_res, "float");
        } 
        else {
            strcpy(tipo_res, "int");
        }
        adicionar_declaracao_cg(tipo_res, nome_temp_res); 
        adicionar_operacao_cg("T%d = T%d / T%d;", res, id1, id3); 
        $$.temp_id = res; 
        strcpy($$.tipo, tipo_res);
    }
    // Adapte operadores relacionais e lógicos similarmente
    | expr IGUAL expr { 
        int res = temp_count++; 
        char nt[10]; 
        sprintf(nt, "T%d", res); 
        adicionar_declaracao_cg("bool", nt); 
        adicionar_operacao_cg("T%d = T%d == T%d;", res, $1.temp_id, $3.temp_id); 
        $$.temp_id = res; strcpy($$.tipo, "bool"); 
    }
    | expr DIFERENTE expr { 
        int res = temp_count++; 
        char nt[10]; sprintf(nt, "T%d", res); 
        adicionar_declaracao_cg("bool", nt); 
        adicionar_operacao_cg("T%d = T%d != T%d;", res, $1.temp_id, $3.temp_id); 
        $$.temp_id = res; 
        strcpy($$.tipo, "bool"); 
    }
    | expr MENOR expr { 
        int res = temp_count++; 
        char nt[10]; sprintf(nt, "T%d", res); 
        adicionar_declaracao_cg("bool", nt); 
        adicionar_operacao_cg("T%d = T%d < T%d;", res, $1.temp_id, $3.temp_id); 
        $$.temp_id = res; 
        strcpy($$.tipo, "bool"); 
    }
    | expr MAIOR expr { 
        int res = temp_count++;
         char nt[10]; sprintf(nt, "T%d", res); 
         adicionar_declaracao_cg("bool", nt); 
         adicionar_operacao_cg("T%d = T%d > T%d;", res, $1.temp_id, $3.temp_id); 
         $$.temp_id = res; 
         strcpy($$.tipo, "bool"); 
    }
    | expr MENORIGUAL expr { 
        int res = temp_count++; 
        char nt[10]; sprintf(nt, "T%d", res); 
        adicionar_declaracao_cg("bool", nt); 
        adicionar_operacao_cg("T%d = T%d <= T%d;", res, $1.temp_id, $3.temp_id);
         $$.temp_id = res; 
         strcpy($$.tipo, "bool"); 
    }
    | expr MAIORIGUAL expr { 
        int res = temp_count++; 
        char nt[10]; sprintf(nt, "T%d", res); 
        adicionar_declaracao_cg("bool", nt);
         adicionar_operacao_cg("T%d = T%d >= T%d;", res, $1.temp_id, $3.temp_id); 
         $$.temp_id = res; 
         strcpy($$.tipo, "bool");
     }
    | expr E expr { 
        int res = temp_count++;
        char nt[10]; sprintf(nt, "T%d", res); 
        adicionar_declaracao_cg("bool", nt);
         adicionar_operacao_cg("T%d = T%d && T%d;", res, $1.temp_id, $3.temp_id); 
         $$.temp_id = res; 
         strcpy($$.tipo, "bool"); 
    }
    | expr OU expr { 
        int res = temp_count++; 
        char nt[10]; sprintf(nt, "T%d", res); 
        adicionar_declaracao_cg("bool", nt); 
        adicionar_operacao_cg("T%d = T%d || T%d;", res, $1.temp_id, $3.temp_id); 
        $$.temp_id = res; 
        strcpy($$.tipo, "bool"); 
    }
    | NEG expr { 
        int res = temp_count++; 
        char nt[10]; sprintf(nt, "T%d", res); 
        adicionar_declaracao_cg("bool", nt); 
        adicionar_operacao_cg("T%d = !T%d;", res, $2.temp_id); 
        $$.temp_id = res; 
        strcpy($$.tipo, "bool"); 
    }
    | fator
    ;

fator:
    ABRE_P expr FECHA_P { $$.temp_id = $2.temp_id; strcpy($$.tipo, $2.tipo); }
    | ABRE_P TIPO FECHA_P fator {
        int res = temp_count++; 
        char nome_temp_res[10]; sprintf(nome_temp_res, "T%d", res);
        adicionar_declaracao_cg($2, nome_temp_res); // $2 é o tipo do cast
        adicionar_operacao_cg("T%d = (%s) T%d;", res, $2, $4.temp_id);
        $$.temp_id = res; strcpy($$.tipo, $2);
        if ($2) free($2);
    }
    | NUM {
        int res = temp_count++; char nome_temp_res[10]; sprintf(nome_temp_res, "T%d", res);
        adicionar_declaracao_cg("int", nome_temp_res);
        adicionar_operacao_cg("T%d = %d;", res, $1);
        $$.temp_id = res; strcpy($$.tipo, "int");
    }
    | FNUM {
        int res = temp_count++; char nome_temp_res[10]; sprintf(nome_temp_res, "T%d", res);
        adicionar_declaracao_cg("float", nome_temp_res);
        adicionar_operacao_cg("T%d = %.2f;", res, $1);
        $$.temp_id = res; strcpy($$.tipo, "float");
    }
    | CARACTERE {
        int res = temp_count++; char nome_temp_res[10]; sprintf(nome_temp_res, "T%d", res);
        adicionar_declaracao_cg("char", nome_temp_res);
        adicionar_operacao_cg("T%d = %s;", res, $1); // $1 é a string do caractere, ex: "'a'"
        $$.temp_id = res; strcpy($$.tipo, "char");
        if ($1) free($1);
    }
    | BOOLLIT {
        int res = temp_count++; char nome_temp_res[10]; sprintf(nome_temp_res, "T%d", res);
        adicionar_declaracao_cg("bool", nome_temp_res);
        adicionar_operacao_cg("T%d = %s;", res, ($1 ? "true" : "false"));
        $$.temp_id = res; strcpy($$.tipo, "bool");
    }
    | ID {
        Simbolo* s = obter_simbolo($1);
        if (!s) { /* ... erro ... YYABORT; */ 
            char error_msg[100]; sprintf(error_msg, "Variável '%s' não declarada.", $1); 
            yyerror(error_msg); if ($1) free($1); YYABORT;
        }
        $$.temp_id = s->temp_id; strcpy($$.tipo, s->tipo); strcpy($$.nome, s->nome); 
        if ($1) free($1);
    }
    ;

%%

int main() {
    inicializar_hash_tabela();
    inicializar_listas_cg(); // Inicializa listas de código uma vez
    yyparse();
    limpar_hash_tabela();
    liberar_listas_cg();    // Libera listas de código ao final
    return 0;
}