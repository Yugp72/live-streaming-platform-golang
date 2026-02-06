# Streaming Dashboard - SwiftUI macOS App

A beautiful, modern macOS dashboard for monitoring live streaming events in real-time.

## Features

✨ **Real-Time Event Monitoring**
- Live event feed with color-coded event types
- Automatic event categorization
- Timestamp tracking

📊 **Channel Management**
- View all active channels
- Real-time viewer counts per channel
- Channel status indicators

📈 **Statistics Dashboard**
- Total events received
- Active streams count
- Total viewers across all channels

🎨 **Modern UI**
- SwiftUI-based interface
- Native macOS design
- Responsive layout
- Beautiful color coding

## Screenshots

The dashboard includes:
- **Sidebar**: Channel list and statistics
- **Main View**: Real-time event feed
- **Control Panel**: Connection settings and controls

## Running the Dashboard

### Prerequisites
1. Swift messaging server must be running
2. Integrated streaming servers (optional, for real events)

### Start the Dashboard

```bash
cd integration/StreamingDashboard
swift run StreamingDashboard
```

### Connect to Messaging Server

1. Enter server host (default: localhost)
2. Enter server port (default: 8080)
3. Click "Connect"

The dashboard will automatically subscribe to `streaming.events` topic and display all events in real-time.

## Event Types

The dashboard recognizes and displays:

- 🎬 **stream.started** - When a stream begins (Green)
- 🛑 **stream.stopped** - When a stream ends (Red)
- ▶️ **stream.playing** - When HLS playback starts (Purple)
- 👤 **viewer.joined** - When a viewer connects (Blue)
- 👋 **viewer.left** - When a viewer disconnects (Orange)
- 📺 **hls.ready** - When HLS segments are ready (Green)
- 📦 **hls.segment.ready** - When a new segment is available (Purple)

## Architecture

```
Messaging Engine → MessagingClient → StreamingEventManager → SwiftUI Views
```

The dashboard uses:
- **MessagingEngine** - For connecting to the messaging server
- **StreamingEventManager** - ObservableObject that manages events and state
- **SwiftUI Views** - Modern, declarative UI components

## Testing

To test the dashboard:

1. Start messaging server:
   ```bash
   cd messaging-engine
   swift run MessagingServer
   ```

2. Start dashboard:
   ```bash
   cd integration/StreamingDashboard
   swift run StreamingDashboard
   ```

3. Send test events:
   ```bash
   cd integration/test-integration
   go run main.go
   ```

4. Watch events appear in the dashboard in real-time!

## UI Components

### ContentView
Main container with navigation split view

### SidebarView
- Channel list with status indicators
- Statistics panel

### MainDashboardView
- Event feed (scrollable)
- Control panel

### EventCard
Individual event display with:
- Event type icon
- Channel information
- Timestamp
- Event data

### ControlPanelView
- Connection settings
- Connect/Disconnect button
- Clear events button

## Customization

You can customize:
- Event colors in `EventCard.colorForEventType()`
- Event icons in `EventCard.iconForEventType()`
- Maximum events stored in `StreamingEventManager.maxEvents`
- UI layout in `ContentView.swift`

## Requirements

- macOS 13.0+
- Swift 5.9+
- MessagingEngine package

## Next Steps

- Add filtering by channel
- Add event search
- Export events to file
- Add charts and graphs
- Dark mode support (automatic with macOS)

