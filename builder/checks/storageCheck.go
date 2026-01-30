package checks

import (
	"fmt"
	"log"
	"math"

	"golang.org/x/sys/unix"
)

const neededSpace = 30 // 30 Gigabytes

// StorageCheck PENDING CONCURRENCY IMPLEMENTATION
func StorageCheck() (passed bool, err error) {
	var stat unix.Statfs_t
	err = unix.Statfs("/", &stat)

	if err != nil {
		log.Fatal(err)
	}
	// Available blocks * size per block = available space in Gigabytes
	availableSpace := stat.Bavail * uint64(stat.Bsize) * uint64(math.Pow(10, 9))

	switch {
	case availableSpace >= neededSpace:
		return true, nil
	default:
		return false, fmt.Errorf("not enough storage space (needed: %v GB) (have: %v GB)", neededSpace, availableSpace)
	}
}
