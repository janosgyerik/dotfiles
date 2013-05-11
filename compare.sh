#!/bin/sh

cd $(dirname "$0")

for i in .??*; do
    if test -f ~/$i; then
        cmp $i ~/$i >/dev/null || echo diff $i ~/$i
    fi
done
