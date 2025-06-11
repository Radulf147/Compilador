%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#ifndef YYABORT
    #define YYABORT return 1
#endif

extern int yylex();
void yyerror(const char *s);

// DEFINIÇÕES E VARIÁVEIS GLOBAIS
#define HASH_TABLE_SIZE 101
#define MAX_ESCOPOS 50
#define MAX_ROTULOS_PILHA 100
#define MAX_CASES 100 // NOVO: Para o switch

int rotulo_count = 1;
int temp_count = 1;

// NOVO: Variáveis para controle do SWITCH
int temp_id_switch_expr = -1; // Armazena o ID do temporário da expressão do switch
int rotulo_default = -1;      // Armazena o rótulo do bloco default
int num_cases = 0;            // Contador de cases dentro de um switch

// ESTRUTURAS DE DADOS
typedef struct Simbolo {
    char nome[50];
    char tipo[10];
    int temp_id;
    int tamanho; // Mantido do seu arquivo original
    struct Simbolo *next;
} Simbolo;

// NOVO: Estrutura para armazenar informações de cada CASE
typedef struct {
    int valor_case;
    int rotulo;
} CaseInfo;

CaseInfo lista_cases[MAX_CASES]; // Array para guardar os cases

typedef struct TabelaDeSimbolos {
    Simbolo* tabela[HASH_TABLE_SIZE];
} TabelaDeSimbolos;

TabelaDeSimbolos* pilha_de_tabelas[MAX_ESCOPOS];
int nivel_escopo_atual = -1;

typedef struct CodegenDecl {
    char definicao[100];
    struct CodegenDecl *next;
} CodegenDecl;

typedef struct CodegenOp {
    char instrucao[200];
    struct CodegenOp *next;
} CodegenOp;

CodegenDecl *head_declaracoes_cg = NULL;
CodegenDecl *tail_declaracoes_cg = NULL;
CodegenOp *head_operacoes_cg = NULL;
CodegenOp *tail_operacoes_cg = NULL;

// FUNÇÕES AUXILIARES
int novo_rotulo() {
    return rotulo_count++;
}

int pilha_rotulos[MAX_ROTULOS_PILHA];
int ponteiro_pilha_rotulos = 0;

void push_rotulo(int rotulo) {
    if (ponteiro_pilha_rotulos >= MAX_ROTULOS_PILHA) {
        yyerror("Estouro da pilha de rótulos.");
        exit(EXIT_FAILURE);
    }
    pilha_rotulos[ponteiro_pilha_rotulos++] = rotulo;
}

int pop_rotulo() {
    if (ponteiro_pilha_rotulos <= 0) {
        yyerror("Pilha de rótulos vazia.");
        exit(EXIT_FAILURE);
    }
    return pilha_rotulos[--ponteiro_pilha_rotulos];
}

// Funções de Geração de Código (CG), Tabela de Símbolos, etc.
// (Mantidas do seu arquivo original, sem alterações significativas aqui)

