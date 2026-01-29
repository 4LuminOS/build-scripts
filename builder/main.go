package main

import (
	"fmt"
	"luminBuilder/checks"
)

func main() {
	privCheck := checks.PrivelageCheck()
	osPassed := checks.OsCheck()
	netPassed := checks.NetCheck()
	storagePassed := checks.StorageCheck()

	fmt.Printf("PrivelageCheck Passed: %v\n", privCheck)
	fmt.Printf("Storage Check passed: %v\n", storagePassed)
	fmt.Printf("OsCheck Passed: %v\n", osPassed)
	fmt.Printf("NetCheck Passed: %v \n", netPassed)

}
