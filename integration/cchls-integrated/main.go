package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"

	"messaging-client"
	"streaming-events"
)

var channel = ""
var messagingClient *messaging.Client

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

	envelope := messaging.NewMessageEnvelope(message, "cchls-server")

	if err := messagingClient.Send(envelope); err != nil {
		log.Printf("Failed to send event: %v", err)
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

func newFunc(s string) {
	go startDownload(s)
}

func handler(w http.ResponseWriter, r *http.Request) {
	res := &Response{
		w:      w,
		Data:   nil,
		Status: 200,
	}

	defer res.SendJson()

	if err := r.ParseForm(); err != nil {
		res.Status = 400
		res.Data = "url: /data?channel=<ROOM_NAME>"
		return
	}

	if r.URL.Query().Get("channel") == "$tart" {
		res.Data = "dfg"
		res.Status = 200
		response := fmt.Sprintf("Response for channel=%s", channel)
		fmt.Fprint(w, response)

		// Publish stream started event
		event := streaming.NewStreamStartedEvent(channel, "publisher-"+channel)
		publishEvent(event)

		newFunc(channel)
		return
	} else {
		channel = r.URL.Query().Get("channel")
	}

	if len(channel) == 0 {
		res.Status = 400
		res.Data = "url: /data?channel=<ROOM_NAME>"
		return
	}

	fmt.Println(channel)

	res.Data = "ok"
	fmt.Print("After res.data")

	response := fmt.Sprintf("Response for channel=%s", channel)

	fmt.Fprint(w, response)
}

func startDownload(s string) {
	fmt.Printf("download started for channel: %s\n", s)

	// Get current working directory or use a default
	homeDir, err := os.UserHomeDir()
	if err != nil {
		homeDir = "/tmp"
	}
	savePath := filepath.Join(homeDir, "Downloads", "segments", s)
	url := "rtmp://localhost:1935/appname/" + s

	err = os.MkdirAll(savePath, 0755)
	if err != nil {
		fmt.Printf("Error creating directory: %v\n", err)
		return
	}

	pathName := filepath.Join(savePath, "index.m3u8")

	// Publish HLS ready event
	event := streaming.NewHLSReadyEvent(s, fmt.Sprintf("http://localhost:9002/%s/index.m3u8", s))
	publishEvent(event)

	go callAPI(s)

	cmd := exec.Command("ffmpeg",
		"-i", url,
		"-c:v", "libx264",
		"-c:a", "aac",
		"-f", "hls",
		"-hls_time", "10",
		"-hls_list_size", "6",
		"-hls_flags", "delete_segments",
		"-vsync", "1",
		pathName)

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		log.Printf("FFmpeg error: %v", err)
		// Publish stream stopped event
		event := streaming.NewStreamStoppedEvent(s, fmt.Sprintf("ffmpeg error: %v", err))
		publishEvent(event)
		return
	}

	// Publish stream stopped event when done
	event = streaming.NewStreamStoppedEvent(s, "ffmpeg completed")
	publishEvent(event)
}

func callAPI(channelName string) {
	apiURL2 := "http://localhost:9001/ded?channel=" + channelName
	fmt.Println(apiURL2)
	res2, err := http.Get(apiURL2)
	if err != nil {
		fmt.Printf("Error calling API: %v\n", err)
		return
	}
	defer res2.Body.Close()
}

func main() {
	// Initialize messaging client
	initMessaging()
	defer func() {
		if messagingClient != nil {
			messagingClient.Disconnect()
		}
	}()

	http.HandleFunc("/", handler)

	err := http.ListenAndServe(":7001", nil)
	if err != nil {
		fmt.Printf("Error starting server: %v\n", err)
	}
	fmt.Println("Server Started on port 7001")
}

