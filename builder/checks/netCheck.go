package checks

import (
	"net"
)

// NetCheck Attempts to make a http request with a 10 second timeout limit, if it fails return a DNS error (default behaviour)
// might change it to return something else if needed, but this should suffice
//
// PENDING CONCURRENCY IMPLEMENTATION
func NetCheck() (passed bool) {
	conn, err := net.DialTimeout("tcp", "go.dev:http", 10)
	if err != nil {
		return false
	}

	defer conn.Close()
	return true
}
