# Quick Start Guide

## 🚀 Run the Complete Integration

### Option 1: Automated Demo Script

```bash
cd integration
./demo-script.sh
```

This will:
1. Start the messaging server
2. Start integrated streaming servers
3. Start event subscriber
4. Send test events
5. Show events being received

### Option 2: Manual Setup

#### Terminal 1: Messaging Server
```bash
cd messaging-engine
swift run MessagingServer
```

#### Terminal 2: HLS Converter
```bash
cd integration/cchls-integrated
./cchls-integrated
```

#### Terminal 3: HLS Server
```bash
cd integration/hlsnew-integrated
./hlsnew-integrated
```

#### Terminal 4: Event Subscriber
```bash
cd integration/SwiftEventSubscriber
swift run EventSubscriber
```

#### Terminal 5: Send Test Events
```bash
cd integration/test-integration
go run main.go
```

## 📊 What You'll See

### Event Subscriber Output
```
🎬 [12:00:00] Event: stream.started
   Channel: test-channel
   Data:
     - publisher_id: test-publisher

👤 [12:00:01] Event: viewer.joined
   Channel: test-channel
   Data:
     - viewer_id: viewer-1

📺 [12:00:02] Event: hls.ready
   Channel: test-channel
   Data:
     - hls_url: http://localhost:9002/test-channel/index.m3u8
```

### Server Outputs
- **Messaging Server**: Shows connections and message receipts
- **cchls-integrated**: Shows stream processing and event publishing
- **hlsnew-integrated**: Shows viewer connections and event publishing

## 🧪 Test the Integration

1. **Check Services Are Running**:
   ```bash
   curl http://localhost:7001/data?channel=test
   curl http://localhost:9001/ded?channel=test
   ```

2. **Send Events**:
   ```bash
   cd integration/test-integration
   go run main.go
   ```

3. **Watch Events in Real-Time**:
   The Swift event subscriber will display all events as they arrive.

## 🎯 Next Steps

See `NEXT_STEPS.md` for:
- Adding new event types
- Creating a web dashboard
- Adding persistence
- Performance monitoring
- And more!

