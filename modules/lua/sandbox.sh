#!/bin/bash

ulimit -c 0 -t 3 -v 25000
lua modules/lua/sandbox.lua $1 > $2
