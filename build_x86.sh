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
if [ -z "$FFTS_DIR" ]; then
	export FFTS_DIR=`pwd`
fi

if [ -z "$FFTS_OUT" ]; then
	export FFTS_OUT=build_${TARGET_ARCH}
	if [ -d $FFTS_OUT ];then
		rm -rf $FFTS_OUT/*
	else
		mkdir -p $FFTS_OUT
	fi
	local_build=1
fi

#if [ -f ${FFTS_OUT}/lib/libffts-${ARCH}.a ]; then
rm -f ${FFTS_OUT}/lib/libffts-${ARCH}.a
rm -f ${FFTS_OUT}/src/libffts.la
#	rm -rf ${FFTS_OUT}/src/.libs
#fi

#clone the upper repo but discard .git
git clone --depth=1 ${FFTS_DIR} ${FFTS_OUT}
pushd ${FFTS_OUT}
rm -rf .git .gitignore

cp Makefile.am.${ARCH} Makefile.am
cp tests/Makefile.am.${ARCH} tests/Makefile.am

#confiure and build
./configure --enable-sse --enable-single
automake --add-missing
make

if [ "$local_build" == "1" ]; then
	popd

	#ln build_${TARGET_ARCH}/libffts-x86.a to lib
	if [ ! -d lib ];then
		mkdir -p lib
	fi

	if [ -L lib/libffts-${TARGET_ARCH}.a ];then
		rm -f lib/libffts-${TARGET_ARCH}.a
	fi

	ln -s ${FFTS_OUT}/lib/libffts-${ARCH}.a lib/libffts-${TARGET_ARCH}.a

else
	rm -f lib/libffts-${TARGET_ARCH}.a
	ln -s ${FFTS_OUT}/lib/libffts-${ARCH}.a lib/libffts-${TARGET_ARCH}.a
fi