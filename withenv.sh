# This file should be sourced make these functions present in a shell session:
#   source withenv.sh


_withenv_usage()
{
    cat >&2 <<EOF
usage: withenv [envfile ...] -- command [argument ...]

Execute a command with a modified environment.

The modified environment is defined by one or more "envfiles"
which are simply shell scripts that withenv will source before
executing COMMAND. Envfiles may optionally be encrypted to protect
secret values on disk which need to be passed as environment variables.
Any envfile ending in .asc or .gpg will be decrypted via gpg.
It is assumed you have a gpgagent running with your private key loaded.

Envfiles should be placed in a directory defined by WITHENV_DIR.
If WITHENV_DIR is not set, \$HOME/.withenv is assumed. Explicit
paths to envfiles outside WITHENV_DIR are also recognized.

If WITHENV_ALLEXPORT is set to "true", the allexport shell option will
be set before sourcing envfiles. Unless this is set, it is necessary
in your envfiles to explicitly export any variables you wish to be
available in the environment when COMMAND is executed.


Example envfile (stored as \$HOME/.withenv/aws.sh):

export AWS_ACCESS_KEY_ID='ABCDEFGHIJKLMNOPQRST'
export AWS_SECRET_ACCESS_KEY='abcdefghijklmnopqrstuvwzyzabcdefghijklmn'


Example invocations:

# Basic usage
withenv aws.sh othercreds.gpg -- aws s3 list-buckets

# Print out the modified environment to the terminal
withenv aws.sh -- env

# Use env to override a previously set variable; env is really useful
withenv aws.sh -- env SOME_VAR=foo aws s3 list-buckets

# Launch a bash subshell where the modified environment persists
withenv aws.sh -- bash
EOF
}


withenv() {
# The enclosing parentheses spawn a subprocess so that environment
# modifications are local to this function invocation.
(
    # Construct an array of environment files.
    env_files=()
    while [ $# -gt 0 ]; do
        arg="$1"; shift
        if [ "$arg" = '-h' ] || [ "$arg" = '--help' ]; then
            _withenv_usage
            exit 1
        fi
        if [ "$arg" = '--' ]; then
            break
        fi
        env_files+=($(_withenv_resolve "$arg"))
    done

    # If no command was given, print usage and exit.
    if [ $# = 0 ]; then
        _withenv_usage
        exit 1
    fi

    # Set the 'allexport' option if appropriate.
    if [ "$WITHENV_ALLEXPORT" = true ]; then
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

    # Run the command.
    "$@"
) }


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

    # Check if '--' has already been specified.
    for (( i=1; i <= COMP_CWORD; i++ )); do
        if [[ ${COMP_WORDS[i]} == "--" ]]; then
            if [ $COMP_CWORD -eq $(( i + 1 )) ]; then
                # We're in the middle of matching the command name.
                COMPREPLY=($(compgen -A command -X "!${cur}*"))
                return
            elif [ $COMP_CWORD -gt $i ]; then
                # A command has been specified, so delegate further completion
                # to that command using _command_offset from the
                # bash_completion package. If bash_completion isn't loaded
                # in the current shell, then fail silently and let default
                # completion take over.
                _command_offset $(( i + 1 )) 2> /dev/null
                return
            fi
        fi
    done

    # Complete '-' to '--'.
    if [[ ${cur} == -* ]] ; then
        COMPREPLY=( $(compgen -W "--" -- ${cur}) )
        return
    fi

    # Offer a list of environment files as the reply.
    setopt nullglob 2> /dev/null || shopt -s nullglob
    COMPREPLY=()  # Initialize array.
    COMPREPLY+=("$cur"*.{sh,bash,zsh,gpg,asc})  # Add envfiles from PWD
    COMPREPLY+=("${WITHENV_DIR=$HOME/.withenv}/$cur"*)  # Add envfiles from WITHENV_DIR
    COMPREPLY=(${COMPREPLY[@]##*/})  # remove directory prefix from each element
    COMPREPLY=(${COMPREPLY[@]/withenv.sh})  # remove withenv.bash from array

}

if [[ -n ${ZSH_VERSION-} ]]; then
    # This is zsh rather than bash
    autoload bashcompinit
    bashcompinit
fi

complete -o default -F _withenv_complete withenv
