
program: lex.yy.c test.tab.c hash.o
	cc -o program lex.yy.c test.tab.c hash.o -lm

lex.yy.c: test.l
	flex test.l

test.tab.c: lex.yy.c test.y
	bison -d test.y

hash.o: hash.c hash.h
	cc -c hash.c

clean:
	rm program test.tab.c test.tab.h lex.yy.c *.o
