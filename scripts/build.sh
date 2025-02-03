#!/bin/sh

set -e

# If Packages aren't installed, install them.
if [ ! -d "DevPackages" ]; then
    sh scripts/install-packages.sh
fi

rojo sourcemap default.project.json -o sourcemap.json

darklua process --config .darklua.json src/ dist/src
rm -rf dist/src/__tests__
rm -f dist/src/jest.config.luau

rojo build build.project.json -o Planck.rbxm