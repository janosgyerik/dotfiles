#!/bin/sh

cd $(dirname "$0")

for i in .??*; do
    test -e ~/$i || echo unused $i
done