void inicializar_listas_cg() {
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

void adicionar_declaracao_cg(const char* tipo, const char* nome_cg, int tamanho) {
    char buffer[150];
    if (strcmp(tipo, "string") == 0) {
        sprintf(buffer, "char %s[%d];", nome_cg, tamanho);
    } else {
        sprintf(buffer, "%s %s;", tipo, nome_cg);
    }
    
    CodegenDecl *novo = (CodegenDecl*)malloc(sizeof(CodegenDecl));
    if (!novo) { yyerror("Falha ao alocar memória para declaração CG"); exit(EXIT_FAILURE); }
    strncpy(novo->definicao, buffer, sizeof(novo->definicao) - 1);
    novo->definicao[sizeof(novo->definicao) - 1] = '\0';
    novo->next = NULL;
    if (tail_declaracoes_cg) {
        tail_declaracoes_cg->next = novo;
    } else {
        head_declaracoes_cg = novo;
    }
    tail_declaracoes_cg = novo;
}

void adicionar_operacao_cg(const char* formato, ...) {
    char buffer[200];
    va_list args;
    va_start(args, formato);
    vsnprintf(buffer, sizeof(buffer), formato, args);
    va_end(args);
    CodegenOp *novo = (CodegenOp*)malloc(sizeof(CodegenOp));
    if (!novo) { yyerror("Falha ao alocar memória para operação CG"); exit(EXIT_FAILURE); }
    strncpy(novo->instrucao, buffer, sizeof(novo->instrucao) - 1);
    novo->instrucao[sizeof(novo->instrucao) - 1] = '\0';
    novo->next = NULL;
    if (tail_operacoes_cg) {
        tail_operacoes_cg->next = novo;
    } else {
        head_operacoes_cg = novo;
    }
    tail_operacoes_cg = novo;
}

void imprimir_codigo_cg() {
    CodegenDecl *decl = head_declaracoes_cg;
    while (decl) {
        printf("    %s\n", decl->definicao);
        decl = decl->next;
    }
    if (head_declaracoes_cg && head_operacoes_cg) {
        printf("\n");
    }
    CodegenOp *op = head_operacoes_cg;
    while (op) {
        printf("    %s\n", op->instrucao);
        op = op->next;
    }
}

void liberar_listas_cg() {
    inicializar_listas_cg();
}

unsigned int calcular_hash(char *nome) {
    unsigned int hash_val = 0;
    while (*nome) { hash_val = (hash_val << 5) + *nome++; }
    return hash_val % HASH_TABLE_SIZE;
}

void entrar_escopo() {
    if (nivel_escopo_atual >= MAX_ESCOPOS - 1) {
        yyerror("Limite de aninhamento de escopo excedido.");
        exit(EXIT_FAILURE);
    }
    nivel_escopo_atual++;
    pilha_de_tabelas[nivel_escopo_atual] = (TabelaDeSimbolos*)malloc(sizeof(TabelaDeSimbolos));
    if (!pilha_de_tabelas[nivel_escopo_atual]) {
        yyerror("Falha ao alocar memória para novo escopo.");
        exit(EXIT_FAILURE);
    }
    for (int i = 0; i < HASH_TABLE_SIZE; i++) {
        pilha_de_tabelas[nivel_escopo_atual]->tabela[i] = NULL;
    }
}

void sair_escopo() {
    if (nivel_escopo_atual < 0) return;
    TabelaDeSimbolos* tabela_atual = pilha_de_tabelas[nivel_escopo_atual];
    for (int i = 0; i < HASH_TABLE_SIZE; i++) {
        Simbolo *atual = tabela_atual->tabela[i];
        while (atual != NULL) {
            Simbolo *proximo = atual->next;
            free(atual);
            atual = proximo;
        }
    }
    free(tabela_atual);
    pilha_de_tabelas[nivel_escopo_atual] = NULL;
    nivel_escopo_atual--;
}

int adicionar_simbolo(char *nome, char *tipo, int tamanho) {
    if (nivel_escopo_atual < 0) {
        yyerror("Tentativa de adicionar símbolo fora de qualquer escopo.");
        return -1;
    }
    unsigned int indice = calcular_hash(nome);
    TabelaDeSimbolos* tabela_atual = pilha_de_tabelas[nivel_escopo_atual];
    Simbolo *simbolo_existente = tabela_atual->tabela[indice];
    while (simbolo_existente != NULL) {
        if (strcmp(simbolo_existente->nome, nome) == 0) {
            char error_msg[100];
            sprintf(error_msg, "Variável '%s' redeclarada no mesmo escopo.", nome);
            yyerror(error_msg);
            if (nome) free(nome);
            if (tipo) free(tipo);
            YYABORT;
        }
        simbolo_existente = simbolo_existente->next;
    }
    Simbolo *novo_simbolo = (Simbolo*) malloc(sizeof(Simbolo));
    if (!novo_simbolo) { yyerror("Falha ao alocar memória para novo símbolo."); exit(EXIT_FAILURE); }
    strcpy(novo_simbolo->nome, nome);
    strcpy(novo_simbolo->tipo, tipo);
    novo_simbolo->tamanho = tamanho;
    novo_simbolo->temp_id = temp_count++;
    novo_simbolo->next = tabela_atual->tabela[indice];
    tabela_atual->tabela[indice] = novo_simbolo;
    return novo_simbolo->temp_id;
}

Simbolo* obter_simbolo(char *nome) {
    for (int i = nivel_escopo_atual; i >= 0; i--) {
        unsigned int indice = calcular_hash(nome);
        TabelaDeSimbolos* tabela = pilha_de_tabelas[i];
        Simbolo *atual = tabela->tabela[indice];
        while (atual != NULL) {
            if (strcmp(atual->nome, nome) == 0) {
                return atual;
            }
            atual = atual->next;
        }
    }
    return NULL;
}

void yyerror(const char *s) {
    fprintf(stderr, "Erro Sintático/Semântico: %s\n", s);
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
        char str_val[256];
    } expr_attr;
}

