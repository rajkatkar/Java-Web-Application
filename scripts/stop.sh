#!/bin/bash

# Stop script for Java Web Application

APP_NAME="webapp"
APP_DIR="/opt/webapp"
PID_FILE="${APP_DIR}/application.pid"

echo "Stopping ${APP_NAME}..."

# Check if PID file exists
if [ ! -f "$PID_FILE" ]; then
    echo "PID file not found. Application may not be running."
    exit 0
fi

# Read PID
PID=$(cat "$PID_FILE")

# Check if process is running
if ! ps -p $PID > /dev/null 2>&1; then
    echo "Application is not running (PID: $PID not found)"
    rm -f "$PID_FILE"
    exit 0
fi

# Try graceful shutdown
echo "Sending SIGTERM to PID: $PID"
kill $PID

# Wait for process to stop
TIMEOUT=30
COUNT=0
while ps -p $PID > /dev/null 2>&1; do
    sleep 1
    COUNT=$((COUNT+1))
    if [ $COUNT -ge $TIMEOUT ]; then
        echo "Graceful shutdown timeout. Forcing shutdown..."
        kill -9 $PID
        sleep 2
        break
    fi
done

# Verify process is stopped
if ps -p $PID > /dev/null 2>&1; then
    echo "Failed to stop application"
    exit 1
else
    echo "Application stopped successfully"
    rm -f "$PID_FILE"
    exit 0
fi
