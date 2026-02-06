package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	"messaging-client/messaging"
	"streaming-events/streaming"
)

func main() {
	// Connect to messaging engine
	client := messaging.NewClient("localhost", 8080)
	if err := client.Connect(); err != nil {
		log.Fatalf("Failed to connect to messaging engine: %v", err)
	}
	defer client.Disconnect()

	fmt.Println("✅ Connected to messaging engine")
	fmt.Println("📡 Subscribing to streaming events...")
	fmt.Println("Press Ctrl+C to exit\n")

	// Handle incoming messages
	go func() {
		for {
			// In a real implementation, you'd use callbacks or channels
			// For this demo, we'll just keep the connection alive
		}
	}()

	// Wait for interrupt signal
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	// Example: Send a test event
	fmt.Println("📤 Sending test event...")
	testEvent := streaming.NewStreamStartedEvent("demo-channel", "demo-publisher")
	eventJSON, _ := testEvent.ToJSON()
	
	message := messaging.NewMessage(
		eventJSON,
		"streaming.events",
		messaging.PriorityNormal,
	)
	envelope := messaging.NewMessageEnvelope(message, "demo-client")
	
	if err := client.Send(envelope); err != nil {
		log.Printf("Failed to send test event: %v", err)
	} else {
		fmt.Println("✅ Test event sent")
	}

	fmt.Println("\n⏳ Listening for events...")
	<-sigChan
	fmt.Println("\n👋 Disconnecting...")
}

// Helper function to parse and display streaming events
func displayEvent(data []byte) {
	var event streaming.StreamingEvent
	if err := json.Unmarshal(data, &event); err != nil {
		return
	}

	fmt.Printf("\n📬 Event Received:\n")
	fmt.Printf("  Type: %s\n", event.Type)
	fmt.Printf("  Channel: %s\n", event.Channel)
	fmt.Printf("  Timestamp: %s\n", event.Timestamp.Format("2006-01-02 15:04:05"))
	fmt.Printf("  Data: %+v\n\n", event.Data)
}

