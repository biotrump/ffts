#!/bin/bash
# Compiles ffts for Android
# Make sure you have NDK_ROOT defined in .bashrc or .bash_profile
#export CMAKE_BUILD_TYPE "Debug"
export CMAKE_BUILD_TYPE="Release"

#get cpu counts
case $(uname -s) in
  Darwin)
    CONFBUILD=i386-apple-darwin`uname -r`
    HOSTPLAT=darwin-x86
    CORE_COUNT=`sysctl -n hw.ncpu`
  ;;
  Linux)
    CONFBUILD=x86-unknown-linux
    HOSTPLAT=linux-`uname -m`
    CORE_COUNT=`grep processor /proc/cpuinfo | wc -l`
  ;;
CYGWIN*)
	CORE_COUNT=`grep processor /proc/cpuinfo | wc -l`
	;;
  *) echo $0: Unknown platform; exit
esac

#INSTALL_DIR="`pwd`/java/android/bin"

# Modify INSTALL_DIR to suit your situation
#Lollipop	5.0 - 5.1	API level 21, 22
#KitKat	4.4 - 4.4.4	API level 19
#Jelly Bean	4.3.x	API level 18
#Jelly Bean	4.2.x	API level 17
#Jelly Bean	4.1.x	API level 16
#Ice Cream Sandwich	4.0.3 - 4.0.4	API level 15, NDK 8
#Ice Cream Sandwich	4.0.1 - 4.0.2	API level 14, NDK 7
#Honeycomb	3.2.x	API level 13
#Honeycomb	3.1	API level 12, NDK 6
#Honeycomb	3.0	API level 11
#Gingerbread	2.3.3 - 2.3.7	API level 10
#Gingerbread	2.3 - 2.3.2	API level 9, NDK 5
#Froyo	2.2.x	API level 8, NDK 4

if [ -z "${NDK_ROOT}"  ]; then
	export NDK_ROOT=${HOME}/NDK/android-ndk-r10d
	#export NDK_ROOT=${HOME}/NDK/android-ndk-r9
fi
export ANDROID_NDK=${NDK_ROOT}

if [[ ${NDK_ROOT} =~ .*"-r9".* ]]
then
#ANDROID_APIVER=android-8
#ANDROID_APIVER=android-9
#android 4.0.1 ICS and above
ANDROID_APIVER=android-14
#TOOL_VER="4.6"
#gfortran is in r9d V4.8.0
TOOL_VER="4.8.0"
else
#android 4.0.1 ICS and above
ANDROID_APIVER=android-14
TOOL_VER="4.9"
fi

if [ $# -ge 1 ]; then
	export ARCH=$1
else
#default
	export ARCH=arm
fi
echo ARCH=$ARCH

#default is arm
case $ARCH in
  arm)
    TARGPLAT=arm-linux-androideabi
    CONFTARG=arm-eabi
	echo "Using: $NDK_ROOT/toolchains/${TARGPLAT}-${TOOL_VER}/prebuilt/${HOSTPLAT}/bin"
	#export PATH="$NDK_ROOT/toolchains/${TARGPLAT}-${TOOL_VER}/prebuilt/${HOSTPLAT}/bin/:\
	#$NDK_ROOT/toolchains/${TARGPLAT}-${TOOL_VER}/prebuilt/${HOSTPLAT}/${TARGPLAT}/bin/:$PATH"
	export PATH="${NDK_ROOT}/toolchains/${TARGPLAT}-${TOOL_VER}/prebuilt/${HOSTPLAT}/bin/:$PATH"
  ;;
  x86)
    TARGPLAT=i686-linux-android
    CONFTARG=x86
	echo "Using: $NDK_ROOT/toolchains/x86-${TOOL_VER}/prebuilt/${HOSTPLAT}/bin"
	export PATH="${NDK_ROOT}/toolchains/x86-${TOOL_VER}/prebuilt/${HOSTPLAT}/bin/:$PATH"
#specify assembler for x86 SSE3, but ffts's sse.s needs 64bit x86.
#intel atom z2xxx and the old atoms are 32bit, so 64bit x86 in android can't work in
#most atom devices.
#http://forum.cvapp.org/viewtopic.php?f=13&t=423&sid=4c47343b1de899f9e1b0d157d04d0af1
	export  CCAS="${TARGPLAT}-as"
#	export  CCASFLAGS="--64 -march=i686+sse3"
	export  CCASFLAGS="--64"

  ;;
  mips)
  ## probably wrong
    TARGPLAT=mipsel-linux-android
    CONFTARG=mips
  ;;
  *) echo $0: Unknown target; exit
