#!/bin/bash

display_help() {
    cat <<EOF
tdo: Todos and Notes, Blazingly Fast! 📃🚀

Usage: tdo [options] [arguments]

Options:
-f | --find | f | find:    searches for argument in notes
-t | --todo | t | todo:    shows all pending todos
-h | --help | h | help:    shows this help message

Example:
# opens today's todo file
tdo
# opens the note for vim in tech dir
tdo tech/vim
# shows all pending todos
tdo t
# searches for neovim in all notes
tdo s neovim
EOF
}

check_command() {
    if ! command -v "$1" &>/dev/null; then
        echo "Error: The $1 command is not available. Make sure it is installed."
        exit 1
    fi
}

search() {
    if [ -z "$1" ]; then
        echo "Error: Please provide a search term."
        exit 1
    fi

    cd "$NOTES_DIR" || return
    rg -l --sort created "$1" |
        fzf --bind "enter:execute($EDITOR {})" \
            --preview "bat --color=always --style=numbers --line-range :500 {}"
    cd - >/dev/null || return
}

pending_todos() {
    cd "$NOTES_DIR" || return
    rg -l --sort created --glob '!templates/*' '\[ \]' |
        fzf --bind "enter:execute($EDITOR {})" --preview 'rg -e "\[ \]" {}'
    cd - >/dev/null || return
}

new_todo() {
    cd "$NOTES_DIR" || return
    year=$(date +%Y)
    month=$(date +%m)
    today=$(date +%Y-%m-%d)
    todo_file="log/$year/$month/$today.md"

    if [ ! -f "$todo_file" ]; then
        cp notes/templates/todo.md "$todo_file"
    fi
    mkdir -p "$(dirname "$todo_file")"
    $EDITOR "$todo_file"
    cd - >/dev/null || return
}

new_note() {
    cd "$NOTES_DIR" || return
    notes_file="notes/$1.md"

    if [ ! -f "$notes_file" ]; then
        cp notes/templates/note.md "$notes_file"
    fi
    mkdir -p "$(dirname "$notes_file")"
    $EDITOR "$notes_file"
    cd - >/dev/null || return
}

main() {
    check_command "rg"
    check_command "fzf"
    check_command "bat"

    case "$1" in
    -h | --help | h | help)
        display_help
        exit 0
        ;;
    -f | --find | f | find)
        search "$2"
        exit 0
        ;;
    -t | --todo | t | todo)
        pending_todos
        exit 0
        ;;
    "")
        new_todo
        exit 0
        ;;
    *)
        new_note "$1"
        ;;
    esac
}

main "$@"
