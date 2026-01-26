package main

import (
	"fmt"
	"luminBuilder/checks"
)

func main() {
	/*
		wg := sync.WaitGroup{}
		osCh := make(chan string)
		wg.Add(1)
	*/
	osPassed := checks.OsCheck()
	netPassed, err := checks.NetCheck()
	storagePassed := checks.StorageCheck()

	fmt.Printf("Storage Check passed: %v\n", storagePassed)
	fmt.Printf("OsCheck Passed: %v due to error: %v \n", osPassed, err)
	fmt.Printf("NetCheck Passed: %v \n", netPassed)
}
