DIR = $(shell pwd)
MAJOR_VERSION = $(shell git describe --abbrev=0 --tags)
MINOR_VERSION = $(shell git rev-list ${MAJOR_VERSION}.. --count)
VERSION = ${MAJOR_VERSION}.${MINOR_VERSION}

.DEFAULT_GOAL:= bin/minim
.PHONY: test test-release deb deb-repo docs release docker-release clean
.PRECIOUS: %.cpp %.gcc %.clang %.ino

NOW = $(shell date '+%Y%m%d.%H%M')
SYS = $(shell uname)

OFLAGS = -O3 -fomit-frame-pointer -DNDEBUG
CFLAGS = -Wall -g $(OFLAGS)
CC32 = $(CC) -m32

ifeq ($(findstring MINGW32,$(SYS)),MINGW32)
LIBS = -lm libw32dl.a
else
LIBS = -lm -ldl
endif

.SUFFIXES:

bin/minim: tangle mkbin eval eval32 osdefs.k

run: bin/minim
	rlwrap ./eval

# tangle compiler generate src/ directory
tangle: minim.org
	emacs -nw -Q --batch --eval \
	"(progn                                                     \
           (require 'org)                                           \
           (require 'ob)                                            \
           (setq org-babel-use-quick-and-dirty-noweb-expansion t)   \
           (setq org-confirm-babel-evaluate nil)                    \
	   (when (locate-library \"ob-sh\")                         \
            (org-babel-do-load-languages                            \
              'org-babel-load-languages '((sh . t))))               \
	   (when (locate-library \"ob-shell\")                      \
            (org-babel-do-load-languages                            \
              'org-babel-load-languages '((shell . t))))            \
           (find-file \"minim.org\")                               \
           (org-babel-tangle))"

mkbin: 
	mkdir -p bin/

status: .force
	@echo "SYS is $(SYS)"

eval: src/bootstrap/eval.c src/bootstrap/gc.c src/bootstrap/gc.h src/bootstrap/buffer.c src/bootstrap/chartab.h src/bootstrap/wcs.c
	$(CC) -g $(CFLAGS) -o bin/eval src/bootstrap/eval.c $(LIBS)
	@-test ! -x /usr/sbin/execstack || /usr/sbin/execstack -s $@

eval32: src/bootstrap/eval.c src/bootstrap/gc.c src/bootstrap/gc.h src/bootstrap/buffer.c src/bootstrap/chartab.h src/bootstrap/wcs.c
	$(CC32) -g $(CFLAGS) -o bin/eval32 src/bootstrap/eval.c $(LIBS)
	@-test ! -x /usr/sbin/execstack || /usr/sbin/execstack -s $@

gceval: eval.c libgc.c buffer.c chartab.h wcs.c
	$(CC) -g $(CFLAGS) -DLIB_GC=1 -o gceval eval.c $(LIBS) -lgc
	@-test ! -x /usr/sbin/execstack || /usr/sbin/execstack -s $@

debug: .force
	$(MAKE) OFLAGS="-O0"

debuggc: .force
	$(MAKE) CFLAGS="$(CFLAGS) -DDEBUGGC=1"

profile: .force
	$(MAKE) clean eval CFLAGS="$(CFLAGS) -O3 -fno-inline-functions -DNDEBUG"
#	shark -q -1 -i ./eval emit.l eval.l eval.l eval.l eval.l eval.l eval.l eval.l eval.l eval.l eval.l > test.s
	shark -q -1 -i ./eval repl.l test-pepsi.l

osdefs.k: mkosdefs
	./bin/mkosdefs > bin/$@

mkosdefs: src/bootstrap/mkosdefs.c
	$(CC) -o bin/$@ $<

cg: eval .force
	./eval codegen5.l | tee test.s
	as test.s
	ld  --build-id --eh-frame-hdr -m elf_i386 --hash-style=both -dynamic-linker /lib/ld-linux.so.2 -o test /usr/lib/gcc/i486-linux-gnu/4.4.5/../../../../lib/crt1.o /usr/lib/gcc/i486-linux-gnu/4.4.5/../../../../lib/crti.o /usr/lib/gcc/i486-linux-gnu/4.4.5/crtbegin.o -L/usr/lib/gcc/i486-linux-gnu/4.4.5 -L/usr/lib/gcc/i486-linux-gnu/4.4.5 -L/usr/lib/gcc/i486-linux-gnu/4.4.5/../../../../lib -L/lib/../lib -L/usr/lib/../lib -L/usr/lib/gcc/i486-linux-gnu/4.4.5/../../.. a.out -lgcc --as-needed -lgcc_s --no-as-needed -lc -lgcc --as-needed -lgcc_s --no-as-needed /usr/lib/gcc/i486-linux-gnu/4.4.5/crtend.o /usr/lib/gcc/i486-linux-gnu/4.4.5/../../../../lib/crtn.o
	./test

