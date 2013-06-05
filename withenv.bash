withenv()
{
  # Load arguments
  env_files=()
  while [ $# -gt 0 ]; do
    arg="$1"; shift
    if [ "$arg" = '--' ]; then
      break
    fi
    env_files+=($(_withenv_resolve "$arg"))
  done

  if [ $# = 0 ]; then

    # Print the specified files
    for f in ${env_files[@]}; do
      echo "# $f"
      cat "$f"
      echo
    done

  else

    # Source the specified files, then run a command
    (
      for f in ${env_files[@]}; do
        source "$f"
      done
      cmd=()
      for word in "${@}"; do
        cmd+=("'$word'")
      done
      eval "${cmd[@]}"
    )

  fi
}

_withenv_resolve() {
  name="$1"
  for f in "$name" "${WITHENV_DIR=$HOME/.withenv}/$name" "${WITHENV_DIR=$HOME/.withenv}/$name.bash" "${WITHENV_DIR=$HOME/.withenv}/$name.sh"; do
    if [ -f "$f" ]; then
      echo "$f"
      return
    fi
  done
  echo "withenv: No such file: $name" >&2
}

_withenv_complete()
{
  cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=( $(cd ${WITHENV_DIR-$HOME/.withenv}; ls "$cur"* 2> /dev/null | sed -e 's/\.sh$//' -e 's/\.bash$//') )
}

complete -o default -F _withenv_complete withenv
