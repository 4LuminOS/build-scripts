package main

import (
	"fmt"
	"log"
	"luminBuilder/checks"
)

//"sync"

func main(){
	/*
	wg := sync.WaitGroup{}
	osCh := make(chan string)
	wg.Add(1)
	*/
	osPassed, err := checks.OsCheck()
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("OsCheck Passed?: %v \n", osPassed)
}
