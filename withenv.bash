# This file should be sourced so these functions are present
# in the shell session.


_withenv_usage()
{
    echo "usage: withenv blah blah" >&2
}


withenv()
{
    # Construct an array of environment files.
    env_files=()
    while [ $# -gt 0 ]; do
        arg="$1"; shift
        if [ "$arg" = '--' ]; then
            break
        fi
        env_files+=($(_withenv_resolve "$arg"))
    done

    # If no command given, print usage and exit.
    if [ $# = 0 ]; then
        _withenv_usage
        return 1
    fi

    # Temporarily set the 'allexport' option if appropriate.
    if [ "$WITHENV_ALLEXPORT" = true ]; then
        local must_unset_allexport=$(echo $SHELLOPTS | grep allexport || echo true)
        set -o allexport
    fi

    # Source the specified files.
    for f in ${env_files[@]}; do
        if [[ "$f" == *.gpg ]] || [[ "$f" == *.asc ]]; then
            source <(gpg --decrypt --batch "$f" 2> /dev/null)
        else
            source "$f"
        fi
    done

    # Unset the 'allexport' option if we previously set it.
    if [ "$must_unset_allexport" = true ]; then
        set +o allexport
    fi

    # Run the command.
    "$@"
}


_withenv_resolve() {
    local name="$1"
    for f in "$name" "${WITHENV_DIR=$HOME/.withenv}/$name"; do
        if [ -f "$f" ]; then
            echo "$f"
            return
        fi
    done
    echo "withenv: No such file: $name" >&2
}


_withenv_complete()
{
    local end_options
    local cur=${COMP_WORDS[COMP_CWORD]}

    # If '--' has been specified, delegate completion to the given command.
    for (( i=1; i <= COMP_CWORD; i++ )); do
        if [ "$end_options" = "true" ]; then
            # Delegate completion to the given command.
            # _command_offset is defined in the bash_completion package.
            _command_offset $i 2> /dev/null
            return
        elif [[ ${COMP_WORDS[i]} == "--" ]]; then
            end_options="true"
        fi
    done

    # Complete '-' to '--'.
    if [[ ${cur} == -* ]] ; then
        COMPREPLY=( $(compgen -W "--" -- ${cur}) )
        return
    fi

    # Offer a list of environment files as the reply.
    setopt nullglob 2> /dev/null || shopt -s nullglob
    COMPREPLY=()
    COMPREPLY+=($(echo "$cur"*.{sh,bash,gpg,asc}))
    COMPREPLY+=($(cd ${WITHENV_DIR=$HOME/.withenv} && echo "$cur"*))
}

if [[ -n ${ZSH_VERSION-} ]]; then
    autoload bashcompinit
    bashcompinit
fi

complete -o default -F _withenv_complete withenv
