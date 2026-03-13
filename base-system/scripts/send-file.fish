#!/usr/bin/env fish

set filepath $argv[1]
set filename (basename $filepath)

set dst $argv[2]

set payload (mktemp)

echo $filename >$payload
cat $filepath >>$payload

socat $payload TCP:@master@