// SEÇÃO DE TOKENS
%token <str> INCLUDE_DIRECTIVE
%token KWD_MAIN KWD_RETURN
%token KWD_IF KWD_ELSE KWD_PRINTF KWD_SCANF KWD_WHILE KWD_DO
%token KWD_STRING
%token <str> STRING_LITERAL
%token AMPERSAND
%token ABRE_CHAVE FECHA_CHAVE ABRE_COL FECHA_COL
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

// NOVOS TOKENS ADICIONADOS
%token KWD_SWITCH KWD_CASE KWD_DEFAULT
%token KWD_BREAK KWD_CONTINUE


%right NEG
%left OU E IGUAL DIFERENTE MENOR MAIOR MENORIGUAL MAIORIGUAL
%left MAIS MENOS
%left VEZES DIV

%type <expr_attr> expr fator

%%

// SEÇÃO DE REGRAS DA GRAMÁTICA
programa:
    includes_opt definicao_main
    ;

includes_opt:
    | includes_opt include_stmt
    ;

include_stmt:
    INCLUDE_DIRECTIVE { printf("%s\n", $1); if ($1) free($1); }
    ;

definicao_main:
    TIPO KWD_MAIN ABRE_P FECHA_P {
        printf("int main() \n{\n");
        if ($1) free($1);
    }
    bloco {
        imprimir_codigo_cg();
        printf("}\n");
    }
    ;

bloco:
    ABRE_CHAVE { entrar_escopo(); }
    lista_comandos_opt
    FECHA_CHAVE { sair_escopo(); }
    ;

lista_comandos_opt:
    | lista_comandos
    ;

lista_comandos:
    lista_comandos comando
    | comando
    ;

// REGRA 'comando' ATUALIZADA
comando:
    decl
    | string_decl
    | atribuicao
    | retorno_main
    | if_stmt
    | while_stmt
    | do_while_stmt        
    | printf_stmt
    | scanf_stmt
    | expr ';'
    | bloco
    | switch_stmt   // NOVO
    | break_stmt    // NOVO
    | continue_stmt // NOVO
    ;

printf_stmt:
    KWD_PRINTF ABRE_P STRING_LITERAL FECHA_P ';' {
        char codigo_gerado[300];
        snprintf(codigo_gerado, sizeof(codigo_gerado), "printf(\"%s\");", $3);
        adicionar_operacao_cg("%s", codigo_gerado);
        if ($3) free($3);
    }
    ;

scanf_stmt:
    KWD_SCANF ABRE_P STRING_LITERAL ',' AMPERSAND ID FECHA_P ';' {
        Simbolo* s = obter_simbolo($6);
        if (!s) {
            char error_msg[100];
            sprintf(error_msg, "Variável '%s' não declarada usada no scanf.", $6);
            yyerror(error_msg);
            if ($6) free($6);
            YYABORT;
        }
        char format_str_cg[256];
        sprintf(format_str_cg, "\"%s\"", $3);
        char var_addr_cg[70];
        sprintf(var_addr_cg, "&%s_T%d", s->nome, s->temp_id);
        adicionar_operacao_cg("param %s;", format_str_cg);
        adicionar_operacao_cg("param %s;", var_addr_cg);
        adicionar_operacao_cg("call scanf, 2;");
        if ($3) free($3);
        if ($6) free($6);
    }
    ;
    
if_stmt:
    KWD_IF ABRE_P expr FECHA_P {
        if (strcmp($3.tipo, "bool") != 0) {
            yyerror("A expressao em um 'if' deve ser do tipo booleano.");
            YYABORT;
        }
        int rotulo_saida = novo_rotulo();
        adicionar_operacao_cg("if_false T%d goto L%d;", $3.temp_id, rotulo_saida);
        push_rotulo(rotulo_saida);
    }
    bloco opt_else
    ;

opt_else:
    {
        int rotulo_saida = pop_rotulo();
        adicionar_operacao_cg("L%d:", rotulo_saida);
    }
    |
    KWD_ELSE {
        int rotulo_fim = novo_rotulo();
        adicionar_operacao_cg("goto L%d;", rotulo_fim);
        int rotulo_else = pop_rotulo();
        adicionar_operacao_cg("L%d:", rotulo_else);
        push_rotulo(rotulo_fim);
    }
    bloco {
        int rotulo_fim = pop_rotulo();
        adicionar_operacao_cg("L%d:", rotulo_fim);
    }
    ;

