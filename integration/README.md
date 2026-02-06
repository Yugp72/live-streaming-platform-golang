# Live Streaming + Messaging Engine Integration

This integration connects the Go-based live streaming platform with the Swift messaging engine, enabling real-time event notifications for streaming activities.

## Architecture

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│  RTMP Server    │────────▶│  cchls-integrated │────────▶│  Messaging      │
│  (go-rtmp)      │         │  (HLS Converter)  │         │  Engine (Swift) │
└─────────────────┘         └──────────────────┘         └─────────────────┘
                                      │                            │
                                      │                            │
                                      ▼                            │
                            ┌──────────────────┐                   │
                            │ hlsnew-integrated│───────────────────┘
                            │  (HLS Server)    │
                            └──────────────────┘
```

## Components

### 1. Messaging Client (Go)
- **Location**: `messaging-client/`
- TCP/IP client that implements the messaging engine protocol
- Connects to Swift messaging server on port 8080
- Handles frame encoding/decoding, heartbeats, and acknowledgments

### 2. Streaming Events
- **Location**: `streaming-events/`
- Defines event types for streaming activities:
  - `stream.started` - When a stream begins
  - `stream.stopped` - When a stream ends
  - `stream.playing` - When HLS playback starts
  - `viewer.joined` - When a viewer connects
  - `viewer.left` - When a viewer disconnects
  - `hls.ready` - When HLS segments are ready
  - `hls.segment.ready` - When a new segment is available

### 3. Integrated Servers

#### cchls-integrated
- Enhanced version of the HLS converter
- Publishes events when:
  - Stream download starts
  - HLS segments become ready
  - Stream conversion completes or fails

#### hlsnew-integrated
- Enhanced version of the HLS server
- Publishes events when:
  - Viewers join/leave
  - HLS playback starts
  - Stream status changes

## Setup

### Prerequisites
1. Swift messaging engine running on port 8080
2. Go 1.21+
3. FFmpeg installed

### Building

```bash
# Build messaging client
cd messaging-client
go mod tidy

# Build streaming events
cd ../streaming-events
go mod tidy

# Build integrated cchls
cd ../cchls-integrated
go mod tidy
go build -o cchls-integrated

# Build integrated hlsnew
cd ../hlsnew-integrated
go mod tidy
go build -o hlsnew-integrated
```

## Running

### 1. Start Messaging Engine (Swift)

```bash
cd messaging-engine
swift run MessagingServer
```

### 2. Start Integrated Servers

**Terminal 1 - HLS Converter:**
```bash
cd integration/cchls-integrated
./cchls-integrated
```

**Terminal 2 - HLS Server:**
```bash
cd integration/hlsnew-integrated
./hlsnew-integrated
```

### 3. Start RTMP Server

You'll need to start your RTMP server (using go-rtmp-master) on port 1935.

## Event Flow

1. **Stream Starts**: RTMP publisher connects → cchls-integrated receives notification → Publishes `stream.started` event
2. **HLS Ready**: FFmpeg creates HLS segments → cchls-integrated publishes `hls.ready` event
3. **Viewer Joins**: Client requests HLS stream → hlsnew-integrated publishes `viewer.joined` event
4. **Viewer Leaves**: Client disconnects → hlsnew-integrated publishes `viewer.left` event
5. **Stream Stops**: FFmpeg completes → cchls-integrated publishes `stream.stopped` event

## Subscribing to Events

You can subscribe to streaming events using the Swift messaging client:

```swift
import MessagingEngine

let client = MessagingClient()
client.delegate = myDelegate
client.connect(host: "localhost", port: 8080)

// Subscribe to all streaming events
_ = client.subscribe(topic: "streaming.events") { envelope in
    // Handle streaming event
    let eventData = envelope.message.payload
    // Parse and process event
}
```

## Event Format

Events are published as JSON messages with the following structure:

```json
{
  "type": "stream.started",
  "channel": "channel1",
  "timestamp": "2024-01-01T12:00:00Z",
  "data": {
    "publisher_id": "publisher-123",
    "hls_url": "http://localhost:9002/channel1/index.m3u8"
  }
}
```

## Benefits

1. **Real-time Notifications**: Get instant updates about streaming activities
2. **Decoupled Architecture**: Streaming and messaging are separate systems
3. **Scalable**: Can handle multiple streams and viewers
4. **Event-Driven**: React to streaming events in real-time
5. **Priority Handling**: Critical events (like stream failures) can use high priority

## Troubleshooting

- **Messaging client fails to connect**: Ensure Swift messaging server is running on port 8080
- **Events not received**: Check that both integrated servers are running and connected
- **FFmpeg errors**: Ensure FFmpeg is installed and RTMP server is running

