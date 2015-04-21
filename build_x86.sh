#~/bin/bash
export ARCH=x86
cp Makefile.am.x86 Makefile.am
cp tests/Makefile.am.x86 tests/Makefile.am

./configure --enable-sse --enable-single
automake --add-missing
make
#recover these auto-gen files
#git checkout Makefile.in
#git checkout aclocal.m4
#git checkout config.h.in
#git checkout java/Makefile.in
#git checkout src/Makefile.in
#git checkout tests/Makefile.in
#git checkout configure
