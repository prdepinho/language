CFLAGS=-g

program: lex.yy.c test.tab.c semantics.o array.o hash.o map_array.o vm.o
	cc -o program lex.yy.c test.tab.c semantics.o array.o hash.o map_array.o vm.o -lm $(CFLAGS)

lex.yy.c: test.l
	flex test.l

test.tab.c: lex.yy.c test.y
	bison -d test.y

semantics.o: semantics.c semantics.h
	cc -c semantics.c $(CFLAGS)

array.o: array.c array.h
	cc -c array.c $(CFLAGS)

hash.o: hash.c hash.h
	cc -c hash.c $(CFLAGS)

map_array.o: map_array.c map_array.h
	cc -c map_array.c $(CFLAGS)

vm.o: vm.c vm.h
	cc -c vm.c $(CFLAGS)

test: test.c hash.o
	cc test.c hash.o array.o map_array.o -o test $(CFLAGS)

clean:
	rm program test.tab.c test.tab.h lex.yy.c *.o
