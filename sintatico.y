%{
#include <iostream>
#include <string>
#include <sstream>
#include <vector>
#include <map>
#include <unordered_map>

#define YYSTYPE atributos

using namespace std;

int var_temp_qnt;
int label_qnt;
string traducaoTemp;

struct atributos
{
	string label;
	string traducao;
	string tipo;
	string tamanho = "";
	string vetor_string = "";
	string literal_value = "";
	bool id = false;
};

struct CaseInfo {
    string constant_value_label;
    string constant_value_type;
    string code_target_label;
	string traducao_exp_case;
};

struct DefaultInfo {
    bool exists = false;
    string code_target_label;
};

struct Simbolo
{
	string label;
	string tipo = "";
	string tamanho = "";
	string vetor_string = "";
	bool tipado = false;
	string rows_label = "";
	string cols_label = "";
	bool is_matrix = false;
};

struct SwitchContext {
    std::vector<CaseInfo> cases; 
    DefaultInfo default_info;
    std::string end_label;
};

/*vetores de declarações das variáveis locais e globais*/
vector<string> declaracoes_locais;
vector<string> declaracoes_globais;
/*variável para saber se estamos no escopo global ainda ou não*/
bool g_processando_escopo_global = true;

// Nova variável global para coletar os valores da lista de inicialização
static vector<vector<atributos>> g_current_matrix_initializer;

static vector<atributos> g_current_flat_initializer;

vector<unordered_map<string, Simbolo>> tabela;
vector<string> rotulo_condicao;
vector<string> rotulo_inicio;
vector<string> rotulo_fim;
vector<string> rotulo_incremento;
static vector<CaseInfo> g_current_switch_cases;
static DefaultInfo g_current_switch_default_info;
static string g_current_switch_end_label;
static vector<SwitchContext> g_switch_context_stack;
vector<string> break_label_stack;
vector<string> continue_label_stack;

map<string, map<string, string>> tipofinal;


void guardaSimbolos(string nome);
void removerEscopo();
void adicionarEscopo();
string genlabel();
void removerRotulos();
void desempilhar_contexto_case();  
void declararVariavel(string tipo, string label, int tam_string);
string cast_implicito(atributos* no1, atributos* no2, atributos* no3, string tipo);
void atualizar(string tipo, string nome, string tamanho, string cadeia_char, string atualiza_label, string rows, string cols, bool matrix);
int tamanho_string(string traducao);
string retirar_aspas(string traducao, int tamanho);
string string_intermediario(string buffer, string tamanho, string cond, string label);
int yylex(void);
void yyerror(string);
string gentempcode();
bool verifica_var(string name);
Simbolo buscar(string name);
string unescape_string(const char* s);



%}

%token KWD_NUM KWD_FLOAT KWD_CHAR KWD_BOOL KWD_RELACIONAL KWD_OU KWD_E KWD_NEG KWD_CAST KWD_VAR KWD_CADEIA_CHAR KWD_TIPO_INPUT KWD_PLUS_EQ KWD_MINUS_EQ KWD_MULT_EQ KWD_DIV_EQ
%token KWD_MAIN KWD_DEF KWD_ID KWD_IF KWD_THEN KWD_ELSE KWD_WHILE KWD_DO KWD_FOR KWD_BREAK KWD_CONTINUE KWD_CPY KWD_CAT KWD_INPUT KWD_OUTPUT KWD_INC KWD_DEC
%token KWD_SWITCH KWD_CASE KWD_DEFAULT
// KWD_FIM KWD_ERROR
%start S

%left KWD_OU
%left KWD_E
%left KWD_RELACIONAL
%left '+' '-'
%left '*' '/'
%right KWD_NEG KWD_INC KWD_DEC
%left '(' ')' KWD_CAST

%%

S 			:LISTA_COMANDOS_GLOBAIS S_MAIN
			{
				string codigo = "#include<stdio.h>\n"
								"#include<stdlib.h>\n"
								"#include<string.h>\n\n";

				for (int i = 0; i < declaracoes_globais.size(); i++) {
					codigo += declaracoes_globais[i];
				}

				codigo += "\nint main() {\n";

				for (int i = 0; i < declaracoes_locais.size(); i++) {
					codigo += declaracoes_locais[i];
				}	

				codigo += "\n" + $1.traducao;

				codigo += "\n" + $2.traducao;
								
				codigo += 	"\n\treturn 0;"
							"\n}";

				cout << codigo << endl;
			}
			;

LISTA_COMANDOS_GLOBAIS :
						{
							$$.traducao = "";
						}
						| LISTA_COMANDOS_GLOBAIS COMANDO_GLOBAL
						{
							$$.traducao = $1.traducao + $2.traducao;
						}
						;

S_MAIN : KWD_DEF KWD_MAIN
		{
			g_processando_escopo_global = false;
		}
		BLOCO
		{
			$$ = $4;
		}
		;
COMANDO_GLOBAL : DEC ';'
				{

				}
				| ATRI ';'
				{

				}
				;
BLOCO		: '{'{ adicionarEscopo();} COMANDOS '}'
			{
				$$.traducao = $3.traducao;
				removerEscopo();
			}
			;
COMANDOS	: COMANDO COMANDOS
			{
				$$.traducao = $1.traducao + $2.traducao;
			}
			|
			{
				$$.traducao = "";
			}
			;
CRIAR_ROTULOS		:
					{
						rotulo_inicio.push_back(genlabel());
						rotulo_condicao.push_back(genlabel());
						rotulo_fim.push_back(genlabel());
						rotulo_incremento.push_back(genlabel());

						break_label_stack.push_back(rotulo_fim.back());
						continue_label_stack.push_back(rotulo_condicao.back());

					}
					;
RETIRAR_ROTULOS :
                {
                    if (!continue_label_stack.empty()) {
                        continue_label_stack.pop_back();
                    } else {
                        yyerror("Pilha continue vazia no cleanup");
                    }
                    
					if (!break_label_stack.empty()) {
                        break_label_stack.pop_back();
                    } else {
                        yyerror("Pilha break vazia no cleanup");
                    }

                }
                ;

CRIAR_ROTULOS_FOR 	:
            		{
        				rotulo_condicao.push_back(genlabel());
        				rotulo_incremento.push_back(genlabel());
        				rotulo_fim.push_back(genlabel());
						rotulo_inicio.push_back(genlabel());

        				break_label_stack.push_back(rotulo_fim.back());
        				continue_label_stack.push_back(rotulo_incremento.back());
                    }
                    ;

