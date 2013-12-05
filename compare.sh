#!/bin/sh

cd $(dirname "$0")

for i in .??*; do
    if test -f ~/$i; then
        if ! cmp $i ~/$i >/dev/null; then
            echo diff $i ~/$i
            echo gvim -d $i ~/$i
        fi
    fi
done
