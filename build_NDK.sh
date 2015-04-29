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

INSTALL_DIR="`pwd`/java/android/bin"

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
export NDK_ROOT=${HOME}/NDK/android-ndk-r10d
#gofortran is supported in r9
#export NDK_ROOT=${HOME}/NDK/android-ndk-r9
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


#default is arm
export ARCH=${ARCH:-x86}
echo ARCH=$ARCH
export SYS_ROOT="${NDK_ROOT}/platforms/${ANDROID_APIVER}/arch-${ARCH}/"
case $ARCH in
  arm)
    TARGPLAT=arm-linux-androideabi
    CONFTARG=arm-eabi
echo "Using: $NDK_ROOT/toolchains/${TARGPLAT}-${TOOL_VER}/prebuilt/${HOSTPLAT}/bin"
export ARCH
#export PATH="$NDK_ROOT/toolchains/${TARGPLAT}-${TOOL_VER}/prebuilt/${HOSTPLAT}/bin/:\
#$NDK_ROOT/toolchains/${TARGPLAT}-${TOOL_VER}/prebuilt/${HOSTPLAT}/${TARGPLAT}/bin/:$PATH"
export PATH="${NDK_ROOT}/toolchains/${TARGPLAT}-${TOOL_VER}/prebuilt/${HOSTPLAT}/bin/:$PATH"
echo $PATH

  ;;
  x86)
    TARGPLAT=i686-linux-android
    CONFTARG=x86
echo "Using: $NDK_ROOT/toolchains/x86-${TOOL_VER}/prebuilt/${HOSTPLAT}/bin"
export PATH="${NDK_ROOT}/toolchains/x86-${TOOL_VER}/prebuilt/${HOSTPLAT}/bin/:$PATH"
echo $PATH
export  CCAS="${TARGPLAT}-as"
export  CCASFLAGS="--64 -march=i686+sse3"

  ;;
  mips)
  ## probably wrong
    TARGPLAT=mipsel-linux-android
    CONFTARG=mips
  ;;
  *) echo $0: Unknown target; exit
esac
#: ${NDK_ROOT:?}


#export CC="${TARGPLAT}-gcc -Wa,--64 --sysroot=$SYS_ROOT"
export CC="${TARGPLAT}-gcc  --sysroot=$SYS_ROOT"
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
mkdir -p $INSTALL_DIR

#mkdir a build folder
echo build_NDK_${ARCH}
if [ -d build_NDK_${ARCH} ];then
pushd build_NDK_${ARCH}
rm -rf *
popd
else
mkdir build_NDK_${ARCH}
fi

pushd build_NDK_${ARCH}

#clone the upper repo but discard .git
git clone --depth=1 .. .
rm -rf .git .gitignore

cp Makefile.am.and Makefile.am
cp tests/Makefile.am.and tests/Makefile.am

#./configure --enable-neon --build=${CONFBUILD} --host=${CONFTARG} --prefix=$INSTALL_DIR LIBS="-lc -lgcc"
#./configure --enable-neon --build=${CONFBUILD} --host=${CONFTARG}
./configure --enable-sse --enable-single

automake --add-missing
make

popd

#ln build_${ARCH}/libffts-x86.a to lib
if [ ! -d lib ];then
mkdir lib
fi

if [ -L lib/libffts-NDK-${ARCH}.a ];then
rm lib/libffts-NDK-${ARCH}.a
fi

ln -s `pwd`/build_${ARCH}/lib/libffts-${ARCH}.a lib/libffts-NDK-${ARCH}.a


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
