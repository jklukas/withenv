# withenv

"withenv" runs a shell command in the context of a named environment. 

For example:

    $ withenv my-aws-credentials -- aws s3 list-buckets

Here, "`my-aws-credentials`" is the name of the environment, and "`aws s3 list-buckets`" is the command to run.

## Installing it

"withenv" is implemented using bash shell functions.  Install it with:

    source path/to/withenv/withenv.bash

## Defining environments

In this context, an "environment" means a set of environment variables.  You define environments by creating shell-script fragments which set environment variables, e.g.

    # /Users/mdub/.withenv/my-aws-credentials
    export AWS_ACCESS_KEY_ID=AKIBIJQ4XSWNFIF426NQ
    export AWS_SECRET_ACCESS_KEY=abNFIEVdwcQdeadbeefnnShq4B1pG7qZ9sqNwoFO

They're just shell scripts; `withenv` will "`source`" them as required.

## Using it

You can specify a full path to the environment file:

    $ withenv /etc/aws-credentials.sh -- aws ec2 list-instances

Or, you can just supply a short-name (as in the first example), in which case we'll look for the file in `$WITHENV_DIR` (which defaults to `$HOME/.withenv`).

If multiple environments are specifed, `withenv` will load them all:

    $ withenv my-aws-credentials ruby-gc -- funky-aws-stuff.rb

## Bash completion

`withenv` comes complete with Bash programmable completion support, for no extra cost.  For example:

    $ withenv my-aw[TAB]
    $ withenv my-aws-credentials
