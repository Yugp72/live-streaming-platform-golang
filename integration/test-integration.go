package main

import (
	"encoding/json"
	"fmt"
	"log"
	"time"

	"messaging-client"
	"streaming-events"
)

func main() {
	fmt.Println("🧪 Testing Messaging Integration")
	fmt.Println("=================================")
	fmt.Println()

	// Connect to messaging engine
	client := messaging.NewClient("localhost", 8080)
	if err := client.Connect(); err != nil {
		log.Fatalf("❌ Failed to connect to messaging engine: %v", err)
	}
	defer client.Disconnect()

	fmt.Println("✅ Connected to messaging engine")
	fmt.Println()

	// Test 1: Send stream started event
	fmt.Println("📤 Test 1: Sending stream.started event...")
	event1 := streaming.NewStreamStartedEvent("test-channel", "test-publisher")
	eventJSON1, _ := event1.ToJSON()
	message1 := messaging.NewMessage(eventJSON1, "streaming.events", messaging.PriorityNormal)
	envelope1 := messaging.NewMessageEnvelope(message1, "test-client")
	
	if err := client.Send(envelope1); err != nil {
		log.Printf("❌ Failed to send event: %v", err)
	} else {
		fmt.Println("✅ Event sent successfully")
	}
	time.Sleep(500 * time.Millisecond)

	// Test 2: Send viewer joined event
	fmt.Println("\n📤 Test 2: Sending viewer.joined event...")
	event2 := streaming.NewViewerJoinedEvent("test-channel", "viewer-1")
	eventJSON2, _ := event2.ToJSON()
	message2 := messaging.NewMessage(eventJSON2, "streaming.events", messaging.PriorityNormal)
	envelope2 := messaging.NewMessageEnvelope(message2, "test-client")
	
	if err := client.Send(envelope2); err != nil {
		log.Printf("❌ Failed to send event: %v", err)
	} else {
		fmt.Println("✅ Event sent successfully")
	}
	time.Sleep(500 * time.Millisecond)

	// Test 3: Send HLS ready event
	fmt.Println("\n📤 Test 3: Sending hls.ready event...")
	event3 := streaming.NewHLSReadyEvent("test-channel", "http://localhost:9002/test-channel/index.m3u8")
	eventJSON3, _ := event3.ToJSON()
	message3 := messaging.NewMessage(eventJSON3, "streaming.events", messaging.PriorityHigh)
	envelope3 := messaging.NewMessageEnvelope(message3, "test-client")
	
	if err := client.Send(envelope3); err != nil {
		log.Printf("❌ Failed to send event: %v", err)
	} else {
		fmt.Println("✅ Event sent successfully")
	}
	time.Sleep(500 * time.Millisecond)

	// Display event JSON for verification
	fmt.Println("\n📋 Event Examples:")
	fmt.Println("------------------")
	
	events := []streaming.StreamingEvent{event1, event2, event3}
	eventNames := []string{"stream.started", "viewer.joined", "hls.ready"}
	
	for i, event := range events {
		json, _ := json.MarshalIndent(event, "", "  ")
		fmt.Printf("\n%s:\n%s\n", eventNames[i], string(json))
	}

	fmt.Println("\n✅ Integration test complete!")
	fmt.Println("\n💡 Check the MessagingServer output to see if events were received")
}

