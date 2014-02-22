#!/usr/bin/env sh

exit_with_usage ()
{
    echo "Usage: $0 [ignored.py] --prefix|--exec-prefix|--includes|--libs|--cflags|--ldflags|--extension-suffix|--help|--abiflags|--configdir"
    exit 1
}

case "$1" in
    *.py)
        shift
    ;;
esac

if [ "$1" = "" ] ; then
    exit_with_usage
fi

# Returns the actual prefix where this script was installed to.
installed_prefix ()
{
    local RESULT=$(dirname $(cd $(dirname "$1") && pwd -P))
    local READLINK=readlink
    if [ "$(uname -s)" = "Darwin" ] ; then
        # readlink in darwin can't handle -f.  Use greadlink from MacPorts instead.
        READLINK=greadlink
    fi
    if [ $(which $READLINK) ] ; then
        RESULT=$($READLINK -f "$RESULT")
    fi
    echo $RESULT
}

prefix_build="/tmp/x32-481-posix-dwarf-r5/mingw32/opt"
prefix_real=$(installed_prefix "$0")

# Use sed to fix paths from their built to locations to their installed to locations.
prefix=$(echo "$prefix_build" | sed "s#$prefix_build#$prefix_real#")
exec_prefix_build="${prefix}"
exec_prefix=$(echo "$exec_prefix_build" | sed "s#$exec_prefix_build#$prefix_real#")
includedir=$(echo "${prefix}/include" | sed "s#$prefix_build#$prefix_real#")
libdir=$(echo "${exec_prefix}/lib" | sed "s#$prefix_build#$prefix_real#")
CFLAGS=$(echo "-O2 -pipe -I/tmp/x32-481-posix-dwarf-r5/libs/include -I/tmp/mingw-prereq/x32-zlib/include -I/tmp/mingw-prereq/i686-w64-mingw32-static/include -fwrapv -DNDEBUG -D__USE_MINGW_ANSI_STDIO=1" | sed "s#$prefix_build#$prefix_real#")
VERSION="2.7"
LIBM=""
LIBC=""
SYSLIBS="$LIBM $LIBC"
ABIFLAGS="@ABIFLAGS@"
# Protect against lack of substitution.
if [ "$ABIFLAGS" = "@ABIFLAGS@" ] ; then
    ABIFLAGS=
fi
LIBS=" $SYSLIBS -lpython${VERSION}${ABIFLAGS}"
BASECFLAGS=" -fno-strict-aliasing"
LDLIBRARY="libpython${VERSION}.dll.a"
LINKFORSHARED="-Wl,--out-implib=${LDLIBRARY}"
OPT="-DNDEBUG "
PY_ENABLE_SHARED="1"
DLLLIBRARY="libpython${VERSION}.dll"
LIBDEST=${prefix}/lib/python${VERSION}
LIBPL=${LIBDEST}/config
SO=".pyd"
PYTHONFRAMEWORK=""
INCDIR="-I$includedir/python${VERSION}${ABIFLAGS}"
PLATINCDIR="-I$includedir/python${VERSION}${ABIFLAGS}"

# Scan for --help or unknown argument.
for ARG in $*
do
    case $ARG in
        --help)
            exit_with_usage
        ;;
        --prefix|--exec-prefix|--includes|--libs|--cflags|--ldflags)
        ;;
        *)
            exit_with_usage
        ;;
    esac
done

for ARG in $*
do
    case $ARG in
        --prefix)
            echo "$prefix"
        ;;
        --exec-prefix)
            echo "$exec_prefix"
        ;;
        --includes)
            echo "$INCDIR"
        ;;
        --cflags)
            echo "$INCDIR $BASECFLAGS $CFLAGS $OPT"
        ;;
        --libs)
            echo "$LIBS"
        ;;
        --ldflags)
            LINKFORSHAREDUSED=
            if [ -z "$PYTHONFRAMEWORK" ] ; then
                LINKFORSHAREDUSED=$LINKFORSHARED
            fi
            LIBPLUSED=
            if [ "$PY_ENABLE_SHARED" = "0" -o -n "${DLLLIBRARY}" ] ; then
                LIBPLUSED="-L$LIBPL"
            fi
            echo "$LIBPLUSED -L$libdir $LIBS $LINKFORSHAREDUSED"
        ;;
esac
done