COMANDO 	: E ';'
			{
				$$ = $1;
			}
			| ATRI ';'
			| DEC ';'
			| BLOCO
			| KWD_IF '(' E ')' KWD_THEN BLOCO
			{
                if($3.tipo != "bool") {
                    yyerror("A expressao condicional 'if' deve ser do tipo booleano.");
                }

                string temp_negated_expr = gentempcode();
                declararVariavel("bool", temp_negated_expr, -1);

                string fim_label = genlabel();
                $$.traducao = $3.traducao; 
                $$.traducao += "\t" + temp_negated_expr + " = !" + $3.label + ";\n";
                $$.traducao += string("\t") + "if (" + temp_negated_expr + ") goto " + fim_label + ";\n";
                $$.traducao += $6.traducao;
                $$.traducao += fim_label + ":\n";
                $$.tipo = "";
                $$.label = "";

			}
			| KWD_IF '(' E ')' KWD_THEN BLOCO KWD_ELSE BLOCO
			{
                if($3.tipo != "bool") {
                    yyerror("A expressao condicional 'if' deve ser do tipo booleano.");
                }

                string else_label = genlabel();
                string end_if_label = genlabel();

                string temp_negated_expr = gentempcode();
                declararVariavel("bool", temp_negated_expr, -1);

                $$.traducao = $3.traducao;
                $$.traducao += "\t" + temp_negated_expr + " = !" + $3.label + ";\n";
                $$.traducao += string("\t") + "if (" + temp_negated_expr + ") goto " + else_label + ";\n";
                $$.traducao += $6.traducao;
                $$.traducao += string("\tgoto ") + end_if_label + ";\n";
                $$.traducao += else_label + ":\n";
                $$.traducao += $8.traducao;
                $$.traducao += end_if_label + ":\n";

                $$.tipo = ""; 
                $$.label = "";
			}
			| KWD_WHILE '(' E ')' CRIAR_ROTULOS BLOCO RETIRAR_ROTULOS
			{
                if($3.tipo != "bool") {
                    yyerror("A expressao condicional 'while' deve ser do tipo booleano.");
                }

                string temp_negated_expr = gentempcode();
                declararVariavel("bool", temp_negated_expr, -1);

                $$.traducao = rotulo_condicao.back() + ":\n";
                $$.traducao += $3.traducao;
                $$.traducao += "\t" + temp_negated_expr + " = !" + $3.label + ";\n";
                $$.traducao += string("\t") + "if (" + temp_negated_expr + ") goto " + rotulo_fim.back() + ";\n";
                $$.traducao += $6.traducao;
                $$.traducao += string("\tgoto ") + rotulo_condicao.back() + ";\n";
                $$.traducao += rotulo_fim.back() + ":\n";

				removerRotulos();

                $$.tipo = ""; 
                $$.label = "";
			}
			| KWD_DO CRIAR_ROTULOS BLOCO RETIRAR_ROTULOS KWD_WHILE '(' E ')' ';'
			{
                if($7.tipo != "bool") {
                    yyerror("A expressao condicional 'do-while' deve ser do tipo booleano.");
                }

                $$.traducao = rotulo_inicio.back() + ":\n";
                $$.traducao += $3.traducao;
				$$.traducao += rotulo_condicao.back() + ":\n";
                $$.traducao += $7.traducao;
                $$.traducao += string("\t") + "if (" + $7.label + ") goto " + rotulo_inicio.back() + ";\n";
				$$.traducao += rotulo_fim.back() + ":\n";

				removerRotulos();

                $$.tipo = ""; 
                $$.label = "";
			}
			| KWD_FOR '(' INTERMEDIARIO_FOR ';' E ';' ATRI ')' CRIAR_ROTULOS_FOR BLOCO RETIRAR_ROTULOS
			{
                if($5.tipo != "bool") {
                    yyerror("A expressao de condicao no loop 'for' deve ser do tipo booleano.");
                }

                string temp_negated_cond = gentempcode();
                declararVariavel("bool", temp_negated_cond, -1);

                $$.traducao = $3.traducao;
                $$.traducao += rotulo_condicao.back() + ":\n";
                $$.traducao += $5.traducao;
                $$.traducao += "\t" + temp_negated_cond + " = !" + $5.label + ";\n";
                $$.traducao += string("\t") + "if (" + temp_negated_cond + ") goto " + rotulo_fim.back() + ";\n";
                $$.traducao += $10.traducao;
				$$.traducao += rotulo_incremento.back() + ":\n";
                $$.traducao += $7.traducao;
                $$.traducao += string("\tgoto ") + rotulo_condicao.back() + ";\n";
                $$.traducao += rotulo_fim.back() + ":\n";

				removerRotulos();

                $$.tipo = ""; 
                $$.label = "";
			}
			| KWD_BREAK ';'
			{
				if (break_label_stack.empty()) {
                    yyerror("Comando 'break' utilizado fora de um loop.");
                } else {
                    $$.traducao = string("\tgoto ") + break_label_stack.back() + ";\n";
                }
                
				$$.tipo = ""; 
				$$.label = "";
			}
			| KWD_CONTINUE ';'
			{
				if (continue_label_stack.empty()) {
                    yyerror("Comando 'continue' utilizado fora de um loop.");
                } else {
                    $$.traducao = string("\tgoto ") + continue_label_stack.back() + ";\n";
                }

                $$.tipo = ""; 
				$$.label = "";
			}
			| KWD_SWITCH '(' E ')' SWITCH_SETUP '{' CASE_STATEMENTS_LIST '}' SWITCH_CLEANUP
			{
				if (g_switch_context_stack.empty()) {
                	yyerror("Contexto de switch nao encontrado ao finalizar o switch.");
                	$$.traducao = "";
            	} else {
                	const SwitchContext& current_context = g_switch_context_stack.back();

                	string switch_expr_traducao = $3.traducao;
                	string switch_expr_val_label = $3.label;
                	string switch_expr_tipo = $3.tipo;

                	string dispatch_code;
                	string case_bodies_code = $7.traducao;

                	for (const auto& ci : current_context.cases) {
                    	if (tipofinal[switch_expr_tipo][ci.constant_value_type] == "float" || tipofinal[switch_expr_tipo][ci.constant_value_type] == "erro") {
                        	yyerror("Switch ou case de tipos incompativeis.");
                       	}

                    	string temp_cond = gentempcode();
                        declararVariavel("bool", temp_cond, -1);
					    dispatch_code += ci.traducao_exp_case;
                        dispatch_code += "\t" + temp_cond + " = (" + switch_expr_val_label + " == " + ci.constant_value_label + ");\n";
                        dispatch_code += string("\t") + "if (" + temp_cond + ") goto " + ci.code_target_label + ";\n";
                	}

                	if (current_context.default_info.exists) {
                        dispatch_code += "\tgoto " + current_context.default_info.code_target_label + ";\n";
                	} else {
                        dispatch_code += "\tgoto " + current_context.end_label + ";\n";
                	}

                	$$.traducao = switch_expr_traducao + dispatch_code + case_bodies_code + current_context.end_label + ":\n";

				    desempilhar_contexto_case();
                    $$.tipo = "";
                    $$.label = "";
            	}
        	}
			| KWD_OUTPUT '(' OUTPUT ')' ';' 
            {
                $$.traducao = $3.traducao;
                $$.tipo = "";
                $$.label = "";
            }
			| KWD_ID '=' KWD_INPUT '(' KWD_TIPO_INPUT ')' ';' 
            {
                if(!verifica_var($1.label)) {
                    yyerror("Variavel '" + $1.label + "' nao declarada para input.");
                }

                Simbolo variavel_destino = buscar($1.label);

				if($5.tipo == "string"){
					if (variavel_destino.tipo != "string" && variavel_destino.tipado == true) {
                        yyerror("Variavel '" + $1.label + "' do tipo " + variavel_destino.tipo + " nao pode receber input de string.");
					}
					string tamanho = gentempcode();
					declararVariavel("int", tamanho, -1);
					string buffer = gentempcode();
					declararVariavel("char*", buffer, -1);
					string cond = gentempcode();
					declararVariavel("bool", cond, -1);
					string label = genlabel();
					string temp_ponteiro = gentempcode();

					declararVariavel("char*", temp_ponteiro, -1);
					atualizar("string", $1.label, tamanho, "", temp_ponteiro, "", "", false);

					$$.traducao += "\t" + buffer + " = malloc(256);\n" +
					"\tfgets(" + buffer + ", 256, stdin);\n" +
					string_intermediario(buffer, tamanho, cond, label) +
					"\t" + temp_ponteiro + " = malloc(" + tamanho + ");\n" +
					"\tstrcpy(" + temp_ponteiro + ", " + buffer + ");\n" +
					"\tfree(" + buffer + ");\n";

					$$.label = temp_ponteiro;
				}

				if($5.tipo == "int" || $5.tipo == "float" || $5.tipo == "char"){
					if(variavel_destino.tipo != $5.tipo && variavel_destino.tipado == true){
						yyerror("Variavel '" + $1.label + "' do tipo " + variavel_destino.tipo + " nao pode receber input de " + $5.tipo + ".");
					}

					string var = gentempcode();
					declararVariavel($5.tipo, var, -1);
					$$.traducao += "\tscanf(\"" + $5.label + "\", &" + var + ");\n";

					atualizar($5.tipo, $1.label, "", "", var, "", "", false);
					$$.label = var;
				}

                $$.tipo = $5.tipo;
            }
			| KWD_CAT '(' KWD_ID ',' KWD_ID ')' ';'
			{
				Simbolo simbolo1 = buscar($3.label); 
				Simbolo simbolo2 = buscar($5.label); 

				if (simbolo1.label == simbolo2.label) yyerror("IMpossivel concatenar origem e destino de mesmo endereço.");
				if(tipofinal[simbolo1.tipo][simbolo2.tipo] != "string") {
					yyerror("Concatenacao com tipos inválidos");
				}

				int len1 = stoi(simbolo1.tamanho) - 1; 
				int len2 = stoi(simbolo2.tamanho) - 1; 
				
				int tamcat_total_alocado = len1 + len2 + 1; 
				string cat = simbolo1.vetor_string + simbolo2.vetor_string; 

				string resultado_temp_c_label = gentempcode();

				declararVariavel("char*", resultado_temp_c_label, -1); 

				$$.traducao = ""; 

				$$.traducao += "\t" + resultado_temp_c_label + " = (char*)malloc(" + to_string(tamcat_total_alocado) + ");\n";
				$$.traducao += "\tstrcpy(" + resultado_temp_c_label + ", " + simbolo1.label + ");\n";
				$$.traducao += "\tstrcat(" + resultado_temp_c_label + ", " + simbolo2.label + ");\n";

				$$.tipo = "string";
				$$.tamanho = to_string(tamcat_total_alocado); 

				$$.traducao += "\tfree(" + simbolo1.label + ");\n"; 
				$$.traducao += "\t" + simbolo1.label + " = " + resultado_temp_c_label + ";\n"; 

				atualizar($$.tipo, $3.label, $$.tamanho, cat, simbolo1.label, "", "", false); 
			}
			;
