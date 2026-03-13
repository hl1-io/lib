#!/usr/bin/env fish


pg_dumpall --port 5555 -U postgres > timescale.sql
