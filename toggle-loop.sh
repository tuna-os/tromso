#!/bin/bash
# Toggle monitor_loop.sh on or off

if pgrep -f "monitor_loop.sh" > /dev/null; then
    echo "Stopping loop..."
    pkill -f "monitor_loop.sh"
    echo "Loop stopped"
else
    echo "Starting loop..."
    cd /var/home/james/dev/kde-linux
    nohup ./monitor_loop.sh > /tmp/build_loop.log 2>&1 &
    echo "Loop started (PID $!)"
fi
