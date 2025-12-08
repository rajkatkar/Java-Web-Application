#!/bin/bash

# Start script for Java Web Application

APP_NAME="webapp"
APP_DIR="/opt/webapp"
JAR_FILE="${APP_DIR}/${APP_NAME}.jar"
PID_FILE="${APP_DIR}/application.pid"
LOG_FILE="${APP_DIR}/application.log"

echo "Starting ${APP_NAME}..."

# Check if application is already running
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p $PID > /dev/null 2>&1; then
        echo "Application is already running with PID: $PID"
        exit 1
    else
        echo "Removing stale PID file"
        rm -f "$PID_FILE"
    fi
fi

# Load environment variables
if [ -f "${APP_DIR}/.env" ]; then
    export $(cat "${APP_DIR}/.env" | xargs)
fi

# Start the application
cd "$APP_DIR"
nohup java -jar \
    -Dspring.profiles.active=${SPRING_PROFILES_ACTIVE:-prod} \
    -Dspring.datasource.url="${DATABASE_URL}" \
    -Dspring.datasource.username="${DATABASE_USERNAME}" \
    -Dspring.datasource.password="${DATABASE_PASSWORD}" \
    "$JAR_FILE" > "$LOG_FILE" 2>&1 &

# Save PID
echo $! > "$PID_FILE"

echo "Application started with PID: $(cat $PID_FILE)"
echo "Logs are available at: $LOG_FILE"

# Wait a few seconds and check if the application is running
sleep 5
if ps -p $(cat "$PID_FILE") > /dev/null 2>&1; then
    echo "Application started successfully!"
    exit 0
else
    echo "Failed to start application. Check logs at $LOG_FILE"
    exit 1
fi
