package streaming

import (
	"encoding/json"
	"time"
)

// EventType represents the type of streaming event
type EventType string

const (
	EventTypeStreamStarted   EventType = "stream.started"
	EventTypeStreamStopped   EventType = "stream.stopped"
	EventTypeStreamPublishing EventType = "stream.publishing"
	EventTypeStreamPlaying   EventType = "stream.playing"
	EventTypeViewerJoined    EventType = "viewer.joined"
	EventTypeViewerLeft      EventType = "viewer.left"
	EventTypeHLSReady        EventType = "hls.ready"
	EventTypeHLSSegmentReady EventType = "hls.segment.ready"
)

// StreamingEvent represents a streaming-related event
type StreamingEvent struct {
	Type      EventType              `json:"type"`
	Channel   string                 `json:"channel"`
	Timestamp time.Time              `json:"timestamp"`
	Data      map[string]interface{} `json:"data"`
}

// NewStreamingEvent creates a new streaming event
func NewStreamingEvent(eventType EventType, channel string, data map[string]interface{}) StreamingEvent {
	return StreamingEvent{
		Type:      eventType,
		Channel:   channel,
		Timestamp: time.Now(),
		Data:      data,
	}
}

// ToJSON converts the event to JSON bytes
func (e StreamingEvent) ToJSON() ([]byte, error) {
	return json.Marshal(e)
}

// Common event creators
func NewStreamStartedEvent(channel string, publisherID string) StreamingEvent {
	return NewStreamingEvent(EventTypeStreamStarted, channel, map[string]interface{}{
		"publisher_id": publisherID,
	})
}

func NewStreamStoppedEvent(channel string, reason string) StreamingEvent {
	return NewStreamingEvent(EventTypeStreamStopped, channel, map[string]interface{}{
		"reason": reason,
	})
}

func NewViewerJoinedEvent(channel string, viewerID string) StreamingEvent {
	return NewStreamingEvent(EventTypeViewerJoined, channel, map[string]interface{}{
		"viewer_id": viewerID,
	})
}

func NewViewerLeftEvent(channel string, viewerID string) StreamingEvent {
	return NewStreamingEvent(EventTypeViewerLeft, channel, map[string]interface{}{
		"viewer_id": viewerID,
	})
}

func NewHLSReadyEvent(channel string, hlsURL string) StreamingEvent {
	return NewStreamingEvent(EventTypeHLSReady, channel, map[string]interface{}{
		"hls_url": hlsURL,
	})
}

func NewHLSSegmentReadyEvent(channel string, segmentPath string) StreamingEvent {
	return NewStreamingEvent(EventTypeHLSSegmentReady, channel, map[string]interface{}{
		"segment_path": segmentPath,
	})
}

