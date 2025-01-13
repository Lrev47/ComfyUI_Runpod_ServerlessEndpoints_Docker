#!/usr/bin/env bash
fuser -k 3021/tcp || echo "No process found on port 3021."
