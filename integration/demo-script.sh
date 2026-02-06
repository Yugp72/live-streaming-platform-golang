#!/bin/bash

echo "🎬 Live Streaming + Messaging Integration Demo"
echo "=============================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}This demo will:${NC}"
echo "  1. Start the Swift messaging server"
echo "  2. Start the integrated streaming servers (cchls & hlsnew)"
echo "  3. Start a Swift event subscriber to monitor events"
echo "  4. Send test streaming events"
echo ""
echo -e "${YELLOW}Press Enter to start the demo...${NC}"
read

# Step 1: Start Messaging Server
echo -e "\n${GREEN}Step 1: Starting Messaging Server...${NC}"
cd ../messaging-engine
swift run MessagingServer &
MESSAGING_PID=$!
cd ../integration
sleep 3
echo "✅ Messaging server started (PID: $MESSAGING_PID)"

# Step 2: Start Integrated Servers
echo -e "\n${GREEN}Step 2: Starting Integrated Streaming Servers...${NC}"
cd cchls-integrated
./cchls-integrated &
CCHLS_PID=$!
cd ../hlsnew-integrated
./hlsnew-integrated &
HLSNEW_PID=$!
cd ..
sleep 2
echo "✅ cchls-integrated started (PID: $CCHLS_PID)"
echo "✅ hlsnew-integrated started (PID: $HLSNEW_PID)"

# Step 3: Start Event Subscriber
echo -e "\n${GREEN}Step 3: Starting Event Subscriber...${NC}"
cd SwiftEventSubscriber
swift run EventSubscriber &
SUBSCRIBER_PID=$!
cd ..
sleep 2
echo "✅ Event subscriber started (PID: $SUBSCRIBER_PID)"

# Step 4: Send test events
echo -e "\n${GREEN}Step 4: Sending Test Events...${NC}"
sleep 2
cd test-integration
go run main.go
cd ..

echo -e "\n${BLUE}Demo is running!${NC}"
echo "Check the event subscriber output to see events being received."
echo ""
echo "To stop all services, run:"
echo "  kill $MESSAGING_PID $CCHLS_PID $HLSNEW_PID $SUBSCRIBER_PID"
echo ""
echo -e "${YELLOW}Press Enter to stop all services...${NC}"
read

# Cleanup
echo -e "\n${GREEN}Stopping all services...${NC}"
kill $MESSAGING_PID $CCHLS_PID $HLSNEW_PID $SUBSCRIBER_PID 2>/dev/null
echo "✅ All services stopped"

