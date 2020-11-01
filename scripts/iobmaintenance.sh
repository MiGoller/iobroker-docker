#!/bin/bash

set -e

do_start () {
    # Set maintenance flag
    touch /opt/iobroker/.maintenance

    # Shutdown ioBroker ...
    pid=$(ps -ef | awk '/[j]s.controller/{print $2}')

    if [ "$pid" != "" ]; then
        echo "Shutting down ioBroker service (PID $pid) ... "
        kill -SIGTERM "$pid"
        # /opt/iobroker/iobroker stop

        echo "Waiting for ioBroker controller to shut down ... "
        until [ "$(ps -ef | awk '/[j]s.controller/{print $2}')" == "" ]
        do
            sleep 1
        done

        rm -f /opt/iobroker/node_modules/iobroker.js-controller/iobroker.pid
    fi

    echo "ioBroker maintenance mode started."

    exit 0
}

do_stop () {
    # Set maintenance flag
    rm -f /opt/iobroker/.maintenance

    echo "ioBroker maintenance mode stopped. ioBroker service will start now."

    exit 0
}

case "$1" in
    start|"")
        do_start
        ;;
    stop)
        do_stop
        ;;
    *)
        echo "Usage: iobmaintenance.sh [start|stop]" >&2
        exit 3
        ;;
esac
