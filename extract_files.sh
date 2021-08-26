#!/bin/sh
    filename=../modelrunner.tex
    
    for n in `mintangle -L $filename | egrep ".sh$"`; do
        mintangle -r $n $filename
        chmod +x $n
    done #extract shell scripts from $filename

    
    for n in `mintangle -L $filename | egrep -v ".sh$"`; do
        mintangle -r $n $filename
    done

