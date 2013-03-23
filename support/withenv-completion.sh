_withenv_complete()
{
  cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=( $(cd ${WITHENV_DIR-$HOME/.withenv}; ls "$cur"* 2> /dev/null) )
}

complete -o default -F _withenv_complete withenv
