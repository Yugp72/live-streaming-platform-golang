#!/bin/bash

# Script to start all integrated services
# Make sure the Swift messaging server is running first!

echo "🚀 Starting Integrated Live Streaming + Messaging Platform"
echo "============================================================"
echo ""
echo "⚠️  Make sure the Swift messaging server is running:"
echo "   cd ../messaging-engine && swift run MessagingServer"
echo ""
echo "Press Enter to continue or Ctrl+C to cancel..."
read

# Check if messaging server is running
if ! nc -z localhost 8080 2>/dev/null; then
    echo "❌ Messaging server is not running on port 8080!"
    echo "   Please start it first: cd ../messaging-engine && swift run MessagingServer"
    exit 1
fi

echo "✅ Messaging server is running"
echo ""

# Start cchls-integrated in background
echo "📹 Starting HLS Converter (cchls-integrated)..."
cd cchls-integrated
go run main.go &
CCHLS_PID=$!
cd ..
echo "   PID: $CCHLS_PID"
sleep 2

# Start hlsnew-integrated in background
echo "📺 Starting HLS Server (hlsnew-integrated)..."
cd hlsnew-integrated
go run main.go &
HLSNEW_PID=$!
cd ..
echo "   PID: $HLSNEW_PID"
sleep 2

echo ""
echo "✅ All services started!"
echo ""
echo "Services:"
echo "  - Messaging Engine: localhost:8080"
echo "  - HLS Converter API: localhost:7001"
echo "  - HLS Server API: localhost:9001"
echo "  - HLS Stream Server: localhost:9002"
echo ""
echo "To stop all services, run: ./stop-all.sh"
echo "Or manually kill PIDs: kill $CCHLS_PID $HLSNEW_PID"

# Save PIDs to file
echo "$CCHLS_PID $HLSNEW_PID" > .pids

