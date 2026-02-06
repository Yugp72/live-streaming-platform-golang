import SwiftUI

struct ContentView: View {
    @EnvironmentObject var eventManager: StreamingEventManager
    
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            MainDashboardView()
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                ConnectionStatusView()
            }
        }
    }
}

struct SidebarView: View {
    @EnvironmentObject var eventManager: StreamingEventManager
    
    var body: some View {
        List {
            Section("Channels") {
                ForEach(eventManager.channels.keys.sorted(), id: \.self) { channel in
                    ChannelRow(channel: channel)
                }
            }
            
            Section("Statistics") {
                StatRow(label: "Total Events", value: "\(eventManager.totalEvents)")
                StatRow(label: "Active Streams", value: "\(eventManager.activeStreams)")
                StatRow(label: "Total Viewers", value: "\(eventManager.totalViewers)")
            }
        }
        .navigationTitle("Streaming Dashboard")
        .listStyle(.sidebar)
    }
}

struct ChannelRow: View {
    let channel: String
    @EnvironmentObject var eventManager: StreamingEventManager
    
    var channelData: StreamingEventManager.ChannelData? {
        eventManager.channels[channel]
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(channelData?.isActive == true ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(channel)
                    .font(.headline)
                Text("\(channelData?.viewerCount ?? 0) viewers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

struct MainDashboardView: View {
    @EnvironmentObject var eventManager: StreamingEventManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Event Feed
            EventFeedView()
            
            // Control Panel
            ControlPanelView()
                .frame(height: 200)
                .background(Color(NSColor.controlBackgroundColor))
        }
    }
}

struct EventFeedView: View {
    @EnvironmentObject var eventManager: StreamingEventManager
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(eventManager.recentEvents) { event in
                    EventCard(event: event)
                }
            }
            .padding()
        }
        .background(Color(NSColor.textBackgroundColor))
    }
}

struct EventCard: View {
    let event: StreamingEventManager.StreamingEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Event Icon
            Image(systemName: iconForEventType(event.type))
                .font(.title2)
                .foregroundColor(colorForEventType(event.type))
                .frame(width: 40)
            
            // Event Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.type.rawValue)
                        .font(.headline)
                    Spacer()
                    Text(event.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Channel: \(event.channel)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !event.data.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(event.data.keys.sorted()), id: \.self) { key in
                            HStack {
                                Text("\(key):")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(event.data[key] ?? "")")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    func iconForEventType(_ type: StreamingEventManager.EventType) -> String {
        switch type {
        case .streamStarted: return "play.circle.fill"
        case .streamStopped: return "stop.circle.fill"
        case .streamPlaying: return "play.fill"
        case .viewerJoined: return "person.badge.plus"
        case .viewerLeft: return "person.badge.minus"
        case .hlsReady: return "tv.fill"
        case .hlsSegmentReady: return "square.stack.3d.up.fill"
        }
    }
    
    func colorForEventType(_ type: StreamingEventManager.EventType) -> Color {
        switch type {
        case .streamStarted, .hlsReady: return .green
        case .streamStopped: return .red
        case .viewerJoined: return .blue
        case .viewerLeft: return .orange
        case .streamPlaying, .hlsSegmentReady: return .purple
        }
    }
}

struct ControlPanelView: View {
    @EnvironmentObject var eventManager: StreamingEventManager
    @State private var serverHost = "localhost"
    @State private var serverPort = "8080"
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Connection Settings")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Host")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("localhost", text: $serverHost)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading) {
                    Text("Port")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("8080", text: $serverPort)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
                
                Spacer()
                
                Button(action: {
                    if eventManager.isConnected {
                        eventManager.disconnect()
                    } else {
                        if let port = Int(serverPort) {
                            eventManager.connect(host: serverHost, port: port)
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: eventManager.isConnected ? "xmark.circle.fill" : "play.circle.fill")
                        Text(eventManager.isConnected ? "Disconnect" : "Connect")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(serverHost.isEmpty || serverPort.isEmpty)
            }
            
            Divider()
            
            HStack {
                Button("Clear Events") {
                    eventManager.clearEvents()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Text("Events: \(eventManager.recentEvents.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct ConnectionStatusView: View {
    @EnvironmentObject var eventManager: StreamingEventManager
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(eventManager.isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(eventManager.isConnected ? "Connected" : "Disconnected")
                .font(.caption)
        }
    }
}

