#!/bin/sh

set -e

rojo sourcemap default.project.json -o sourcemap.json

rm -rf dist
darklua process --config .darklua.json src/ dist/src

cp README.md dist/README.md
cp LICENSE.md dist/LICENSE.md
cp pesde.toml dist/pesde.toml
cp pesde.lock dist/pesde.lock

cd ./dist

if [ "$1" = "--publish" ]; then
    pesde publish
fi