Códigos para rodar:
1:win_bison -d sintatico.y -o sintatico.tab.c
2:win_flex -o lex.yy.c lexico.l
3:gcc -o compilador sintatico.tab.c lex.yy.c -lfl
ou
gcc -o compilador sintatico.tab.c lex.yy.c
.\compilador.exe



# Compilador
..............................compilation..................................

etapa 1:
1 - Operações; ex: +-*/...
2 - ()
3 - atribuição 

Etapa 2:
....
....
....

Etapa FInal:

....

............................................................................

