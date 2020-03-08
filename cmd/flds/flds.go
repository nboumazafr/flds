package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gorilla/mux"
)

const (
	status = "{status: OK}"
)

type logEvent struct {
	data string `json:"data"`
}

type allEvents []logEvent

var events = allEvents{
	{
		data: "not hooked up to stackDriver API yet",
	},
}

func health(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode(status)
}

func getLogEvents(w http.ResponseWriter, r *http.Request) {
	// TODO hookup to stackdriver
	json.NewEncoder(w).Encode(events)
}

func main() {

	port := os.Getenv("PORT")
	if port == "" {
		port = "7070"
	}
	router := mux.NewRouter().StrictSlash(true)

	router.HandleFunc("/health", health).Methods("GET")
	router.HandleFunc("/logs", getLogEvents).Methods("GET")
	log.Fatal(http.ListenAndServe("localhost:"+port, router))
}

func waitForShutdown(srv *http.Server) {
	interruptChan := make(chan os.Signal, 1)
	signal.Notify(interruptChan, os.Interrupt, syscall.SIGINT, syscall.SIGTERM)

	// Block until we receive our signal.
	<-interruptChan

	// Create a deadline to wait for.
	ctx, cancel := context.WithTimeout(context.Background(), time.Second*10)
	defer cancel()
	srv.Shutdown(ctx)
	log.Println("Shutting down")
	os.Exit(0)
}