SWITCH_SETUP :
            {
                SwitchContext current_switch_details;
                current_switch_details.end_label = genlabel();
                
                break_label_stack.push_back(current_switch_details.end_label);

                g_switch_context_stack.push_back(current_switch_details);
            }
            ;
SWITCH_CLEANUP :
            {
                if (!break_label_stack.empty()) {
                    break_label_stack.pop_back();
                } else {
                    yyerror("Pilha de break vazia no cleanup do switch");
                }
            }
            ;
			
INTERMEDIARIO_FOR: KWD_ID '=' E
			{
				traducaoTemp = "";

				if(!verifica_var($1.label)) {
					yyerror("Variavel nao declarada.");
				}

				Simbolo variavel;
				variavel = buscar($1.label);

				if(variavel.tipado == false && $3.tipo == "int") {
					atualizar($3.tipo, $1.label, "", "", "", "", "", false);
					declararVariavel($3.tipo, variavel.label, -1);
					variavel.tipo = $3.tipo;
				} else if(variavel.tipado == true){
					yyerror("Variavel no parametro do for já tem um valor atribuido!");
				}

				$$.traducao += $1.traducao + $3.traducao + "\t" + variavel.label + " = " + $3.label + ";\n";
			}
			| KWD_VAR KWD_ID '=' E
			{
				if($4.tipo != "int"){
					yyerror("Tipo incompativel de atribuicao a uma variavel utilizada de parametro no for!");
				}
				if(verifica_var($2.label)) {
                    yyerror("Voce ja declarou essa variavel: " + $2.label);
                }

				guardaSimbolos($2.label);

				$$.label = "";
				$$.traducao = "";
				$$.tipo = "";
				$$.tamanho = "";
				$$.vetor_string = "";

				Simbolo variavel;
				variavel = buscar($2.label);

				if(variavel.tipado == false) {
					atualizar($4.tipo, $2.label, "", "", "", "", "", false);
					declararVariavel($4.tipo, variavel.label, -1);
					variavel.tipo = $4.tipo;
				}

				$2.tipo = variavel.tipo;
				$2.label = variavel.label;

				$$.traducao += $2.traducao + $4.traducao + "\t" + $2.label + " = " + $4.label + ";\n";
				
			};

CASE_STATEMENTS_LIST :
            {
                $$.traducao = "";
            }
            | CASE_STATEMENTS_LIST_NON_EMPTY
            ;
CASE_STATEMENTS_LIST_NON_EMPTY : CASE_OR_DEFAULT_ITEM
            | CASE_STATEMENTS_LIST_NON_EMPTY CASE_OR_DEFAULT_ITEM
            { $$.traducao = $1.traducao + $2.traducao; }
            ;
CASE_OR_DEFAULT_ITEM : CASE_CLAUSE
            | DEFAULT_CLAUSE
            ;

CASE_CLAUSE : KWD_CASE E ':' COMANDOS
            {
                if ($2.tipo != "int" && $2.tipo != "char" && $2.tipo != "bool") {
                    yyerror("Constante do 'case' deve ser do tipo int, char ou bool. Encontrado: " + $2.tipo);
                }

                if (g_switch_context_stack.empty()) {
                    yyerror("'case' encontrado fora de um contexto de switch ativo.");
                
                } else {
                    CaseInfo ci;
                    ci.constant_value_label = $2.label;
                    ci.constant_value_type = $2.tipo;
                    ci.code_target_label = genlabel();
					ci.traducao_exp_case = $2.traducao;
                    g_switch_context_stack.back().cases.push_back(ci);

                    $$.traducao = ci.code_target_label + ":\n" + $4.traducao;
                    $$.label = ci.code_target_label;
                    $$.tipo = "";
                }
            }
            ;

DEFAULT_CLAUSE : KWD_DEFAULT ':' COMANDOS
            {
                if (g_switch_context_stack.empty()) {
                    yyerror("'default' encontrado fora de um contexto de switch ativo.");
                } else {
                    SwitchContext& current_active_switch = g_switch_context_stack.back();
                    if (current_active_switch.default_info.exists) {
                        yyerror("Multiplos 'default' no mesmo switch.");
                    }
                    current_active_switch.default_info.exists = true;
                    current_active_switch.default_info.code_target_label = genlabel();

                    $$.traducao = current_active_switch.default_info.code_target_label + ":\n" + $3.traducao;
                    $$.label = current_active_switch.default_info.code_target_label;
                    $$.tipo = "";
                }
            }
            ;

OUTPUT      : E
            {
                string format_specifier;
                string valor_a_imprimir = $1.label;

                if ($1.tipo == "int" || $1.tipo == "bool") {
                    format_specifier = "%d";
                } else if ($1.tipo == "float") {
                    format_specifier = "%f";
                } else if ($1.tipo == "char") {
                    format_specifier = "%c";
                } else if ($1.tipo == "string") {
                    format_specifier = "%s";
                } else {
                    yyerror("Tentando imprimir uma expressao de tipo invalido ou desconhecido: " + $1.tipo);
                }

                $$.traducao = $1.traducao + "\tprintf(\"" + format_specifier + "\", " + valor_a_imprimir + ");\n";
                $$.label = "";
                $$.tipo = "";
            }
            | OUTPUT ',' E
            {
                $$.traducao = $1.traducao;
                
                string format_specifier;
                string valor_a_imprimir = $3.label;

                if ($3.tipo == "int" || $3.tipo == "bool") {
                    format_specifier = "%d";
                } else if ($3.tipo == "float") {
                    format_specifier = "%f";
                } else if ($3.tipo == "char") {
                    format_specifier = "%c";
                } else if ($3.tipo == "string") {
                    format_specifier = "%s";
                } else {
                    yyerror("Tentando imprimir uma expressao de tipo invalido ou desconhecido: " + $3.tipo);
                }

                $$.traducao += $3.traducao + "\tprintf(\"" + format_specifier + "\", " + valor_a_imprimir + ");\n";
                $$.label = "";
                $$.tipo = "";
            }
            ;