while_stmt:
    KWD_WHILE ABRE_P expr FECHA_P {
        if (strcmp($3.tipo, "bool") != 0) {
            yyerror("A expressão do while deve ser booleana.");
            YYABORT;
        }
        int rotulo_inicio = novo_rotulo();
        int rotulo_saida = novo_rotulo();
        adicionar_operacao_cg("L%d:", rotulo_inicio);
        adicionar_operacao_cg("if_false T%d goto L%d;", $3.temp_id, rotulo_saida);
        push_rotulo(rotulo_inicio); // Para o continue
        push_rotulo(rotulo_saida);  // Para o break
    }
    bloco {
        int rotulo_saida = pop_rotulo();
        int rotulo_inicio = pop_rotulo();
        adicionar_operacao_cg("goto L%d;", rotulo_inicio);
        adicionar_operacao_cg("L%d:", rotulo_saida);
    }
    ;

do_while_stmt:
    KWD_DO {
        int rotulo_inicio = novo_rotulo();
        adicionar_operacao_cg("L%d:", rotulo_inicio);
        push_rotulo(rotulo_inicio);
    }
    bloco KWD_WHILE ABRE_P expr FECHA_P ';'
    {
        if (strcmp($6.tipo, "bool") != 0) {
            yyerror("A expressão do do/while deve ser booleana.");
            YYABORT;
        }
        int rotulo_inicio = pop_rotulo();
        adicionar_operacao_cg("if_true T%d goto L%d;", $6.temp_id, rotulo_inicio);
    }
    ;

// NOVAS REGRAS PARA SWITCH, BREAK, CONTINUE
switch_stmt:
    KWD_SWITCH ABRE_P expr FECHA_P {
        // Validação: a expressão do switch deve ser um inteiro
        if (strcmp($3.tipo, "int") != 0) {
            yyerror("A expressão do switch deve ser do tipo 'int'.");
            YYABORT;
        }
        int rotulo_fim_switch = novo_rotulo();
        temp_id_switch_expr = $3.temp_id; // Salva o ID da expressão
        num_cases = 0;                    // Reseta o contador de cases
        rotulo_default = -1;              // Reseta o rótulo do default
        push_rotulo(rotulo_fim_switch);   // Empilha o rótulo de saída para o break
    }
    ABRE_CHAVE 
    // Corpo do switch (processado em duas partes)
    {
        // Parte 1: Gera a tabela de saltos ANTES de processar os blocos de código
        adicionar_operacao_cg("// Tabela de saltos do Switch");
    }
    case_list default_case_opt 
    {
        // Parte 2: Após ler todos os cases, gera os saltos condicionais
        for (int i = 0; i < num_cases; i++) {
            adicionar_operacao_cg("if T%d == %d goto L%d;", temp_id_switch_expr, lista_cases[i].valor_case, lista_cases[i].rotulo);
        }
        
        // Se houver um default, salta para ele. Senão, sai do switch.
        if (rotulo_default != -1) {
            adicionar_operacao_cg("goto L%d;", rotulo_default);
        } else {
            int rotulo_fim_switch = pilha_rotulos[ponteiro_pilha_rotulos - 1];
            adicionar_operacao_cg("goto L%d;", rotulo_fim_switch);
        }
        adicionar_operacao_cg("// Fim da tabela de saltos");
    }
    // O código dos blocos dos cases é gerado aqui no meio pela regra 'case_list'
    FECHA_CHAVE 
    {
        // Gera o rótulo final para onde os breaks desviam
        int rotulo_fim_switch = pop_rotulo();
        adicionar_operacao_cg("L%d: // Fim do Switch", rotulo_fim_switch);

        // Limpa as variáveis globais do switch para o próximo
        temp_id_switch_expr = -1;
        rotulo_default = -1;
        num_cases = 0;
    }
    ;

case_list:
    /* Vazio */
    | case_list case_stmt
    ;

case_stmt:
    KWD_CASE NUM ':' {
        int rotulo_case = novo_rotulo();
        if (num_cases < MAX_CASES) {
            lista_cases[num_cases].valor_case = $2;
            lista_cases[num_cases].rotulo = rotulo_case;
            num_cases++;
        } else {
            yyerror("Número máximo de 'case' excedido.");
            YYABORT;
        }
        adicionar_operacao_cg("L%d: // Case %d", rotulo_case, $2);
    }
    lista_comandos_opt
    ;

