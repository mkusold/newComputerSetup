#!/bin/bash
# Re-run a command until it exits successfully.
# Usage: auto_restart.sh <command> [args...]
# Example: auto_restart.sh yarn start
#

until "$@"; do
  echo "Restarting"
  sleep 2
done
