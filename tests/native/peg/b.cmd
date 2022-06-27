gcc -fPIC -c libpeg.c pknative.c -I../../../src/include/
gcc -shared -o peg.dll libpeg.o pknative.o
rm *.o
..\..\..\build\Debug\bin\pocket example2