default_case_opt:
    /* Vazio */
    | KWD_DEFAULT ':' {
        rotulo_default = novo_rotulo();
        adicionar_operacao_cg("L%d: // Default", rotulo_default);
    }
    lista_comandos_opt
    ;

break_stmt:
    KWD_BREAK ';' {
        if (ponteiro_pilha_rotulos < 1) {
            yyerror("'break' fora de um laço ou switch.");
            YYABORT;
        }
        // O rótulo de saída é sempre o último empilhado pelo while, do-while ou switch
        int rotulo_saida = pilha_rotulos[ponteiro_pilha_rotulos - 1];
        adicionar_operacao_cg("goto L%d; // break", rotulo_saida);
    }
    ;

continue_stmt:
    KWD_CONTINUE ';' {
        // Para 'continue' funcionar, precisa haver pelo menos 2 rótulos na pilha
        // (início e fim do laço). O switch só empilha 1.
        if (ponteiro_pilha_rotulos < 2) {
            yyerror("'continue' fora de um laço (while, do-while).");
            YYABORT;
        }
        // O rótulo de início do laço é o penúltimo empilhado.
        int rotulo_inicio = pilha_rotulos[ponteiro_pilha_rotulos - 2];
        adicionar_operacao_cg("goto L%d; // continue", rotulo_inicio);
    }
    ;


retorno_main:
    KWD_RETURN NUM ';' { adicionar_operacao_cg("return %d;", $2); }
    ;

decl:
    TIPO ID ';' {
        int id_temp = adicionar_simbolo($2, $1, 0);
        char nome_var_formatado[60];
        sprintf(nome_var_formatado, "%s_T%d", $2, id_temp);
        adicionar_declaracao_cg($1, nome_var_formatado, 0);
        if ($1) free($1); if ($2) free($2);
    }
    ;

string_decl:
    KWD_STRING ID ABRE_COL NUM FECHA_COL ';' {
        int id_temp = adicionar_simbolo($2, "string", $4);
        char nome_var_formatado[80];
        sprintf(nome_var_formatado, "%s_T%d", $2, id_temp);
        adicionar_declaracao_cg("string", nome_var_formatado, $4);
        if ($2) free($2);
    }
    ;

atribuicao:
    ID ATRIB expr ';' {
        Simbolo* s = obter_simbolo($1);
        if (!s) {
            yyerror("Variável não declarada."); YYABORT;
        }
        
        if (strcmp(s->tipo, "string") == 0) {
            if (strcmp($3.tipo, "string_literal") != 0) {
                yyerror("Atribuição para string só pode ser feita com um literal de string \"...\".");
                YYABORT;
            }
            if (strlen($3.str_val) >= s->tamanho) {
                char error_msg[450];
                snprintf(error_msg, sizeof(error_msg), "Erro: O texto \"%s\" (%zu chars) é grande demais para a variável '%s'[%d].", $3.str_val, strlen($3.str_val), s->nome, s->tamanho);
                yyerror(error_msg);
                YYABORT;
            }
            char var_name_cg[70];
            sprintf(var_name_cg, "%s_T%d", s->nome, s->temp_id);
            adicionar_operacao_cg("strcpy(%s, \"%s\");", var_name_cg, $3.str_val);
        } else {
            char var_name_cg[60];
            sprintf(var_name_cg, "%s_T%d", s->nome, s->temp_id);
            int expr_temp_id = $3.temp_id;
            char expr_tipo[10];
            strcpy(expr_tipo, $3.tipo);
            if (strcmp(s->tipo, "float") == 0 && strcmp(expr_tipo, "int") == 0) {
                int novo_temp_cast = temp_count++;
                char nome_novo_temp_cast_cg[10]; sprintf(nome_novo_temp_cast_cg, "T%d", novo_temp_cast);
                adicionar_declaracao_cg("float", nome_novo_temp_cast_cg, 0);
                adicionar_operacao_cg("T%d = (float) T%d;", novo_temp_cast, expr_temp_id);
                expr_temp_id = novo_temp_cast;
            }
            adicionar_operacao_cg("%s = T%d;", var_name_cg, expr_temp_id);
        }
        if ($1) free($1);
    }
    ;

// As regras para 'expr' e 'fator' permanecem as mesmas do seu arquivo original.
// ... (código de expr e fator omitido para brevidade, mas deve ser incluído aqui) ...

