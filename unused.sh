#!/bin/sh

cd "$(dirname "$0")"

all_dotfiles() {
    (cd "$script_dir" && git ls-files) | grep '^\.'
}

for f in $(all_dotfiles); do
    test -e ~/"$f" || echo "$f"
done
