#!/bin/sh
# Compiles ffts for Android
# Make sure you have NDK_ROOT defined in .bashrc or .bash_profile
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
NDK_ROOT=${NDK_ROOT:-/home/thomas/aosp/NDK/android-ndk-r10d}
export NDK_ROOT
#gofortran is supported in r9
#export NDK_ROOT=/home/thomas/aosp/NDK/android-ndk-r9

INSTALL_DIR="`pwd`/java/android/bin"

#PLATFORM=android-8
#PLATFORM=android-9
#android 4.0.1 ICS and above
PLATFORM=android-14
#TOOL="4.6"
TOOL="4.8"

cp Makefile.am.and Makefile.am
cp tests/Makefile.am.and tests/Makefile.am

case $(uname -s) in
  Darwin)
    CONFBUILD=i386-apple-darwin`uname -r`
    HOSTPLAT=darwin-x86
  ;;
  Linux)
    CONFBUILD=x86-unknown-linux
    HOSTPLAT=linux-`uname -m`
  ;;
  *) echo $0: Unknown platform; exit
esac

arm=${arm:-arm}
echo arm=$arm
case arm in
  arm)
    TARGPLAT=arm-linux-androideabi
    ARCH=arm
    CONFTARG=arm-eabi
  ;;
  x86)
    TARGPLAT=x86
    ARCH=x86
    CONFTARG=x86
  ;;
  mips)
  ## probably wrong
    TARGPLAT=mipsel-linux-android
    ARCH=mips
    CONFTARG=mips
  ;;
  *) echo $0: Unknown target; exit
esac

: ${NDK_ROOT:?}

echo "Using: $NDK_ROOT/toolchains/${TARGPLAT}-${TOOL}/prebuilt/${HOSTPLAT}/bin"
export ARCH
export PATH="$NDK_ROOT/toolchains/${TARGPLAT}-${TOOL}/prebuilt/${HOSTPLAT}/bin/:$PATH"
export SYS_ROOT="$NDK_ROOT/platforms/${PLATFORM}/arch-${ARCH}/"
export CC="${TARGPLAT}-gcc --sysroot=$SYS_ROOT"
export LD="${TARGPLAT}-ld"
export AR="${TARGPLAT}-ar"
export RANLIB="${TARGPLAT}-ranlib"
export STRIP="${TARGPLAT}-strip"
export CFLAGS="-Os"
export AM_ANDROID_EXTRA="-llog -fPIE -pie"
#Some influential environment variables to configure
#export LIBS="-lc -lgcc -llog -fPIE -pie"
#export LDFLAGS="-mhard-float -D_NDK_MATH_NO_SOFTFP=1 -march=armv7-a -mfloat-abi=hard"
#export CFLAGS="-mhard-float -D_NDK_MATH_NO_SOFTFP=1 -march=armv7-a -mfloat-abi=hard"
mkdir -p $INSTALL_DIR
#./configure --enable-neon --build=${CONFBUILD} --host=${CONFTARG} --prefix=$INSTALL_DIR LIBS="-lc -lgcc"
./configure --enable-neon --build=${CONFBUILD} --host=${CONFTARG}

automake --add-missing
make clean
make
#recover these auto-gen files

#git checkout Makefile.in
#git checkout aclocal.m4
#git checkout config.h.in
#git checkout java/Makefile.in
#git checkout src/Makefile.in
#git checkout tests/Makefile.in

#make install
export ANDROID_HOME=/home/thomas/aosp/4.4.2_r2/prebuilts/devtools
export ANDROID_SWT=/home/thomas/aosp/4.4.2_r2/prebuilts/tools/linux-x86_64/swt

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
exit 0
