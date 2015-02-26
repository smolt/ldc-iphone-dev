# Make main LDC stuff for IPhoneOS and support packages

# The llvm-config program.  Change this if llvm is configured
# differently (e.g. Debug+Asserts)
LLVM_CONFIG = build/llvm/Release/bin/llvm-config


all: support ldc-all

clean: ldc-clean

distclean:
	-rm -Rf build
	$(MAKE) -C iphoneos-apple-support clean

unittest: unittest-debug unittest-release

unittest-debug: all
	$(MAKE) -C build/ldc druntime-ldc-unittest-debug phobos2-ldc-unittest-debug
	tools/collect-unittests debug build

unittest-release: all
	$(MAKE) -C build/ldc druntime-ldc-unittest phobos2-ldc-unittest
	tools/collect-unittests release build

.PHONY: all clean distclean unittest unittest-debug unittest-release

# ldc submakes

ldc-%: build/ldc/Makefile 
	$(MAKE) -C build/ldc $(@:ldc-%=%)

build/ldc/Makefile: $(LLVM_CONFIG)
	mkdir -p build/ldc
	tools/prepmake-ldc

# support packages - treat llvm different because it is so big.  Only
# do submake in llvm if it doesn't appear to be built.  I assume llvm
# won't be changing much and you can always do a direct make in the
# subpackage if something changes (e.g. make llvm-all)

.PHONY: support

support: $(LLVM_CONFIG)
	$(MAKE) -C iphoneos-apple-support

iphoneos-apple-support/libiphoneossup.a:
	$(MAKE) -C iphoneos-apple-support

# Use non-existence of llvm-config to decide if llvm needs to be built

$(LLVM_CONFIG):
	$(MAKE) llvm-all

# llvm submakes

llvm-%: build/llvm/Makefile
	$(MAKE) -C build/llvm $(@:llvm-%=%)

build/llvm/Makefile:
	mkdir -p build/llvm
	tools/prepmake-llvm

# emacs stuff

.PHONY: etags

etags:
	cd llvm && etags `find include lib -name '*.[hc]' -o -name '*.cpp'`
	cd llvm && if [ -d tools/clang ]; then \
	    etags --append \
	    `find tools/clang/{include,lib} -name '*.[hc]' -o -name '*.cpp'`; \
	  fi
	cd ldc && etags -i ../llvm/TAGS `find . -name '*.[hc]' -o -name '*.cpp'`
