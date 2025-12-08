#!/bin/bash

# Restart script for Java Web Application

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Restarting application..."

# Stop the application
"${SCRIPT_DIR}/stop.sh"

# Wait a moment
sleep 2

# Start the application
"${SCRIPT_DIR}/start.sh"
