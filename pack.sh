#!/bin/bash

set -e  # Exit on error

luarocks test
luarocks make --pack-binary-rock
mv *.all.rock rocks
