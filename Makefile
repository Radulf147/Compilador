COMPILADOR_C = gcc
ARQ_FONTE = teste5.cspt
ARQ_C_GERADO = saida.c
EXECUTAVEL_FINAL = saida_programa
NOME_COPILADOR = compirado


all:
	clear
	lex lexico.l
	yacc -d -t sintatico.y
	g++ -o $(NOME_COPILADOR) y.tab.c -ll
	@echo "\n"
	./$(NOME_COPILADOR) < $(ARQ_FONTE) > $(ARQ_C_GERADO)
	@echo "\n"
	@cat $(ARQ_C_GERADO)
	@echo "\n"
	$(COMPILADOR_C) -o $(EXECUTAVEL_FINAL) $(ARQ_C_GERADO)
	@echo "\n"
	./$(EXECUTAVEL_FINAL)
	@echo "\n"

clean:
	@echo "Limpando arquivos gerados..."
	rm -f $(NOME_COPILADOR) $(ARQ_C_GERADO) $(EXECUTAVEL_FINAL) y.tab.c y.tab.h lex.yy.c

