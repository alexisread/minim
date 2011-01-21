CFLAGS = -Wall -g # -Os

.SUFFIXES :

all : eval

eval : eval.c gc.c gc.h buffer.c chartab.h
	gcc -g $(CFLAGS) -o eval eval.c

opt : .force
	$(MAKE) CFLAGS="$(CFLAGS) -O3 -fomit-frame-pointer -DNDEBUG"

debuggc : .force
	$(MAKE) CFLAGS="$(CFLAGS) -DDEBUGGC=1"

profile : .force
	$(MAKE) clean eval CFLAGS="$(CFLAGS) -O3 -fno-inline-functions -DNDEBUG"
	shark -q -1 -i ./eval emit.l eval.l eval.l eval.l eval.l eval.l eval.l eval.l eval.l eval.l eval.l > test.s

test : *.l eval
	time ./emit.l eval.l > test.s && cc -c -o test.o test.s && size test.o && gcc -o test test.o

time : .force
	time ./eval emit.l eval.l eval.l eval.l eval.l eval.l > /dev/null

test2 : test .force
	time ./test boot.l emit.l eval.l > test2.s
	diff test.s test2.s

time2 : .force
	time ./test boot.l emit.l eval.l eval.l eval.l eval.l eval.l > /dev/null

test-eval : test .force
	time ./test test-eval.l

test-boot : test .force
	time ./test boot-emit.l

test-emit : eval .force
	./emit.l test-emit.l | tee test.s && cc -c -o test.o test.s && size test.o && cc -o test test.o && ./test

stats : .force
	cat boot.l emit.l | sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
	cat eval.l | sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
	cat boot.l emit.l eval.l | sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l

clean : .force
	rm -f *~ *.o main eval test
	rm -rf *.dSYM *.mshark

.force :
