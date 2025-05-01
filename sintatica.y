%{
#include <iostream>
#include <string>
#include <sstream>
#include <cstdlib>

#define YYSTYPE atributos

using namespace std;

struct atributos {
	string label;
	string traducao;
};

int yylex(void);
void yyerror(string msg);
%}

// Tokens importados do léxico
%token NUM_INT NUM_DEC STRING IDENT
%token INTEIRO FLUTUANTE BOOLEANO CARACTERE
%token VERDADEIRO FALSO
%token ATRIB MAIS MENOS MULT DIV MOD
%token IGUAL DIFERENTE MENOR MAIOR MENOR_IGUAL MAIOR_IGUAL
%token E_LOGICO OU_LOGICO NAO_LOGICO
%token CONVERTE_PARA COMO
%token PONTO_VIRG ABRE_P FECHA_P ABRE_CH FECHA_CH
%token SE SENAO ENQUANTO PARA RETORNA

%start S

%left OU_LOGICO
%left E_LOGICO
%left IGUAL DIFERENTE
%left MENOR MAIOR MENOR_IGUAL MAIOR_IGUAL
%left MAIS MENOS
%left MULT DIV MOD
%right NAO_LOGICO

%%

S           : BLOCO
            {
                cout << "/* Compilador FOCA */\n";
                cout << "#include <iostream>\nusing namespace std;\nint main() {\n";
                cout << $1.traducao;
                cout << "\treturn 0;\n}\n";
            }
            ;

BLOCO       : ABRE_CH COMANDOS FECHA_CH
            {
                $$.traducao = $2.traducao;
            }
            ;

COMANDOS    : COMANDO COMANDOS
            {
                $$.traducao = $1.traducao + $2.traducao;
            }
            | /* vazio */
            {
                $$.traducao = "";
            }
            ;

COMANDO     : DECLARACAO PONTO_VIRG
            {
                $$.traducao = $1.traducao + ";\n";
            }
            | ATRIBUICAO PONTO_VIRG
            {
                $$.traducao = $1.traducao + ";\n";
            }
            ;

DECLARACAO  : TIPO IDENT
            {
                $$.traducao = "\t" + $1.label + " " + $2.label;
            }
            ;

ATRIBUICAO  : IDENT ATRIB EXPR
            {
                $$.traducao = "\t" + $1.label + " = " + $3.label;
            }
            ;

TIPO        : INTEIRO     { $$.label = "int"; }
            | FLUTUANTE   { $$.label = "float"; }
            | BOOLEANO    { $$.label = "bool"; }
            | CARACTERE   { $$.label = "char"; }
            ;

EXPR        : EXPR MAIS EXPR
            {
                $$.label = $1.label + " + " + $3.label;
            }
            | EXPR MENOS EXPR
            {
                $$.label = $1.label + " - " + $3.label;
            }
            | EXPR MULT EXPR
            {
                $$.label = $1.label + " * " + $3.label;
            }
            | EXPR DIV EXPR
            {
                $$.label = $1.label + " / " + $3.label;
            }
            | EXPR MOD EXPR
            {
                $$.label = $1.label + " % " + $3.label;
            }
            | EXPR IGUAL EXPR
            {
                $$.label = $1.label + " == " + $3.label;
            }
            | EXPR DIFERENTE EXPR
            {
                $$.label = $1.label + " != " + $3.label;
            }
            | EXPR MENOR EXPR
            {
                $$.label = $1.label + " < " + $3.label;
            }
            | EXPR MAIOR EXPR
            {
                $$.label = $1.label + " > " + $3.label;
            }
            | EXPR MENOR_IGUAL EXPR
            {
                $$.label = $1.label + " <= " + $3.label;
            }
            | EXPR MAIOR_IGUAL EXPR
            {
                $$.label = $1.label + " >= " + $3.label;
            }
            | EXPR E_LOGICO EXPR
            {
                $$.label = $1.label + " && " + $3.label;
            }
            | EXPR OU_LOGICO EXPR
            {
                $$.label = $1.label + " || " + $3.label;
            }
            | NAO_LOGICO EXPR
            {
                $$.label = "!" + $2.label;
            }
            | CONVERTE_PARA ABRE_P TIPO FECHA_P EXPR
            {
                $$.label = "(" + $3.label + ") " + $5.label;
            }
            | EXPR COMO TIPO
            {
                $$.label = "(" + $3.label + ") " + $1.label;
            }
            | ABRE_P EXPR FECHA_P
            {
                $$.label = "(" + $2.label + ")";
            }
            | IDENT
            {
                $$.label = $1.label;
            }
            | NUM_INT
            {
                $$.label = yytext;
            }
            | NUM_DEC
            {
                $$.label = yytext;
            }
            | VERDADEIRO
            {
                $$.label = "true";
            }
            | FALSO
            {
                $$.label = "false";
            }
            | STRING
            {
                $$.label = string(yytext);
            }
            ;

%%

#include "lex.yy.c"

int main() {
    return yyparse();
}

void yyerror(string msg) {
    cerr << "Erro sintático: " << msg << endl;
    exit(1);
}