expr:
    expr MAIS expr {
        int res = temp_count++; char tipo_res[10];
        int id1 = $1.temp_id; char tipo1[10]; strcpy(tipo1, $1.tipo);
        int id3 = $3.temp_id; char tipo3[10]; strcpy(tipo3, $3.tipo);
        char nome_temp_res[10]; sprintf(nome_temp_res, "T%d", res);
        if (strcmp(tipo1, "float") == 0 && strcmp(tipo3, "int") == 0) {
            int conv_temp = temp_count++; char nome_conv_temp[10]; sprintf(nome_conv_temp, "T%d", conv_temp);
            adicionar_declaracao_cg("float", nome_conv_temp, 0);
            adicionar_operacao_cg("T%d = (float) T%d;", conv_temp, id3);
            id3 = conv_temp; strcpy(tipo3, "float");
        } else if (strcmp(tipo1, "int") == 0 && strcmp(tipo3, "float") == 0) {
            int conv_temp = temp_count++; char nome_conv_temp[10]; sprintf(nome_conv_temp, "T%d", conv_temp);
            adicionar_declaracao_cg("float", nome_conv_temp, 0);
            adicionar_operacao_cg("T%d = (float) T%d;", conv_temp, id1);
            id1 = conv_temp; strcpy(tipo1, "float");
        }
        if (strcmp(tipo1, "float") == 0 || strcmp(tipo3, "float") == 0) strcpy(tipo_res, "float");
        else strcpy(tipo_res, "int");
        adicionar_declaracao_cg(tipo_res, nome_temp_res, 0);
        adicionar_operacao_cg("T%d = T%d + T%d;", res, id1, id3);
        $$.temp_id = res; strcpy($$.tipo, tipo_res);
    }
    | expr MENOS expr {
        int res = temp_count++; char tipo_res[10];
        int id1 = $1.temp_id; char tipo1[10]; strcpy(tipo1, $1.tipo);
        int id3 = $3.temp_id; char tipo3[10]; strcpy(tipo3, $3.tipo);
        char nome_temp_res[10]; sprintf(nome_temp_res, "T%d", res);
        if (strcmp(tipo1, "float") == 0 && strcmp(tipo3, "int") == 0) {
            int conv_temp = temp_count++; char nct[10];
            sprintf(nct, "T%d", conv_temp);
            adicionar_declaracao_cg("float", nct, 0);
            adicionar_operacao_cg("T%d = (float) T%d;", conv_temp, id3);
            id3 = conv_temp;
            strcpy(tipo3, "float");
        }
        else if (strcmp(tipo1, "int") == 0 && strcmp(tipo3, "float") == 0) {
            int conv_temp = temp_count++; char nct[10]; sprintf(nct, "T%d", conv_temp);
            adicionar_declaracao_cg("float", nct, 0);
            adicionar_operacao_cg("T%d = (float) T%d;", conv_temp, id1);
            id1 = conv_temp; strcpy(tipo1, "float");
        }
        if (strcmp(tipo1, "float") == 0 || strcmp(tipo3, "float") == 0){
            strcpy(tipo_res, "float");
        }
        else {
            strcpy(tipo_res, "int");
        }
        adicionar_declaracao_cg(tipo_res, nome_temp_res, 0);
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
            int conv_temp = temp_count++; char nct[10]; sprintf(nct, "T%d", conv_temp);
            adicionar_declaracao_cg("float", nct, 0);
            adicionar_operacao_cg("T%d = (float) T%d;", conv_temp, id3);
            id3 = conv_temp; strcpy(tipo3, "float");
        }
        else if (strcmp(tipo1, "int") == 0 && strcmp(tipo3, "float") == 0) {
            int conv_temp = temp_count++; char nct[10];
            sprintf(nct, "T%d", conv_temp);
            adicionar_declaracao_cg("float", nct, 0);
            adicionar_operacao_cg("T%d = (float) T%d;", conv_temp, id1);
            id1 = conv_temp; strcpy(tipo1, "float");
        }
        if (strcmp(tipo1, "float") == 0 || strcmp(tipo3, "float") == 0) {
            strcpy(tipo_res, "float");
        }
        else {
            strcpy(tipo_res, "int");
        }
        adicionar_declaracao_cg(tipo_res, nome_temp_res, 0);
        adicionar_operacao_cg("T%d = T%d * T%d;", res, id1, id3);
        $$.temp_id = res; strcpy($$.tipo, tipo_res);
    }
    | expr DIV expr {
        int res = temp_count++; char tipo_res[10];
        int id1 = $1.temp_id; char tipo1[10];
        strcpy(tipo1, $1.tipo);
        int id3 = $3.temp_id; char tipo3[10];
        strcpy(tipo3, $3.tipo);
        char nome_temp_res[10]; sprintf(nome_temp_res, "T%d", res);
        if (strcmp(tipo1, "float") == 0 && strcmp(tipo3, "int") == 0) {
            int conv_temp = temp_count++; char nct[10];
            sprintf(nct, "T%d", conv_temp);
            adicionar_declaracao_cg("float", nct, 0);
            adicionar_operacao_cg("T%d = (float) T%d;", conv_temp, id3);
            id3 = conv_temp; strcpy(tipo3, "float");
        }
        else if (strcmp(tipo1, "int") == 0 && strcmp(tipo3, "float") == 0) {
            int conv_temp = temp_count++; char nct[10]; sprintf(nct, "T%d", conv_temp);
            adicionar_declaracao_cg("float", nct, 0);
            adicionar_operacao_cg("T%d = (float) T%d;", conv_temp, id1);
            id1 = conv_temp; strcpy(tipo1, "float");
        }
        if (strcmp(tipo1, "float") == 0 || strcmp(tipo3, "float") == 0) {
            strcpy(tipo_res, "float");
        }
        else {
            strcpy(tipo_res, "int");
        }
        adicionar_declaracao_cg(tipo_res, nome_temp_res, 0);
        adicionar_operacao_cg("T%d = T%d / T%d;", res, id1, id3);
        $$.temp_id = res;
        strcpy($$.tipo, tipo_res);
    }
    | expr IGUAL expr {
        int res = temp_count++;
        char nome_temp_res[10]; sprintf(nome_temp_res, "T%d", res);
        if (strcmp($1.tipo, "string") == 0 || strcmp($1.tipo, "string_literal") == 0 ||
            strcmp($3.tipo, "string") == 0 || strcmp($3.tipo, "string_literal") == 0) {
            
            char op1_str[300], op2_str[300];
            Simbolo* s1 = obter_simbolo($1.nome);
            Simbolo* s2 = obter_simbolo($3.nome);

            if (strcmp($1.tipo, "string_literal") == 0) {
                snprintf(op1_str, sizeof(op1_str), "\"%s\"", $1.str_val);
            } else if (s1 && strcmp(s1->tipo, "string") == 0) {
                snprintf(op1_str, sizeof(op1_str), "%s_T%d", s1->nome, s1->temp_id);
            }

            if (strcmp($3.tipo, "string_literal") == 0) {
                snprintf(op2_str, sizeof(op2_str), "\"%s\"", $3.str_val);
            } else if (s2 && strcmp(s2->tipo, "string") == 0) {
                snprintf(op2_str, sizeof(op2_str), "%s_T%d", s2->nome, s2->temp_id);
            }

            adicionar_declaracao_cg("bool", nome_temp_res, 0);
            adicionar_operacao_cg("T%d = (strcmp(%s, %s) == 0);", res, op1_str, op2_str);
        
        } else {
            adicionar_declaracao_cg("bool", nome_temp_res, 0);
            adicionar_operacao_cg("T%d = T%d == T%d;", res, $1.temp_id, $3.temp_id);
        }

        $$.temp_id = res;
        strcpy($$.tipo, "bool");
    }
    | expr DIFERENTE expr {
        int res = temp_count++; char nt[10]; sprintf(nt, "T%d", res);
        adicionar_declaracao_cg("bool", nt, 0);
        adicionar_operacao_cg("T%d = T%d != T%d;", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res; strcpy($$.tipo, "bool");
    }
    | expr MENOR expr {
        int res = temp_count++; char nt[10]; sprintf(nt, "T%d", res);
        adicionar_declaracao_cg("bool", nt, 0);
        adicionar_operacao_cg("T%d = T%d < T%d;", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res; strcpy($$.tipo, "bool");
    }
    | expr MAIOR expr {
        int res = temp_count++; char nt[10]; sprintf(nt, "T%d", res);
         adicionar_declaracao_cg("bool", nt, 0);
         adicionar_operacao_cg("T%d = T%d > T%d;", res, $1.temp_id, $3.temp_id);
         $$.temp_id = res; strcpy($$.tipo, "bool");
    }
    | expr MENORIGUAL expr {
        int res = temp_count++; char nt[10]; sprintf(nt, "T%d", res);
        adicionar_declaracao_cg("bool", nt, 0);
        adicionar_operacao_cg("T%d = T%d <= T%d;", res, $1.temp_id, $3.temp_id);
         $$.temp_id = res; strcpy($$.tipo, "bool");
    }
    | expr MAIORIGUAL expr {
        int res = temp_count++; char nt[10]; sprintf(nt, "T%d", res);
        adicionar_declaracao_cg("bool", nt, 0);
         adicionar_operacao_cg("T%d = T%d >= T%d;", res, $1.temp_id, $3.temp_id);
         $$.temp_id = res; strcpy($$.tipo, "bool");
    }
    | expr E expr {
        int res = temp_count++; char nt[10]; sprintf(nt, "T%d", res);
        adicionar_declaracao_cg("bool", nt, 0);
         adicionar_operacao_cg("T%d = T%d && T%d;", res, $1.temp_id, $3.temp_id);
         $$.temp_id = res; strcpy($$.tipo, "bool");
    }
    | expr OU expr {
        int res = temp_count++; char nt[10]; sprintf(nt, "T%d", res);
        adicionar_declaracao_cg("bool", nt, 0);
        adicionar_operacao_cg("T%d = T%d || T%d;", res, $1.temp_id, $3.temp_id);
        $$.temp_id = res; strcpy($$.tipo, "bool");
    }
    | NEG expr {
        int res = temp_count++; char nt[10]; sprintf(nt, "T%d", res);
        adicionar_declaracao_cg("bool", nt, 0);
        adicionar_operacao_cg("T%d = !T%d;", res, $2.temp_id);
        $$.temp_id = res;
        strcpy($$.tipo, "bool");
    }
    | fator
    ;

fator:
    ABRE_P expr FECHA_P { $$.temp_id = $2.temp_id; strcpy($$.tipo, $2.tipo); }
    |
    ABRE_P TIPO FECHA_P fator {
        int res = temp_count++;
        char nome_temp_res[10];
        sprintf(nome_temp_res, "T%d", res);
        adicionar_declaracao_cg($2, nome_temp_res, 0);
        adicionar_operacao_cg("T%d = (%s) T%d;", res, $2, $4.temp_id);
        $$.temp_id = res; strcpy($$.tipo, $2);
        if ($2) free($2);
    }
    | NUM {
        int res = temp_count++;
        char nome_temp_res[10]; sprintf(nome_temp_res, "T%d", res);
        adicionar_declaracao_cg("int", nome_temp_res, 0);
        adicionar_operacao_cg("T%d = %d;", res, $1);
        $$.temp_id = res; strcpy($$.tipo, "int");
    }
    | FNUM {
        int res = temp_count++; char nome_temp_res[10];
        sprintf(nome_temp_res, "T%d", res);
        adicionar_declaracao_cg("float", nome_temp_res, 0);
        adicionar_operacao_cg("T%d = %.2f;", res, $1);
        $$.temp_id = res; strcpy($$.tipo, "float");
    }
    | CARACTERE {
        int res = temp_count++; char nome_temp_res[10];
        sprintf(nome_temp_res, "T%d", res);
        adicionar_declaracao_cg("char", nome_temp_res, 0);
        adicionar_operacao_cg("T%d = %s;", res, $1);
        $$.temp_id = res;
        strcpy($$.tipo, "char");
        if ($1) free($1);
    }
    | BOOLLIT {
        int res = temp_count++; char nome_temp_res[10];
        sprintf(nome_temp_res, "T%d", res);
        adicionar_declaracao_cg("bool", nome_temp_res, 0);
        adicionar_operacao_cg("T%d = %s;", res, ($1 ? "true" : "false"));
        $$.temp_id = res; strcpy($$.tipo, "bool");
    }
    | STRING_LITERAL {
        strcpy($$.tipo, "string_literal");
        strcpy($$.str_val, $1);
        $$.temp_id = -1;
        if ($1) free($1);
    }
    |
    ID {
        Simbolo* s = obter_simbolo($1);
        if (!s) {
            yyerror("Variável não declarada."); YYABORT;
        }
        $$.temp_id = s->temp_id; 
        strcpy($$.tipo, s->tipo); 
        strcpy($$.nome, s->nome);
        if ($1) free($1);
    }
    ;

%%

int main(int argc, char* argv[]) {
    if (argc > 1) {
        FILE *file = fopen(argv[1], "r");
        if (!file) {
            perror("Não foi possível abrir o arquivo");
            return 1;
        }
        extern FILE *yyin;
        yyin = file;
    }
    
    inicializar_listas_cg();
    yyparse();
    liberar_listas_cg();
    return 0;
}