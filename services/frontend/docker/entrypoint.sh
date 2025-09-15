#!/bin/sh
set -e

echo "Starting frontend service..."

# Check if we're in development mode
if [ "$NODE_ENV" = "development" ]; then
    echo "Running in development mode"
    npm run dev -- --host 0.0.0.0 --port 3000
else
    echo "Running in production mode"
    # Start the application
    exec "$@"
fi
