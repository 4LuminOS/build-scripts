package checks

import (
	"log"
	"math"

	"golang.org/x/sys/unix"
)

// StorageCheck PENDING CONCURRENCY IMPLEMENTATION
func StorageCheck() (passed bool) {
	var stat unix.Statfs_t
	err := unix.Statfs("/", &stat)

	if err != nil {
		log.Fatal(err)
	}
	// Available blocks * size per block = available space in Gigabytes
	availableSpace := stat.Bavail * uint64(stat.Bsize) * uint64(math.Pow(10, 9))

	switch {
	case availableSpace >= uint64(math.Pow(30, 9)):
		return true
	default:
		return false
	}

}
