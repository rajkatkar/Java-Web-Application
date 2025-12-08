#!/bin/bash

# Status script for Java Web Application

APP_NAME="webapp"
APP_DIR="/opt/webapp"
PID_FILE="${APP_DIR}/application.pid"

echo "Checking status of ${APP_NAME}..."

# Check if PID file exists
if [ ! -f "$PID_FILE" ]; then
    echo "Status: NOT RUNNING (PID file not found)"
    exit 1
fi

# Read PID
PID=$(cat "$PID_FILE")

# Check if process is running
if ps -p $PID > /dev/null 2>&1; then
    echo "Status: RUNNING"
    echo "PID: $PID"
    echo "Process Details:"
    ps -fp $PID
    exit 0
else
    echo "Status: NOT RUNNING (process not found)"
    exit 1
fi
