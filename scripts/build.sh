#!/bin/sh

set -e

rojo sourcemap default.project.json -o sourcemap.json

darklua process --config .darklua.json src/ dist/src

rojo build build.project.json -o planck.rbxm