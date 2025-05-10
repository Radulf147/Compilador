%{
using System;
using System.Collections.Generic;

int tempCounter = 1;
List<string> codigoIntermediario = new List<string>();

string novoTemporario() {
    return "T" + (tempCounter++);
}
%}

%token NUMERO SOMA

%%

expressao
    : NUMERO
        {
            string t = novoTemporario();
            codigoIntermediario.Add($"{t} = {$1};");
            $$ = t;
        }
    | expressao SOMA NUMERO
        {
            string t1 = $1;
            string t2 = novoTemporario();
            codigoIntermediario.Add($"{t2} = {$3};");
            string t3 = novoTemporario();
            codigoIntermediario.Add($"{t3} = {t1} + {t2};");
            $$ = t3;
        }
    ;

%%

public class Program {
    public static void Main() {
        yyparse();
        foreach (var linha in codigoIntermediario) {
            Console.WriteLine(linha);
        }
    }
}
