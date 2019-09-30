
program: lex.yy.c test.tab.c semantics.o array.o hash.o
	cc -o program lex.yy.c test.tab.c semantics.o array.o hash.o -lm

lex.yy.c: test.l
	flex test.l

test.tab.c: lex.yy.c test.y
	bison -d test.y

semantics.o: semantics.c semantics.h
	cc -c semantics.c

array.o: array.c array.h
	cc -c array.c

hash.o: hash.c hash.h
	cc -c hash.c

test: test.c hash.o
	cc test.c hash.o -o test

clean:
	rm program test.tab.c test.tab.h lex.yy.c *.o