esac
#: ${NDK_ROOT:?}
echo $PATH

export SYS_ROOT="${NDK_ROOT}/platforms/${ANDROID_APIVER}/arch-${ARCH}/"
export CC="${TARGPLAT}-gcc --sysroot=$SYS_ROOT"
export LD="${TARGPLAT}-ld"
export AR="${TARGPLAT}-ar"
export RANLIB="${TARGPLAT}-ranlib"
export STRIP="${TARGPLAT}-strip"
#export CFLAGS="-Os -fPIE"
export CFLAGS="-Os -fPIE --sysroot=$SYS_ROOT"
export CXXFLAGS="-fPIE --sysroot=$SYS_ROOT"
export FORTRAN="${TARGPLAT}-gfortran --sysroot=$SYS_ROOT"

#!!! quite importnat for cmake to define the NDK's fortran compiler.!!!
#Don't let cmake decide it.
export FC=${FORTRAN}
export AM_ANDROID_EXTRA="-llog -fPIE -pie"

#Some influential environment variables to configure
#export LIBS="-lc -lgcc -llog -fPIE -pie"
#export LDFLAGS="-mhard-float -D_NDK_MATH_NO_SOFTFP=1 -march=armv7-a -mfloat-abi=hard"
#export CFLAGS="-mhard-float -D_NDK_MATH_NO_SOFTFP=1 -march=armv7-a -mfloat-abi=hard"
#mkdir -p $INSTALL_DIR

if [ -z "$FFTS_DIR" ]; then
	export FFTS_DIR=`pwd`
fi

if [ -z "$FFTS_OUT" ]; then
	export FFTS_OUT=build_${TARGET_ARCH}
	local_build=1
fi
#check if it needs a clean build?
if [ -d "$FFTS_OUT" ]; then
	if [ ! -f $FFTS_OUT/.TOS-NDK ]; then
		rm -rf $FFTS_OUT/*
	fi
else
	mkdir -p $FFTS_OUT
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

cp Makefile.am.and Makefile.am
cp tests/Makefile.am.and tests/Makefile.am

#./configure --enable-neon --build=${CONFBUILD} --host=${CONFTARG} --prefix=$INSTALL_DIR LIBS="-lc -lgcc"
case $ARCH in
  arm)
  ./configure --enable-neon --build=${CONFBUILD} --host=${CONFTARG}
  ;;
  x86)
#  ./configure --enable-sse --enable-single --build=${CONFBUILD} --host=${CONFTARG}
  ./configure --enable-sse --build=${CONFBUILD} --host=${CONFTARG}
  ;;
  mips)
  ;;
  *) echo $0: Unknown target; exit
esac

automake --add-missing
make
echo "$ARCH" >> $FFTS_OUT/.TOS-NDK
if [ "$local_build" == "1" ]; then
	popd

	#ln build_${TARGET_ARCH}/libffts-x86.a to lib
	if [ ! -d lib ];then
		mkdir -p lib
	fi

	if [ -L lib/libffts-NDK-${TARGET_ARCH}.a ];then
		rm -f lib/libffts-NDK-${TARGET_ARCH}.a
	fi

	ln -s ${FFTS_OUT}/lib/libffts-${ARCH}.a lib/libffts-NDK-${TARGET_ARCH}.a

else
	rm -f ${FFTS_OUT}/lib/libffts-NDK-${TARGET_ARCH}.a
	ln -s ${FFTS_OUT}/lib/libffts-${ARCH}.a ${FFTS_OUT}/lib/libffts-NDK-${TARGET_ARCH}.a
	popd
fi

#make install
export ANDROID_HOME=${HOME}/aosp/4.4.2_r2/prebuilts/devtools
export ANDROID_SWT=${HOME}/aosp/4.4.2_r2/prebuilts/tools/linux-x86_64/swt

if [ -n "$JNI_SUPPORT" ];then
if [ -z "$ANDROID_HOME" ] ; then
    echo ""
    echo " No ANDROID_HOME defined"
    echo " Android JNI interfaces will not be built"
    echo
else
    echo
    echo "Using android_home ${ANDROID_HOME}"
    echo
    ( cd java/android ; ${ANDROID_HOME}/tools/android update lib-project -p . ) || exit 1
    ( cd java/android/jni ; ${NDK_ROOT}/ndk-build V=1 ) || exit 1
    ( cd java/android ; ant release ) || exit 1
    echo
    echo "Android library project location:"
    echo " `pwd`/java/android"
    echo
fi
fi
