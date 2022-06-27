#!/bin/bash
gcc -fPIC -c libpeg.c pknative.c -I../../../src/include/
gcc -shared -o peg.so libpeg.o pknative.o
rm *.o
/workspace/pocketlang/build/Debug/bin/pocket main