OP_ATRIBUICAO : KWD_PLUS_EQ { $$.label = "+";}
			  | KWD_MINUS_EQ { $$.label = "-";}
			  | KWD_MULT_EQ { $$.label = "*";}
			  | KWD_DIV_EQ { $$.label = "/";}
			  ;
ATRI 		:KWD_ID '=' E
			{
				traducaoTemp = "";

				if(!verifica_var($1.label)) {
					yyerror("Variavel nao declarada.");
				}

				Simbolo variavel;
				variavel = buscar($1.label);

				if(variavel.tipado == false) {
					if($3.tipo == "string" ){
						atualizar($3.tipo, $1.label, $3.tamanho, $3.vetor_string, "", "", "", false);
						declararVariavel($3.tipo, variavel.label, stoi($3.tamanho));
						variavel.tipo = $3.tipo;
						variavel.tamanho = $3.tamanho;
						$1.tamanho = $3.tamanho;
						$1.vetor_string = $3.vetor_string;
					}else{
						atualizar($3.tipo, $1.label, "", "", "", "", "", false);
						declararVariavel($3.tipo, variavel.label, -1);
						variavel.tipo = $3.tipo;
					}
				}

				$1.tipo = variavel.tipo;
				$1.label = variavel.label;

				if(tipofinal[$1.tipo][$3.tipo] == "erro") yyerror("Operação com tipos inválidos");

				traducaoTemp = cast_implicito(&$$, &$1, &$3, "atribuicao");
				if($1.tipo == "string" && $3.tipo == "string" && $3.id){
					$$.traducao += $1.traducao + $3.traducao + traducaoTemp + 
					"\t" + $1.label + " = (char *) realloc(" + $1.label + ", " + $3.tamanho + ");\n" +
					"\tstrcpy(" + $1.label + ", " + $3.label + ");\n";
				}else if($1.tipo == "string" && $3.tipo == "string"){
					$$.traducao += $1.traducao + $3.traducao + traducaoTemp + 
					"\t" + $1.label + " = (char *) malloc(" + $3.tamanho + " * sizeof(char));\n" +
					"\tstrcpy(" + $1.label + ", " + $3.label + ");\n";
				}else{
					$$.traducao += $1.traducao + $3.traducao + traducaoTemp + "\t" + $1.label + " = " + $3.label + ";\n";
				}
			}
			| KWD_ID '[' E ']' '[' E ']' '=' E
			{
				if (!verifica_var($1.label)) {
					yyerror("Matriz '" + $1.label + "' nao declarada.");
				}

				Simbolo s = buscar($1.label);
				if (!s.is_matrix) {
					yyerror("Variavel '" + $1.label + "' nao eh uma matriz.");
				}

				atributos rhs_attrs = $9;

				$$.traducao = $3.traducao + $6.traducao + rhs_attrs.traducao;

				if (s.tipado == false) {
					string inferred_type = rhs_attrs.tipo;
					
					if (inferred_type == "string") {
						declararVariavel("char**", s.label, -1);
						string temp_total_size = gentempcode();
						declararVariavel("int", temp_total_size, -1);
						$$.traducao += "\t" + temp_total_size + " = " + s.rows_label + " * " + s.cols_label + ";\n";
						$$.traducao += "\t" + s.label + " = (char**) malloc(sizeof(char*) * " + temp_total_size + ");\n";
						
					} else {
						string tipo_c_ptr = inferred_type;
						if (tipo_c_ptr == "bool") tipo_c_ptr = "int";
						declararVariavel(tipo_c_ptr + "*", s.label, -1);
						
						string temp_total_size = gentempcode();
						declararVariavel("int", temp_total_size, -1);
						$$.traducao += "\t" + temp_total_size + " = " + s.rows_label + " * " + s.cols_label + ";\n";
						$$.traducao += "\t" + s.label + " = (" + tipo_c_ptr + "*) malloc(sizeof(" + tipo_c_ptr + ") * " + temp_total_size + ");\n";
					}
					
					atualizar(inferred_type, $1.label, "", "", "", s.rows_label, s.cols_label, true);
					s.tipo = inferred_type; 
				
				} else {
					if (tipofinal[s.tipo][rhs_attrs.tipo] == "erro") {
						yyerror("A matriz '" + $1.label + "' eh do tipo " + s.tipo + " e nao pode receber uma atribuicao do tipo " + rhs_attrs.tipo);
					}
					if (s.tipo != rhs_attrs.tipo) {
						atributos lhs_attrs;
						lhs_attrs.tipo = s.tipo;
						$$.traducao += cast_implicito(&$$, &lhs_attrs, &rhs_attrs, "atribuicao");
					}
				}

				string temp_mult = gentempcode();
				declararVariavel("int", temp_mult, -1);
				$$.traducao += "\t" + temp_mult + " = " + $3.label + " * " + s.cols_label + ";\n"; 

				string temp_index = gentempcode();
				declararVariavel("int", temp_index, -1);
				$$.traducao += "\t" + temp_index + " = " + temp_mult + " + " + $6.label + ";\n";
				
				if (s.tipo == "string") {
					$$.traducao += "\t" + s.label + "[" + temp_index + "] = (char*) malloc(sizeof(char) * " + rhs_attrs.tamanho + ");\n";
					$$.traducao += "\tstrcpy(" + s.label + "[" + temp_index + "], " + rhs_attrs.label + ");\n";
				} else {
					$$.traducao += "\t" + s.label + "[" + temp_index + "] = " + rhs_attrs.label + ";\n";
				}
			}
			| KWD_ID OP_ATRIBUICAO E
			{
        		Simbolo lhs_var = buscar($1.label);
        		if (!lhs_var.tipado) {
            		yyerror("Variavel '" + $1.label + "' usada em operacao composta antes de ser tipada.");
        		}

        		if (lhs_var.tipo == "string" && $2.label == "+") {
            		if ($3.tipo != "string") {
                		yyerror("Operador '+=' em uma string requer outra string como operando.");
            		}
            
            		string novo_tamanho_label = gentempcode();
            		declararVariavel("int", novo_tamanho_label, -1);
            
            		$$.traducao = $3.traducao; 
            		$$.traducao += "\t" + novo_tamanho_label + " = strlen(" + lhs_var.label + ") + strlen(" + $3.label + ") + 1;\n";
            		$$.traducao += "\t" + lhs_var.label + " = (char*) realloc(" + lhs_var.label + ", " + novo_tamanho_label + ");\n";
            		$$.traducao += "\tstrcat(" + lhs_var.label + ", " + $3.label + ");\n";

            		atualizar(lhs_var.tipo, $1.label, novo_tamanho_label, "", lhs_var.label, "", "", false);

        		} else { 
            		if (tipofinal[lhs_var.tipo][$3.tipo] == "erro" || tipofinal[lhs_var.tipo][$3.tipo] == "string") {
                		yyerror("Operador '" + $2.label + "=' com tipos incompativeis: " + lhs_var.tipo + " e " + $3.tipo);
            		}

            		$$.traducao = $3.traducao;
            
            		string op_result_temp = gentempcode();
            		string op_result_tipo = tipofinal[lhs_var.tipo][$3.tipo];
            		declararVariavel(op_result_tipo, op_result_temp, -1);
            		$$.traducao += "\t" + op_result_temp + " = " + lhs_var.label + " " + $2.label + " " + $3.label + ";\n";

            		$$.traducao += "\t" + lhs_var.label + " = " + op_result_temp + ";\n";
        		}
			}
			| OPERADORES_UNARIOS
			;
INITIALIZER_SETUP :
				  {
					g_current_matrix_initializer.clear();
				  }
				  ;
