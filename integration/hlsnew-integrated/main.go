package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"sync"
	"time"

	"messaging-client"
	"streaming-events"
)

var (
	messagingClient *messaging.Client
	viewerCounts    = make(map[string]int)
	viewerLock      sync.RWMutex
)

func initMessaging() {
	client := messaging.NewClient("localhost", 8080)
	if err := client.Connect(); err != nil {
		log.Printf("Warning: Failed to connect to messaging engine: %v", err)
		log.Printf("Continuing without messaging integration...")
		return
	}
	messagingClient = client
	log.Println("✅ Connected to messaging engine")
}

func publishEvent(event streaming.StreamingEvent) {
	if messagingClient == nil {
		return
	}

	eventJSON, err := event.ToJSON()
	if err != nil {
		log.Printf("Failed to serialize event: %v", err)
		return
	}

	message := messaging.NewMessage(
		eventJSON,
		"streaming.events",
		messaging.PriorityNormal,
	)

	envelope := messaging.NewMessageEnvelope(message, "hlsnew-server")

	if err := messagingClient.Send(envelope); err != nil {
		log.Printf("Failed to send event: %v", err)
	}
}

func incrementViewer(channel string) {
	viewerLock.Lock()
	defer viewerLock.Unlock()
	viewerCounts[channel]++
	count := viewerCounts[channel]

	// Publish viewer joined event
	event := streaming.NewViewerJoinedEvent(channel, fmt.Sprintf("viewer-%d", count))
	publishEvent(event)
}

func decrementViewer(channel string) {
	viewerLock.Lock()
	defer viewerLock.Unlock()
	if viewerCounts[channel] > 0 {
		viewerCounts[channel]--
		count := viewerCounts[channel]

		// Publish viewer left event
		event := streaming.NewViewerLeftEvent(channel, fmt.Sprintf("viewer-%d", count))
		publishEvent(event)
	}
}

type Response struct {
	w      http.ResponseWriter
	Status int         `json:"status"`
	Data   interface{} `json:"data"`
}

func (r *Response) SendJson() (int, error) {
	resp, _ := json.Marshal(r)
	r.w.Header().Set("Content-Type", "application/json")
	r.w.WriteHeader(r.Status)
	return r.w.Write(resp)
}

func dedHandler(w http.ResponseWriter, r *http.Request) {
	res := &Response{
		w:      w,
		Data:   nil,
		Status: 200,
	}

	defer res.SendJson()

	if err := r.ParseForm(); err != nil {
		res.Status = 400
		res.Data = "url: /ded?channel=<ROOM_NAME>"
		return
	}

	channel := r.URL.Query().Get("channel")
	fmt.Printf("HLS stream requested for channel: %s\n", channel)

	if len(channel) == 0 {
		res.Status = 400
		res.Data = "url: /ded?channel=<ROOM_NAME>"
		return
	}

	response := fmt.Sprintf("Response for channel=%s", channel)
	fmt.Fprint(w, response)

	// Increment viewer count
	incrementViewer(channel)

	go startStream(channel)
}

func startStream(s string) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		homeDir = "/tmp"
	}
	segDir := filepath.Join(homeDir, "Downloads", "segments", s)
	const port = 9002
	fmt.Printf("Serving HLS from: %s\n", segDir)

	// Publish stream playing event
	event := streaming.NewStreamingEvent(
		streaming.EventTypeStreamPlaying,
		s,
		map[string]interface{}{
			"hls_url": fmt.Sprintf("http://localhost:%d/index.m3u8", port),
		},
	)
	publishEvent(event)

	// Create file server with CORS headers
	fileServer := http.FileServer(http.Dir(segDir))
	handler := addHeaders(fileServer)

	http.Handle("/", handler)
	fmt.Printf("Starting HLS server on port %d\n", port)
	log.Printf("Serving %s on HTTP port: %d\n", segDir, port)

	// Track when viewers disconnect (simplified - in production, track actual connections)
	go func() {
		ticker := time.NewTicker(30 * time.Second)
		defer ticker.Stop()
		for range ticker.C {
			// In a real implementation, you'd track actual HTTP connections
			// For now, we'll just maintain the count
		}
	}()

	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%d", port), nil))
}

func main() {
	// Initialize messaging client
	initMessaging()
	defer func() {
		if messagingClient != nil {
			messagingClient.Disconnect()
		}
	}()

	http.HandleFunc("/ded", dedHandler)

	err := http.ListenAndServe(":9001", nil)
	if err != nil {
		fmt.Printf("Error starting server: %v\n", err)
	}
	fmt.Println("HLS Server Started on port 9001")
}

func addHeaders(h http.Handler) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		h.ServeHTTP(w, r)
	}
}

