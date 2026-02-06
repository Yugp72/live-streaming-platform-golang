# Quick Start - Streaming Dashboard

## 🚀 Run the Dashboard

### Step 1: Start Messaging Server

```bash
cd ../../messaging-engine
swift run MessagingServer
```

### Step 2: Start the Dashboard

In a new terminal:

```bash
cd integration/StreamingDashboard
swift run StreamingDashboard
```

### Step 3: Connect

1. The dashboard will open automatically
2. Enter connection details (default: localhost:8080)
3. Click "Connect"
4. You should see "Connected" status in the toolbar

### Step 4: Send Test Events

In another terminal:

```bash
cd integration/test-integration
go run main.go
```

## 📊 What You'll See

### Sidebar (Left)
- **Channels**: List of all channels with status indicators
  - 🟢 Green = Active stream
  - ⚪ Gray = Inactive
- **Statistics**: 
  - Total Events
  - Active Streams
  - Total Viewers

### Main View (Right)
- **Event Feed**: Real-time scrolling list of events
  - Color-coded by event type
  - Shows channel, timestamp, and data
- **Control Panel**: 
  - Connection settings
  - Connect/Disconnect button
  - Clear events button

## 🎨 Event Colors

- 🟢 **Green**: stream.started, hls.ready
- 🔴 **Red**: stream.stopped
- 🔵 **Blue**: viewer.joined
- 🟠 **Orange**: viewer.left
- 🟣 **Purple**: stream.playing, hls.segment.ready

## ⌨️ Keyboard Shortcuts

- `Cmd+Q`: Quit application
- `Cmd+W`: Close window
- `Cmd+,`: Preferences (if implemented)

## 🐛 Troubleshooting

### Dashboard won't connect
- Check messaging server is running on port 8080
- Verify firewall settings
- Check connection settings in control panel

### No events showing
- Verify messaging server is receiving events
- Check that integrated servers are publishing events
- Try sending test events with `test-integration`

### Build errors
- Make sure messaging-engine is built: `cd messaging-engine && swift build`
- Clean build: `swift package clean && swift build`

## 📝 Features

✅ Real-time event monitoring
✅ Channel management
✅ Statistics tracking
✅ Beautiful SwiftUI interface
✅ Native macOS design
✅ Auto-scrolling event feed
✅ Connection status indicator

## 🎯 Next Steps

- Filter events by channel
- Search events
- Export events to file
- Add charts and graphs
- Customize event colors

Enjoy your streaming dashboard! 🎉