INITIALIZER : '{' INITIALIZER_SETUP ROW_LIST '}'
			;

ROW_LIST : ROW
		 | ROW_LIST ',' ROW
		 ;
ROW : '{' 
	{
		g_current_matrix_initializer.push_back({});
	}
	ELEMENT_LIST '}'
	;
ELEMENT_LIST : E
			 {
				g_current_matrix_initializer.back().push_back($1);
			 }
			 | ELEMENT_LIST ',' E
			 {
				g_current_matrix_initializer.back().push_back($3);
			 }
			 ;

FLAT_INITIALIZER_SETUP :
						{
							g_current_flat_initializer.clear();
						}
						;
FLAT_INITIALIZER : '{' FLAT_INITIALIZER_SETUP FLAT_ELEMENT_LIST '}'
				 ;
FLAT_ELEMENT_LIST : E
				  {
					g_current_flat_initializer.push_back($1);
				  }
				  | FLAT_ELEMENT_LIST ',' E
				  {
					g_current_flat_initializer.push_back($3);
				  }
				  ;
DEC			:KWD_VAR KWD_ID
			{
				if(verifica_var($2.label)) {
					yyerror("Variavel já declarada.\n");
				}

				guardaSimbolos($2.label);

				$$.label = "";
				$$.traducao = "";
				$$.tipo = "";
				$$.tamanho = "";
				$$.vetor_string = "";

			}
			| KWD_VAR KWD_ID '[' E ']' '[' E ']'
			{
			  if(verifica_var($2.label)) {
                    yyerror("Voce ja declarou essa variavel: " + $2.label);
              }
              if ($4.tipo != "int" || $7.tipo != "int") {
                    yyerror("As dimensoes da matriz devem ser do tipo inteiro.");
              }

              guardaSimbolos($2.label); 

			  atualizar("", $2.label, "", "", "", $4.label, $7.label, true);

			  $$.traducao = $4.traducao + $7.traducao;
			  $$.label = "";
			  $$.tipo = "";
			}
			| KWD_VAR KWD_ID '=' E
			{
				if(verifica_var($2.label)) {
                    yyerror("Voce ja declarou essa variavel: " + $2.label);
                }

				guardaSimbolos($2.label);

				$$.label = "";
				$$.traducao = "";
				$$.tipo = "";
				$$.tamanho = "";
				$$.vetor_string = "";

				Simbolo variavel;
				variavel = buscar($2.label);

				if(variavel.tipado == false) {
					if($4.tipo == "string" ){
						atualizar($4.tipo, $2.label, $4.tamanho, $4.vetor_string, "", "", "", false);
						declararVariavel($4.tipo, variavel.label, stoi($4.tamanho));
						variavel.tipo = $4.tipo;
						variavel.tamanho = $4.tamanho;
						$2.tamanho = $4.tamanho;
						$2.vetor_string = $4.vetor_string;
					}else{
						atualizar($4.tipo, $2.label, "", "", "", "", "", false);
						declararVariavel($4.tipo, variavel.label, -1);
						variavel.tipo = $4.tipo;
					}
				}

				$2.tipo = variavel.tipo;
				$2.label = variavel.label;

				if(tipofinal[$2.tipo][$4.tipo] == "erro") yyerror("Operação com tipos inválidos");

				traducaoTemp = "";
				traducaoTemp = cast_implicito(&$$, &$2, &$4, "atribuicao");
				if($2.tipo == "string" && $4.tipo == "string" && $4.id){
					$$.traducao += $2.traducao + $4.traducao + traducaoTemp + 
					"\t" + $2.label + " = (char *) realloc(" + $2.label + ", " + $4.tamanho + ");\n" +
					"\tstrcpy(" + $2.label + ", " + $4.label + ");\n";
				}else if($2.tipo == "string" && $4.tipo == "string"){
					$$.traducao += $2.traducao + $4.traducao + traducaoTemp + 
					"\t" + $2.label + " = (char *) malloc(" + $4.tamanho + " * sizeof(char));\n" +
					"\tstrcpy(" + $2.label + ", " + $4.label + ");\n";
				}else{
					$$.traducao += $2.traducao + $4.traducao + traducaoTemp + "\t" + $2.label + " = " + $4.label + ";\n";
				}
			}
			| KWD_VAR KWD_ID '[' E ']' '[' E ']' '=' INITIALIZER
			{
                if(verifica_var($2.label)) {
                    yyerror("Voce ja declarou essa variavel: " + $2.label);
                }
                if ($4.tipo != "int" || $7.tipo != "int") {
                    yyerror("As dimensoes da matriz devem ser do tipo inteiro constante.");
                }
                if (g_current_matrix_initializer.empty() || g_current_matrix_initializer[0].empty()) {
                    yyerror("Lista de inicializacao da matriz '" + $2.label + "' nao pode ser vazia.");
                }

                int declared_rows = stoi($4.literal_value);
                int declared_cols = stoi($7.literal_value);
        
                if (g_current_matrix_initializer.size() != declared_rows) {
                    yyerror("Numero de linhas no inicializador (" + to_string(g_current_matrix_initializer.size()) + ") eh diferente do declarado (" + to_string(declared_rows) + ").");
                }
        
				string inferred_type = g_current_matrix_initializer[0][0].tipo;
				string all_expressions_code;

				for (size_t i = 0; i < g_current_matrix_initializer.size(); ++i) {
					if (g_current_matrix_initializer[i].size() != declared_cols) {
						yyerror("Numero de colunas na linha " + to_string(i) + " do inicializador eh diferente do declarado (" + to_string(declared_cols) + ").");
					}
					for (size_t j = 0; j < g_current_matrix_initializer[i].size(); ++j) {
						atributos& current_elem = g_current_matrix_initializer[i][j];
						all_expressions_code += current_elem.traducao;
						
						if (inferred_type != current_elem.tipo) {
							bool cast_valido = (inferred_type == "float" && current_elem.tipo == "int") || (inferred_type == "int" && current_elem.tipo == "float");
							if (cast_valido) {
								string casted_temp_label = gentempcode();
								string c_type_for_decl = inferred_type;
								if(c_type_for_decl == "bool") c_type_for_decl = "int";
								
								declararVariavel(inferred_type, casted_temp_label, -1);
								all_expressions_code += "\t" + casted_temp_label + " = (" + c_type_for_decl + ")" + current_elem.label + ";\n";
								current_elem.label = casted_temp_label;
							} else {
								yyerror("Tipos incompativeis na inicializacao. Esperado " + inferred_type + ", mas encontrado " + current_elem.tipo + ".");
							}
						}
					}
				}

				guardaSimbolos($2.label);
				Simbolo s = buscar($2.label);
				atualizar(inferred_type, $2.label, "", "", "", $4.literal_value, $7.literal_value, true);
				
				string tipo_c = inferred_type;
				if (tipo_c == "bool") tipo_c = "int";
				
				declararVariavel(tipo_c + "*", s.label, -1);

				string temp_total_size = gentempcode();
				declararVariavel("int", temp_total_size, -1);
				$$.traducao = $4.traducao + $7.traducao;
				$$.traducao += "\t" + temp_total_size + " = " + $4.literal_value + " * " + $7.literal_value + ";\n";
				$$.traducao += "\t" + s.label + " = (" + tipo_c + "*) malloc(sizeof(" + tipo_c + ") * " + temp_total_size + ");\n";
				$$.traducao += all_expressions_code;

				for (int i = 0; i < declared_rows; ++i) {
					for (int j = 0; j < declared_cols; ++j) {
						string temp_index = gentempcode();
						declararVariavel("int", temp_index, -1);
						string valor_label = g_current_matrix_initializer[i][j].label;
						$$.traducao += "\t" + temp_index + " = " + to_string(i) + " * " + $7.literal_value + " + " + to_string(j) + ";\n";
						$$.traducao += "\t" + s.label + "[" + temp_index + "] = " + valor_label + ";\n";
					}
				}
			}
			| KWD_VAR KWD_ID '[' E ']' '[' E ']' '=' FLAT_INITIALIZER
			{
				if(verifica_var($2.label)) { yyerror("Voce ja declarou essa variavel: " + $2.label); }
				if ($4.tipo != "int" || $7.tipo != "int") { yyerror("As dimensoes da matriz devem ser do tipo inteiro."); }
				if (g_current_flat_initializer.empty()) { yyerror("Lista de inicializacao da matriz nao pode ser vazia."); }

				int declared_rows = stoi($4.literal_value);
				int declared_cols = stoi($7.literal_value);
				
				if (g_current_flat_initializer.size() != (declared_rows * declared_cols)) {
					yyerror("Numero de elementos no inicializador (" + to_string(g_current_flat_initializer.size()) + ") eh diferente do tamanho da matriz (" + to_string(declared_rows * declared_cols) + ").");
				}
				
				string inferred_type = g_current_flat_initializer[0].tipo;
				string all_expressions_code;

				for (size_t i = 0; i < g_current_flat_initializer.size(); ++i) {
					atributos& current_elem = g_current_flat_initializer[i];
					all_expressions_code += current_elem.traducao;
					
					if (inferred_type != current_elem.tipo) {
						bool cast_valido = (inferred_type == "float" && current_elem.tipo == "int") || (inferred_type == "int" && current_elem.tipo == "float");
						if (cast_valido) {
							string casted_temp_label = gentempcode();
							declararVariavel(inferred_type, casted_temp_label, -1);
							all_expressions_code += "\t" + casted_temp_label + " = (" + inferred_type + ")" + current_elem.label + ";\n";
							current_elem.label = casted_temp_label;
						} else {
							yyerror("Tipos incompativeis na inicializacao. Esperado " + inferred_type + ", mas encontrado " + current_elem.tipo + ".");
						}
					}
				}

				guardaSimbolos($2.label);
				Simbolo s = buscar($2.label);
				atualizar(inferred_type, $2.label, "", "", "", $4.literal_value, $7.literal_value, true);
				
				string tipo_c = inferred_type;
				if (tipo_c == "bool") tipo_c = "int";

				$$.traducao = $4.traducao + $7.traducao;
				string temp_total_size = gentempcode();
				declararVariavel("int", temp_total_size, -1);
				$$.traducao += "\t" + temp_total_size + " = " + $4.literal_value + " * " + $7.literal_value + ";\n";
				
				if (inferred_type == "string") {
					declararVariavel("char**", s.label, -1);
					$$.traducao += "\t" + s.label + " = (char**) malloc(sizeof(char*) * " + temp_total_size + ");\n";
				} else {
					declararVariavel(tipo_c + "*", s.label, -1);
					$$.traducao += "\t" + s.label + " = (" + tipo_c + "*) malloc(sizeof(" + tipo_c + ") * " + temp_total_size + ");\n";
				}
				
				$$.traducao += all_expressions_code;

				for (size_t i = 0; i < g_current_flat_initializer.size(); ++i) {
					const atributos& current_elem = g_current_flat_initializer[i];
					if (inferred_type == "string") {
						$$.traducao += "\t" + s.label + "[" + to_string(i) + "] = (char*) malloc(sizeof(char) * " + current_elem.tamanho + ");\n";
						$$.traducao += "\tstrcpy(" + s.label + "[" + to_string(i) + "], " + current_elem.label + ");\n";
					} else {
						$$.traducao += "\t" + s.label + "[" + to_string(i) + "] = " + current_elem.label + ";\n";
					}
				}
			}
			;


