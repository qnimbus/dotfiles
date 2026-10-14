#!/usr/bin/env bash

alias cz=chezmoi
function cze() { chezmoi edit "$@"; }
function cza() { chezmoi apply "$@"; }

alias opin='eval "$(op signin)"'
alias opout='op signout; unset $(compgen -v OP_SESSION_)'
