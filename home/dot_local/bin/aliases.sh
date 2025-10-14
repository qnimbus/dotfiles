#!/usr/bin/env bash

alias cz=chezmoi
function cze() { chezmoi edit "$@"; }
function cza() { chezmoi apply "$@"; }