E 			: '(' E ')'
			{
				$$ = $2;
			}
			| E '+' E
			{	
				traducaoTemp = "";
				
				traducaoTemp = cast_implicito(&$$, &$1, &$3, "operacao");

				$$.label = gentempcode();
					
				$$.tipo = tipofinal[$1.tipo][$3.tipo];
				if($$.tipo == "erro") yyerror("Operação com tipos inválidos");

				$$.traducao = $1.traducao + $3.traducao + traducaoTemp +
					"\t" + $$.label + " = " + $1.label + " + " + $3.label + ";\n";

				declararVariavel($$.tipo, $$.label, -1);
				
			}
			| E '-' E
			{
				traducaoTemp = "";
				
				traducaoTemp = cast_implicito(&$$, &$1, &$3, "operacao");
				
                $$.label = gentempcode();
                
				$$.tipo = tipofinal[$1.tipo][$3.tipo];
				if($$.tipo == "erro" || $$.tipo == "string") yyerror("Operação com tipos inválidos");

                $$.traducao = $1.traducao + $3.traducao + traducaoTemp +
                    "\t" + $$.label + " = " + $1.label + " - " + $3.label + ";\n";

                declararVariavel($$.tipo, $$.label, -1);
			}
			| E '*' E
			{
				traducaoTemp = "";

				traducaoTemp = cast_implicito(&$$, &$1, &$3, "operacao");

                $$.label = gentempcode();
                
				$$.tipo = tipofinal[$1.tipo][$3.tipo];
				if($$.tipo == "erro" || $$.tipo == "string") yyerror("Operação com tipos inválidos");

                $$.traducao = $1.traducao + $3.traducao + traducaoTemp +
                    "\t" + $$.label + " = " + $1.label + " * " + $3.label + ";\n";

                declararVariavel($$.tipo, $$.label, -1);			
			}
			| E '/' E
			{
				traducaoTemp = "";

				traducaoTemp = cast_implicito(&$$, &$1, &$3, "operacao");

				$$.label = gentempcode();
                
				$$.tipo = tipofinal[$1.tipo][$3.tipo];
				if($$.tipo == "erro" || $$.tipo == "string") yyerror("Operação com tipos inválidos");

                $$.traducao = $1.traducao + $3.traducao + traducaoTemp + "\t" + $$.label + " = " + $1.label + " / " + $3.label + ";\n";

                declararVariavel($$.tipo, $$.label, -1);
			}
			| KWD_FLOAT
			{
				$$.label = gentempcode();
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				$$.tipo = "float";
				declararVariavel($$.tipo, $$.label, -1);
				$$.literal_value = $1.label;
			}
			| KWD_NUM
			{
				$$.label = gentempcode();
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				$$.tipo = "int";
				declararVariavel($$.tipo, $$.label, -1);
				$$.literal_value = $1.label;
			}
			| KWD_ID
			{
				Simbolo variavel;

                if(!verifica_var($1.label)) {
                    yyerror("Variavel nao declarada.");
                }

                variavel = buscar($1.label);
                if(variavel.tipo == "") yyerror("Variavel ainda nao tem um tipo definido");

                $$.label = variavel.label;
                $$.traducao = "";
                $$.tipo = variavel.tipo;
                $$.tamanho = variavel.tamanho;
                $$.vetor_string = variavel.vetor_string;
                $$.id = true;				
			}
			| KWD_CHAR
			{

				$$.label = gentempcode();
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				$$.tipo = "char";
				$$.tamanho = "1";
				declararVariavel($$.tipo, $$.label, -1);
				$$.literal_value = $1.label;
			}
			| KWD_BOOL
			{
				if($1.label == "true") {
					$1.label = "1";
				} else {
					$1.label = "0";
				}

				$$.label = $1.label;
				$$.traducao = "";
				$$.tipo = "bool";
			}
            | E KWD_RELACIONAL E
    		{	
				traducaoTemp = "";

				traducaoTemp = cast_implicito(&$$, &$1, &$3, "operacao");

            	$$.label = gentempcode();
    			$$.traducao = $1.traducao + $3.traducao + traducaoTemp + "\t" + $$.label + " = " + $1.label + " " + $2.label + " " + $3.label + ";\n";
        		$$.tipo = "bool";
        		declararVariavel($$.tipo, $$.label, -1);
        	}
            | E KWD_OU E
    		{
   				$$.label = gentempcode();
        		$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " " + $2.label + " " + $3.label + ";\n";
        		$$.tipo = "bool";
    			declararVariavel($$.tipo, $$.label, -1);
        	}
            | E KWD_E E
        	{
        		$$.label = gentempcode();
        		$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " " + $2.label + " " + $3.label + ";\n";
        		$$.tipo = "bool";
        		declararVariavel($$.tipo, $$.label, -1);
            }
            | KWD_NEG E
            {
	        	$$.label = gentempcode();
        		$$.traducao = $2.traducao + "\t" + $$.label + " = !" + $2.label + ";\n";
        		$$.tipo = "bool";
        		declararVariavel($$.tipo, $$.label, -1);
        	}
	    	| KWD_CAST E
	    	{
				string temp1 = gentempcode();
    			string temp2 = gentempcode();

    			declararVariavel($2.tipo, temp1, -1);
    			declararVariavel($1.tipo, temp2, -1);

    			$$.traducao = $2.traducao +	"\t" + temp1 + " = " + $2.label + ";\n" +"\t" + temp2 + " = " + "(" + $1.tipo + ")" + temp1 + ";\n";

    			$$.label = temp2;
    			$$.tipo = $1.tipo;
	    	}
			|KWD_CADEIA_CHAR
			{
				// A função unescape_string já foi chamada no léxico.
				// O yylval.label agora é a string processada.
				string str_processada = $1.label;
				int tamReal = str_processada.length() + 1; // +1 para o '\0'

				$$.label = gentempcode();
				$$.tipo = "string";
				$$.tamanho = to_string(tamReal);
				$$.vetor_string = str_processada;

				// Alocação de memória
				$$.traducao = "\t" + $$.label + " = (char *) malloc(" + $$.tamanho + " * sizeof(char));\n";

				// --- LAÇO CORRIGIDO PARA "ESCAPAR DE VOLTA" OS CARACTERES ---
				for(int i = 0; i < str_processada.length(); i++){
					string char_escapado;
					char c = str_processada[i];
					switch (c) {
						case '\n': char_escapado = "\\n"; break;
						case '\t': char_escapado = "\\t"; break;
						case '\\': char_escapado = "\\\\"; break;
						case '\'': char_escapado = "\\'"; break;
						case '\"': char_escapado = "\\\""; break;
						default:   char_escapado = string(1, c); break;
					}
					$$.traducao += "\t" + $$.label + "[" + to_string(i) + "] = '" + char_escapado + "';\n";
				}
				// Adiciona o terminador nulo no final
				$$.traducao += "\t" + $$.label + "[" + to_string(str_processada.length()) + "] = '\\0';\n";

				declararVariavel($$.tipo, $$.label, tamReal);
			}
			| KWD_ID '[' E ']' '[' E ']'
			{
            if (!verifica_var($1.label)) {
            	yyerror("Matriz '" + $1.label + "' nao declarada.");
            }

            Simbolo s = buscar($1.label);
            if (!s.is_matrix) {
            	yyerror("Variavel '" + $1.label + "' nao eh uma matriz.");
            }
            if (!s.tipado) {
            	yyerror("Matriz '" + $1.label + "' usada antes de qualquer valor ser atribuido a ela.");
            }

            $$.traducao = $3.traducao + $6.traducao;

			string temp_mult = gentempcode();
			declararVariavel("int", temp_mult, -1);
			$$.traducao += "\t" + temp_mult + " = " + $3.label + " * " + s.cols_label + ";\n";

			string temp_index = gentempcode();
			declararVariavel("int", temp_index, -1);
			$$.traducao += "\t" + temp_index + " = " + temp_mult + " + " + $6.label + ";\n";
            
            $$.label = gentempcode();
            $$.tipo = s.tipo;
            declararVariavel($$.tipo, $$.label, -1);
            $$.traducao += "\t" + $$.label + " = " + s.label + "[" + temp_index + "];\n";
			}
			| OPERADORES_UNARIOS
            ;
