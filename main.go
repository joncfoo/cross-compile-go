package main

import (
	"database/sql"
	"log"

	_ "github.com/mattn/go-sqlite3"
)

func main() {
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		log.Fatalf("failed to open sqlite database: %s", err)
	}
	defer db.Close()

	version := ""
	row := db.QueryRow(`select sqlite_version()`)
	if err := row.Scan(&version); err != nil {
		log.Panicf("failed to query: %s", err)
	}

	log.Printf("sqlite version: %s", version)
}
