package checks

import (
	"net"
)

func NetCheck() (passed bool, err error) {
	conn, err := net.Dial("tcp", "go.dev:http")
	if err != nil {
		return false, err
	}

	defer conn.Close()
	return true, nil
}