test: src/emit.l src/eval.l bin/eval
	time ./bin/eval -O src/emit.l src/eval.l > test.s && $(CC32) -c -o test.o test.s && size test.o && $(CC32) -o test test.o

time: .force
	time ./bin/eval -O src/emit.l src/eval.l src/eval.l src/eval.l src/eval.l src/eval.l > /dev/null

test2: test .force
	time ./test -O src/boot.l src/emit.l src/eval.l > test2.s
	diff test.s test2.s

time2: .force
	time ./test src/boot.l src/emit.l src/eval.l src/eval.l src/eval.l src/eval.l src/eval.l > /dev/null

test-eval: test .force
	time ./test test-eval.l

test-boot: test .force
	time ./test boot-emit.l

test-emit: eval .force
	./emit.l test-emit.l | tee test.s && $(CC32) -c -o test.o test.s && size test.o && $(CC32) -o test test.o && ./test

peg.l: eval parser.l peg-compile.l peg-boot.l peg.g
	-rm peg.l.new
	./eval parser.l peg-compile.l peg-boot.l > peg.l.new
	-mv peg.l peg.l.$(shell date '+%Y%m%d.%H%M%S')
	mv peg.l.new peg.l

test-repl: eval peg.l .force
	./eval repl.l test-repl.l

test-peg: eval peg.l .force
	time ./eval parser.l peg.l test-peg.l > peg.n
	time ./eval parser.l peg.n test-peg.l > peg.m
	diff peg.n peg.m

test-compile-grammar:
	./eval compile-grammar.l test-dc.g > test-dc.g.l
	./eval compile-dc.l test.dc

test-compile-irl: eval32 irl.g.l .force
	./eval compile-irl.l test.irl > test.c
	$(CC32) -fno-builtin -g -o test test.c
	@echo
	./test

irl.g.l: tpeg.l irl.g
	./eval compile-tpeg.l irl.g > irl.g.l

test-compile-sirl: eval32 sirl.g.l .force
	./eval compile-sirl.l test.sirl > test.c
	$(CC32) -fno-builtin -g -o test test.c
	@echo
	./test

sirl.g.l: tpeg.l sirl.g
	./eval compile-tpeg.l sirl.g > sirl.g.l

test-ir: eval .force
	./eval test-ir.k > test.c
	$(CC32) -fno-builtin -g -o test test.c
	@echo
	./test

tpeg.l: tpeg.g compile-peg.l compile-tpeg.l
	time ./eval compile-peg.l  tpeg.g > tpeg.l.new
	-test -f tpeg.l && cp tpeg.l tpeg.l.$(NOW)
	mv tpeg.l.new tpeg.l
	time ./eval compile-tpeg.l tpeg.g > tpeg.ll
	sort tpeg.l > tpeg.ls
	sort tpeg.ll > tpeg.lls
	diff tpeg.ls tpeg.lls
	rm tpeg.ls tpeg.ll tpeg.lls

test-mach-o: eval32 .force
	./eval32 test-mach-o.l
	@echo
	size a.out
	chmod +x a.out
	@echo
	./a.out

test-elf: eval32 .force
	./eval32 test-elf.l
	@echo
	size a.out
	chmod +x a.out
	@echo
	./a.out

test-assembler: eval32 .force
	./eval32 assembler.k

test-recursion2:
	./eval compile-grammar.l test-recursion2.g > test-recursion2.g.l
	./eval compile-recursion2.l test-recursion2.txt

profile-peg: .force
	$(MAKE) clean eval CFLAGS="-O3 -fno-inline-functions -g -DNDEBUG"
	shark -q -1 -i ./eval parser.l peg.n test-peg.l > peg.m

stats: .force
	cat src/boot.l src/emit.l | sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
	cat src/eval.l | sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
	cat src/boot.l src/emit.l src/eval.l | sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l

clean: .force
	rm -rf src/ bin/ docs/ release/

#----------------------------------------------------------------

FILES = Makefile \
	src/bootstrap/wcs.c src/bootstrap/buffer.c src/bootstrap/chartab.h src/bootstrap/eval.c src/bootstrap/gc.c src/bootstrap/gc.h \
	src/boot.l src/emit.l src/eval.l test-emit.l \
	parser.l peg-compile.l peg-compile-2.l peg-boot.l peg.l test-peg.l test-repl.l \
	repl.l repl-2.l mpl.l sim.l \
	peg.g

DIST = maru-$(NOW)
DEST = ckpt/$(DIST)

dist: .force
	mkdir -p $(DEST)
	cp -p $(FILES) $(DEST)/.
	$(SHELL) -ec "cd ckpt; tar cvfz $(DIST).tar.gz $(DIST)"

.force:
