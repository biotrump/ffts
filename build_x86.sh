#~/bin/bash
if [ -z "$TARGET_ARCH" ];then
export TARGET_ARCH=x86_64
fi
export ARCH=x86
#check if build_x86 exists,
#if it's build_x86, rmdir and copy a fresh one and rebuild again
#mkdir ../build_$ARCH
#cp -rf * ../build_x86
#mv ../build_x86 .
echo build_${TARGET_ARCH}
if [ -d build_${TARGET_ARCH} ];then
pushd build_${TARGET_ARCH}
rm -rf *
popd
else
mkdir -p build_${TARGET_ARCH}
fi
pushd build_${TARGET_ARCH}
#clone the upper repo but discard .git
git clone --depth=1 .. .
rm -rf .git .gitignore

cp Makefile.am.${ARCH} Makefile.am
cp tests/Makefile.am.${ARCH} tests/Makefile.am

#confiure and build
./configure --enable-sse --enable-single
automake --add-missing
make

popd

#ln build_${TARGET_ARCH}/libffts-x86.a to lib
if [ ! -d lib ];then
	mkdir -p lib
fi

if [ -L lib/libffts-${ARCH}.a ];then
	rm -f lib/libffts-${ARCH}.a
fi

if [ -n "$FFTS_OUT" ]; then
	rm -f ${FFTS_OUT}/libffts-${TARGET_ARCH}.a
	cp `pwd`/build_${TARGET_ARCH}/lib/libffts-${ARCH}.a ${FFTS_OUT}/libffts-${TARGET_ARCH}.a
else
	rm -f lib/libffts-${TARGET_ARCH}.a
	ln -s `pwd`/build_${TARGET_ARCH}/lib/libffts-${ARCH}.a lib/libffts-${TARGET_ARCH}.a
fi