OPERADORES_UNARIOS : KWD_ID KWD_INC
					{
        				Simbolo variavel = buscar($1.label);
        				if (variavel.tipo != "int" && variavel.tipo != "float" && variavel.tipo != "char") {
            				yyerror("Operador '++' so pode ser aplicado em tipos numericos (int, float, char).");
        				}
        				if (!variavel.tipado) {
            				yyerror("Variavel '" + $1.label + "' usada em operacao antes de ser tipada.");
        				}

        				$$.label = gentempcode();
        				$$.tipo = variavel.tipo; 
        				declararVariavel($$.tipo, $$.label, -1);
        
        				$$.traducao = "\t" + $$.label + " = " + variavel.label + ";\n"; 
        				$$.traducao += "\t" + variavel.label + " = " + variavel.label + " + 1;\n";
					}
					| KWD_ID KWD_DEC
					{
        				Simbolo variavel = buscar($1.label);
        				if (variavel.tipo != "int" && variavel.tipo != "float" && variavel.tipo != "char") {
            				yyerror("Operador '--' so pode ser aplicado em tipos numericos (int, float, char).");
        				}
        				if (!variavel.tipado) {
            				yyerror("Variavel '" + $1.label + "' usada em operacao antes de ser tipada.");
        				}

        				$$.label = gentempcode();
        				$$.tipo = variavel.tipo;
        				declararVariavel($$.tipo, $$.label, -1);
        
        				$$.traducao = "\t" + $$.label + " = " + variavel.label + ";\n"; 
        				$$.traducao += "\t" + variavel.label + " = " + variavel.label + " - 1;\n";
					}
					| KWD_INC KWD_ID
					{
        				Simbolo variavel = buscar($2.label);
        				if (variavel.tipo != "int" && variavel.tipo != "float" && variavel.tipo != "char") {
            				yyerror("Operador '++' so pode ser aplicado em tipos numericos (int, float, char).");
        				}
        				if (!variavel.tipado) {
            				yyerror("Variavel '" + $2.label + "' usada em operacao antes de ser tipada.");
        				}
        
        				$$.traducao = "\t" + variavel.label + " = " + variavel.label + " + 1;\n";
        
        				$$.label = variavel.label;
        				$$.tipo = variavel.tipo;
					}
					| KWD_DEC KWD_ID
					{
        				Simbolo variavel = buscar($2.label);
        				if (variavel.tipo != "int" && variavel.tipo != "float" && variavel.tipo != "char") {
            				yyerror("Operador '--' so pode ser aplicado em tipos numericos (int, float, char).");
        				}
        				if (!variavel.tipado) {
            				yyerror("Variavel '" + $2.label + "' usada em operacao antes de ser tipada.");
        				}

        				$$.traducao = "\t" + variavel.label + " = " + variavel.label + " - 1;\n";
        
        				$$.label = variavel.label;
        				$$.tipo = variavel.tipo;
					}
					;
%%

#include "lex.yy.c"

int yyparse();

void yyerror(string MSG)
{
	cout << MSG << endl;
	exit (0);
}

void desempilhar_contexto_case() {
	if (!g_switch_context_stack.empty()) {
        g_switch_context_stack.pop_back();
	} else {
        yyerror("PANICO: Pilha de contexto de switch vazia no cleanup");
    }
}

string gentempcode()
{
	var_temp_qnt++;
	return "T" + to_string(var_temp_qnt);
}

void adicionarEscopo()
{
	unordered_map<string, Simbolo> escopo;
	tabela.push_back(escopo);
}

int tamanho_string(string traducao){
	traducaoTemp = "";
	int tamanho = 0;
	int i = 0;

	while(traducao[i] != '\0'){
		if(traducao[i] != '"') tamanho++;
		i++;
	}
	tamanho++;

	return tamanho;
}

