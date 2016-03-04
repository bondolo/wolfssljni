#!/bin/bash

OS=`uname`
ARCH=`uname -m`

# set up Java include and library paths for OS X and Linux
# NOTE: you may need to modify these if your platform uses different locations
if [ "$OS" == "Darwin" ] ; then
    javaHome=$(/usr/libexec/java_home)
    javaIncludes="-I$javaHome/include -I$javaHome/include/darwin"
    javaLibs="-dynamiclib -framework JavaVM"
    jniLibName="libwolfssl.jnilib"
    cflags="-DHAVE_ECC"
    fpic=""
elif [ "$OS" == "Linux" ] ; then
    javaHome=$(echo $(dirname $(dirname $(dirname $(readlink -f $(which java))))))
    javaIncludes="-I$javaHome/include -I$javaHome/include/linux"
    javaLibs="-shared"
    jniLibName="libwolfSSL.so"
    cflags="-DHAVE_ECC -DUSE_FAST_MATH"
    if [ "$ARCH" == "x86_64" ] ; then
        fpic="-fPIC"
    else
        fpic=""
    fi
else
    echo 'Unknown host OS!'
    exit
fi

if [ "$(pkg-config --version || echo 'no pkg-config')" != "no pkg-config" ]; then
    wolfsslcflags="$(pkg-config --cflags wolfssl)"
    wolfssllibs="$(pkg-config --libs wolfssl)"
else
    wolfsslcflags=""
    wolfssllibs="-lwolfssl"
fi

# create /lib directory if doesn't exist
mkdir -p ./lib

objFiles="./native/com_wolfssl_WolfSSL.o ./native/com_wolfssl_WolfSSLSession.o ./native/com_wolfssl_WolfSSLContext.o ./native/com_wolfssl_wolfcrypt_RSA.o ./native/com_wolfssl_wolfcrypt_ECC.o"
rm -f ${objFiles}
gcc -DWOLFSSL_DTLS -Wall -c $fpic $cflags $wolfsslcflags ./native/com_wolfssl_WolfSSL.c -o ./native/com_wolfssl_WolfSSL.o $javaIncludes
gcc -DWOLFSSL_DTLS -Wall -c $fpic $cflags $wolfsslcflags ./native/com_wolfssl_WolfSSLSession.c -o ./native/com_wolfssl_WolfSSLSession.o $javaIncludes
gcc -DWOLFSSL_DTLS -Wall -c $fpic $cflags $wolfsslcflags ./native/com_wolfssl_WolfSSLContext.c -o ./native/com_wolfssl_WolfSSLContext.o $javaIncludes
gcc -DWOLFSSL_DTLS -Wall -c $fpic $cflags $wolfsslcflags ./native/com_wolfssl_wolfcrypt_RSA.c -o ./native/com_wolfssl_wolfcrypt_RSA.o $javaIncludes
gcc -DWOLFSSL_DTLS -Wall -c $fpic $cflags $wolfsslcflags ./native/com_wolfssl_wolfcrypt_ECC.c -o ./native/com_wolfssl_wolfcrypt_ECC.o $javaIncludes
gcc -Wall $wolfssllibs $javaLibs $cflags $wolfsslcflags -o ./lib/$jniLibName  ${objFiles}

