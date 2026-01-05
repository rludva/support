!/bin/bash

# Power On function..
on() {
    [[ -z "$1" ]] && { echo "Usage: on <host>"; return 1; }
    mwol.sh "$1"
}

# Power Off function..
off() {
    [[ -z "$1" ]] && { echo "Usage: off <host>"; return 1; }
    moff.sh "$1"
}

# Universal alias for on/off..
a() {
    [[ -z "$1" || -z "$2" ]] && { echo "Usage: a {on|off} <host>"; return 1; }
    [[ "$1" == "on" ]] && on "$2"
    [[ "$1" == "off" ]] && off "$2"
}

_get_mwol_conf() {
    if [[ -f "./mwol.conf" ]]; then
        echo "./mwol.conf"
    elif [[ -f "$HOME/.mwol.conf" ]]; then
        echo "$HOME/.mwol.conf"
    elif [[ -f "/etc/mwol.conf" ]]; then
        echo "/etc/mwol.conf"
    fi
}

_get_host_groups() {
    local config=$(_get_mwol_conf)
    [[ -f "$config" ]] && bash -c "source $config; echo \${!HOST_GROUPS[@]}"
}

_on_off_comp() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=( $(compgen -W "$(_get_host_groups)" -- "$cur") )
}

_a_comp() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case $COMP_CWORD in
        1) COMPREPLY=( $(compgen -W "on off" -- "$cur") )
            ;;
        2) COMPREPLY=( $(compgen -W "$(_get_host_groups)" -- "$cur") )
            ;;
    esac
}

# Registration..
complete -F _on_off_comp  on
complete -F _on_off_comp  off
complete -F _a_comp       a
