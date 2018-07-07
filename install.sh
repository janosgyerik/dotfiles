#!/usr/bin/env bash
#

set -euo pipefail

usage() {
    local exitcode=0
    if [ $# != 0 ]; then
        echo "$@"
        exitcode=1
    fi
    echo "Usage: $0 [OPTION]... [ARG]..."
    echo
    echo "Install the specified files in $HOME"
    echo
    echo Options:
    echo
    echo "  -n, --dry-run  Do nothing, show what would happen, default = $dry_run"
    echo "  -f, --force    Skip interactive mode, perform selected action"
    echo "  -d, --diff     With --force, if file/dir exists, print the diff, default = $diff"
    echo "  -b, --backup   With --force, if file/dir exists, rename with .bak, default = $backup"
    echo "  -r, --replace  With --force, if file/dir exists, replace it, default = $replace"
    echo
    echo "  -l, --link     Symlink instead of copy, default = $link"
    echo "  -c, --copy     Copy instead of symlinks, default = ! $link"
    echo
    echo "  -h, --help     Print this help"
    echo
    exit $exitcode
}

args=()
dry_run=off
force=off
diff=off
backup=off
replace=off
link=on
while [ $# != 0 ]; do
    case "$1" in
    -h|--help) usage ;;
    -f|--force) force=on ;;
    -l|--link) link=on ;;
    --no-link) link=off ;;
    -c|--copy) link=off ;;
    --no-copy) link=on ;;
    -n|--dry-run) dry_run=on ;;
    -d|--diff) diff=on ;;
    --no-diff) diff=off ;;
    -b|--backup) backup=on ;;
    --no-backup) backup=off ;;
    -r|--replace) replace=on ;;
    --no-replace) replace=off ;;
    --) shift; while [ $# != 0 ]; do args+=("$1"); shift; done; break ;;
    -|-?*) usage "Unknown option: $1" ;;
    *) args+=("$1") ;;
    esac
    shift
done

set -- "${args[@]}"

script_dir=$(cd "$(dirname "$0")"; pwd)

all_dotfiles() {
    (cd "$script_dir" && git ls-files) | grep '^\.'
}

if [ $# = 0 ]; then
    set -- $(all_dotfiles)
fi

info() {
    echo "[info] $@"
}

warn() {
    echo "[warn] $@"
}

run_maybe() {
    if test $dry_run = off; then
        info "$@"
        "$@"
    else
        echo "[dry-run] $@"
    fi
}

_gvim() {
    if type gvim &> /dev/null; then
        gvim "$@"
    elif type mvim &> /dev/null; then
        mvim "$@"
    else
        warn "could not find gvim"
        return 1
    fi
}

decide_action() {
    local src=$1
    local dst=$2
    local basename=$3

    replace=off
    backup=off
    diff=off
    vimdiff=off
    gvimdiff=off

    cat << EOF
   What would you like to do ?  Your options are:
      R     : replace your version with the package maintainer's version
      K     : keep your current version
      B     : backup your current version and use the package maintainer's version
      D     : show the differences between the versions
      V     : run vimdiff
      G     : run gvim -d
EOF
    while true; do
        read -p "*** $basename (R/K/B/D/V/G) ? " choice

        case "$choice" in
            [rR]) replace=on ;;
            [kK]) ;;  # keep
            [bB]) backup=on ;;
            [dD]) diff -r "$dst" "$src" | less; continue ;;
            [vV]) vimdiff "$dst" "$src"; continue ;;
            [gG]) _gvim -d "$dst" "$src"; continue ;;
            *) continue ;;
        esac
        break
    done
}

handle_existing_file() {
    local src=$1
    local dst=$2
    local dotfile=$3

    if ! test -f "$dst"; then
        warn "mismatched kinds: $src is a file but $dst is not"
        return 1
    fi

    if cmp -s "$src" "$dst"; then
        info "target is the same: $dst"
        return 1
    fi

    read added removed <<< $(diff "$dst" "$src" | awk '/^</ {a++} /^>/ {r++} BEGIN {a=0; r=0} END {print a, r}')
    info "lines added/removed in $dst: $added/$removed"

    if test $dry_run = off && test $force = off; then
        decide_action "$src" "$dst" "$dotfile"
    fi

    if test $diff = on; then
        {
            echo "diff $dst $src"
            diff "$dst" "$src"
        } | less
        return 1
    elif test $backup = on; then
        run_maybe mv "$dst" "$dst".bak
        return 0
    elif test $replace = on; then
        run_maybe rm -fr "$dst"
        return 0
    fi

    return 1
}

for dotfile; do
    if ! test -f "$script_dir/$dotfile"; then
        warn "invalid file: $dotfile does not exist in $script_dir"
        continue
    fi
    src="$script_dir/$dotfile"
    dst="$HOME/$dotfile"

    if test -f "$dst"; then
        handle_existing_file "$src" "$dst" "$dotfile" || continue
    else
        dst_dir=$(dirname "$dst")
        test -d "$dst_dir" || run_maybe mkdir -p "$dst_dir"
    fi

    if test $link = on; then
        run_maybe ln -snf "$src" "$dst"
    else
        run_maybe cp "$src" "$dst"
    fi
done
