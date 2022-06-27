#!/bin/bash
nim c --app:lib -d:release --opt:size --gc:orc -d:strip -o:nimpeg.so nimpeg
../../build/Debug/bin/pocket test