# withenv

Execute a command in a modified environment.
It's kind of like [envcrypt](https://github.com/whilp/envcrypt)
or a more user-friendly
[chpst (8)](http://manpages.ubuntu.com/manpages/hardy/man8/chpst.8.html)
with support for keeping your environment variables in GPG-encrypted files.

For example:

    $ withenv aws.sh -- aws s3 list-buckets

Here, `aws.sh` is an "envfile" defining some environment variables,
and `aws s3 list-buckets` is the command to run.

## Installing it

`withenv` is implemented using shell functions and supports both bash and zsh.

Install it by copying `withenv.sh` from GitHub:

    mkdir -p ~/.withenv
    curl https://raw.githubusercontent.com/jklukas/withenv/master/withenv.sh > ~/.withenv/withenv.sh

To make it available, add the following to your `.bash_profile` or `.zshrc`:

    source $HOME/.withenv/withenv.sh

## Usage

Full usage details and examples are given by `withenv --help`:

```bash
usage: withenv [envfile ...] -- command [argument ...]

Execute a command with a modified environment.

The modified environment is defined by one or more "envfiles"
which are simply shell scripts that withenv will source before
executing COMMAND. Envfiles may optionally be encrypted to protect
secret values on disk which need to be passed as environment variables.
Any envfile ending in .asc or .gpg will be decrypted via gpg.
It is assumed you have a gpgagent running with your private key loaded.

Envfiles should be placed in a directory defined by WITHENV_DIR.
If WITHENV_DIR is not set, $HOME/.withenv is assumed. Explicit
paths to envfiles outside WITHENV_DIR are also recognized.

Unless the WITHENV_ALLEXPORT exists and is set to "false", the 'allexport'
shell option will be set before sourcing envfiles. If this is turned off,
your envfiles must explicitly export any variables you wish to be
available in the environment when COMMAND is executed.


Example envfile (stored as $HOME/.withenv/aws.sh):

AWS_ACCESS_KEY_ID='ABCDEFGHIJKLMNOPQRST'
AWS_SECRET_ACCESS_KEY='abcdefghijklmnopqrstuvwzyzabcdefghijklmn'
REDSHIFT_COPY_CREDS="aws_access_key_id=$AWS_ACCESS_KEY_ID;aws_secret_access_key=$AWS_SECRET_ACCESS_KEY"


Example invocations:

# Basic usage
withenv aws.sh othercreds.gpg -- aws s3 list-buckets

# Print out the modified environment to the terminal
withenv aws.sh -- env

# Use env to override a previously set variable; env is really useful
withenv aws.sh -- env SOME_VAR=foo aws s3 list-buckets

# Launch a bash subshell where the modified environment persists
withenv aws.sh -- bash
```

## Bash completion

`withenv` comes complete with bash programmable completion support, for no extra cost.
Partial completion support is also available in zsh.

For example:

    $ withenv aw[TAB]
    $ withenv aws.sh
    $ withenv aws.sh -[TAB]
    $ withenv aws.sh --
    $ withenv aws.sh -- aw[TAB]
    $ withenv aws.sh -- aws


For best results with Bash, make sure you have the `bash_completion` package installed.
A blog post from David Alger provides some nice
[instructions for installing bash_completion on OS X via Homebrew](http://davidalger.com/development/bash-completion-on-os-x-with-brew/).


## Decryption (GPG Support)

If you want to use encrypted envfiles as a way to protect your secrets while
they're resting on disk, you'll need to have `gpg` installed.
If you're on OS X, download [GPG Tools](https://gpgtools.org/), which includes
a very user-friendly implementation of `gpg-agent`.

If you've already created a key pair, GPG Tools should pull up a PIN entry
screen the first time you pass an encrypted envfile to `withenv`.
The agent will then cache your credentials for some period of time
so that you don't have to enter your secret key's password every time
you invoke `withenv`.


## FAQ

*How is this different from [envcrypt](https://github.com/whilp/envcrypt)?*

It's similar in many ways, but the implementation is shell script rather
than Go and the interface is different, aiming to resolve some
usability issues I had with envcrypt.

First, I wanted more flexibility for envfiles.
`envcrypt` defines its own restricted file format for environments
whereas `withenv` expects shell scripts and `source`s them in the shell.
If you're comfortable with shell scripting, that means you already
understand how quoting will behave in envfiles. It also means that you can define
some variables in terms of other variables already defined or use some logic.
You can even have dependent envfiles that build a new variable based on
values defined in previous envfiles.

Second, I wanted command completion. I found that with `envcrypt`,
I would often construct a command using shell completion features, then
return to the beginning of the line to add the `envcrypt envfile` part.
Or I would resort to command history rather than retyping a command.
[mdub/withenv](https://github.com/mdub/withenv), on which this project
is based, provided some completion pieces
and the concept of a known directory for envfiles.

*How can I migrate from envcrypt?*

You should be able to use most of your existing envcrypt environment files
unmodified in `withenv`. Just copy the files into `$HOME/.withenv` or
set `WITHENV_DIR` in your `.bash_profile` or `.zshrc` to point to your
existing directory.
You may need to put quotes around some values if they contain characters
that have special meaning to the shell.
