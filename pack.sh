#!/bin/bash

luarocks make --pack-binary-rock
mv *.all.rock rocks
