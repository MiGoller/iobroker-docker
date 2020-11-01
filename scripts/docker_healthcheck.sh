#!/bin/bash

set -e

if [ -f /opt/iobroker/.maintenance ]; then
    echo "Running maintenance mode!"
    exit 0
else
    /opt/iobroker/iobroker isrun
fi