Simbolo buscar(string name)
{
	for(int i = tabela.size() - 1; i >= 0; i--) {
		auto it = tabela[i].find(name);
		if(!(it == tabela[i].end())) return it->second;
	}
	yyerror("Não foi encontrado o símbolo durante a busca!");
}

string unescape_string(const char* s) {
    string resultado;
    // Itera pela string, ignorando as aspas do início e do fim.
    for (int i = 1; s[i] != '\"' && s[i] != '\0'; i++) {
        if (s[i] == '\\') {
            i++; // Pula a barra invertida para ver o próximo caractere.
            switch (s[i]) {
                case 'n':
                    resultado += '\n'; // Adiciona um caractere de nova linha REAL.
                    break;
                case 't':
                    resultado += '\t'; // Adiciona um caractere de tabulação.
                    break;
                case '\"':
                    resultado += '\"'; // Adiciona aspas dentro da string.
                    break;
                case '\\':
                    resultado += '\\'; // Adiciona uma barra invertida literal.
                    break;
                default:
                    resultado += s[i]; // Mantém o caractere como está (ex: \z -> z)
                    break;
            }
        } else {
            resultado += s[i];
        }
    }
    return resultado;
}

void removerEscopo() 
{
	tabela.pop_back();
}

string retirar_aspas(string traducao, int tamanho){
	traducaoTemp = "";

	for(int j = 1; j < tamanho; j++){
		traducaoTemp += traducao[j];
	}	

	return traducaoTemp;
}

string genlabel()
{
    label_qnt++;
    return "L" + to_string(label_qnt);
}

string string_intermediario(string buffer, string tamanho, string cond, string label)
{
    string temp = gentempcode();
	declararVariavel("char", temp, -1);
    string saida = "";
	saida += "\n\t" + tamanho + " = 0;\n"; 
	saida += "\t" + label + ":\n"; 
	saida += "\t\t" + temp + " = *" + buffer + ";\n"; 
	saida += "\t\t" + buffer + " = " + buffer + " + 1;\n";
	saida += "\t\t" + cond + " = (" + temp + " != '\\0');\n"; 
	saida += "\t\tif (!" + cond + ") goto " + label + "_end;\n"; 
	saida += "\t\t" + tamanho + " = " + tamanho + " + 1;\n"; 
	saida += "\t\tgoto " + label + ";\n"; 
	saida += "\t" + label + "_end:\n"; 
	saida += "\t\t" + tamanho + " = " + tamanho + " + 1;\n";
    return saida;
}

void declararVariavel(string tipo, string label, int tam_string) 
{
	if (tipo == "bool") tipo = "int";
	if (tipo == "string") tipo = "char*";
	
	if(g_processando_escopo_global){
		declaracoes_globais.push_back(tipo + " " + label + ";\n");
	}
	else {
		declaracoes_locais.push_back("\t" + tipo + " " + label + ";\n");
	}
}

void guardaSimbolos(string nome)
{
	Simbolo simbolo;
	simbolo.label = gentempcode();
	auto it = tabela.end();
	(*(--it))[nome] = simbolo;
}

bool verifica_var(string name)
{
	for(int i = tabela.size() - 1; i >= 0; i--) {
		auto it = tabela[i].find(name);
		if(!(it == tabela[i].end())) return true;
	}
	return false;
}

void removerRotulos() {
	if (!rotulo_condicao.empty()) {
    	rotulo_condicao.pop_back();
    } else {
        yyerror("Tentativa de dar pop na pilha rotulo condicao vazia");
    }
    
	if (!rotulo_fim.empty()) {
        rotulo_fim.pop_back();
    } else {
        yyerror("Tentativa de dar pop na pilha rotulo fim vazia");
    }
					
	if (!rotulo_inicio.empty()) {
        rotulo_inicio.pop_back();
    } else {
        yyerror("Tentativa de dar pop na pilha rotulo inicio vazia");
    }
    
	if (!rotulo_incremento.empty()) {
        rotulo_incremento.pop_back();
    } else {
        yyerror("Tentativa de dar pop na pilha rotulo incremento vazia");
	}
}

void atualizar(string tipo, string nome, string tamanho, string cadeia_char, string atualiza_label, string rows, string cols, bool matrix) {
	for(int i = tabela.size() - 1; i >= 0; i--) {
		auto it = tabela[i].find(nome);
		if(!(it == tabela[i].end())) {
			if(atualiza_label != "") it->second.label = atualiza_label;
			
			if(tipo != "") {
				it->second.tipo = tipo;
				it->second.tipado = true;
			}
			it->second.tamanho = tamanho;
			it->second.vetor_string = cadeia_char;
			it->second.rows_label = rows;
			it->second.cols_label = cols;
			it->second.is_matrix = matrix;
			break;
		}
	}
}

string cast_implicito(atributos* no1, atributos* no2, atributos* no3, string tipo)
{
		traducaoTemp = "";

		if (!((no2->tipo == "float" && no3->tipo == "int") || (no2->tipo == "int" && no3->tipo == "float")) ) {
			return traducaoTemp;
		}

		if(tipo == "operacao") {
        	if (no2->tipo == "int" && no3->tipo == "float") {
        		no1->label = gentempcode();
        		declararVariavel("float", no1->label, -1);
        		traducaoTemp += "\t" + no1->label + " = (float)" + no2->label + ";\n";
        		no2->label = no1->label;
				no2->tipo = "float";
        	} else if (no2->tipo == "float" && no3->tipo == "int") {
				no1->label = gentempcode();
        		declararVariavel("float", no1->label, -1);
        		traducaoTemp += "\t" + no1->label + " = (float)" + no3->label + ";\n";
        		no3->label = no1->label;
        		no3->tipo = "float";
        	}
    	}
		
		if(tipo == "atribuicao") {
        	if (no2->tipo == "int" && no3->tipo == "float") {
        		no1->label = gentempcode();
        		declararVariavel("int", no1->label, -1);
        		traducaoTemp += "\t" + no1->label + " = (int)" + no3->label + ";\n";
				no3->label = no1->label;
    		} else if (no2->tipo == "float" && no3->tipo == "int") {
				no1->label = gentempcode();
        		declararVariavel("float", no1->label, -1);
        		traducaoTemp += "\t" + no1->label + " = (float)" + no3->label + ";\n";
				no3->label = no1->label;
        	} 
    	}
	return traducaoTemp;
}

int main(int argc, char* argv[])
{
	adicionarEscopo();

	traducaoTemp = "";
	label_qnt = 0;
	var_temp_qnt = 0;
	tipofinal["int"]["int"] = "int";
	tipofinal["float"]["int"] = "float";
	tipofinal["float"]["float"] = "float";
	tipofinal["string"]["string"] = "string";
	tipofinal["int"]["float"] = "float";
	tipofinal["char"]["int"] = "char";
	tipofinal["int"]["char"] = "char";
	tipofinal["char"]["char"] = "char";
	tipofinal["bool"]["bool"] = "bool";
	tipofinal["string"]["char"] = "erro";
	tipofinal["char"]["string"] = "erro";
	tipofinal["bool"]["int"] = "erro";
	tipofinal["int"]["bool"] = "erro";
	tipofinal["float"]["char"] = "erro";
	tipofinal["char"]["float"] = "erro";
	tipofinal["bool"]["char"] = "erro";
	tipofinal["char"]["bool"] = "erro";
	tipofinal["bool"]["float"] = "erro";
	tipofinal["float"]["bool"] = "erro";
	tipofinal["string"]["bool"] = "erro";
	tipofinal["bool"]["string"] = "erro";
	tipofinal["string"]["int"] = "erro";
	tipofinal["int"]["string"] = "erro";
	tipofinal["string"]["float"] = "erro";
	tipofinal["float"]["string"] = "erro";

	yyparse();

	return 0;
}