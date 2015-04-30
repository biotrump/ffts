#~/bin/bash
export ARCH=x86
#check if build_x86 exists,
#if it's build_x86, rmdir and copy a fresh one and rebuild again
#mkdir ../build_$ARCH
#cp -rf * ../build_x86
#mv ../build_x86 .
echo build_${ARCH}
if [ -d build_${ARCH} ];then
pushd build_${ARCH}
rm -rf *
popd
else
mkdir build_${ARCH}
fi
pushd build_${ARCH}
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

#ln build_${ARCH}/libffts-x86.a to lib
if [ ! -d lib ];then
	mkdir lib
fi

if [ -L lib/libffts-${ARCH}.a ];then
	rm -f lib/libffts-${ARCH}.a
fi

ln -s `pwd`/build_${ARCH}/lib/libffts-${ARCH}.a lib/libffts-${ARCH}.a
