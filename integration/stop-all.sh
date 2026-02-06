#!/bin/bash

echo "🛑 Stopping all integrated services..."

if [ -f .pids ]; then
    PIDS=$(cat .pids)
    for PID in $PIDS; do
        if kill -0 $PID 2>/dev/null; then
            echo "   Stopping PID: $PID"
            kill $PID
        fi
    done
    rm .pids
    echo "✅ All services stopped"
else
    echo "⚠️  No PID file found. Services may have been stopped manually."
fi

