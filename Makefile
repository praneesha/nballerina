BAL?=bal
LLVM_SUFFIX?=-12
CLANG?=clang$(LLVM_SUFFIX)
CFLAGS=-O2
JAVA?=$(shell test/findJava.sh)
TARGETS=all clean test regex
export CLANG CFLAGS BAL JAVA LLVM_SUFFIX
SUBDIRS=compiler.d runtime.d test.d extra/regex.d

all:
	$(MAKE) target=all compiler.d runtime.d

test clean:
	$(MAKE) target=$@ $(SUBDIRS)

test: all

regex:
	$(MAKE) target=all extra/regex.d

$(SUBDIRS):
	$(MAKE) -C $(basename $@) $(target)

.PHONY: $(TARGETS) $(SUBDIRS)
