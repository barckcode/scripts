package main

import (
	"encoding/json"
	"fmt"
	"os/exec"
)

type Information struct {
	Ip          string
	Country     string
	Region_name string
	City        string
}

func main() {
	cmd := exec.Command(
		"curl",
		"ifconfig.co/json",
	)

	stdout, err := cmd.Output()

	// Error Response
	if err != nil {
		fmt.Println(err.Error())
		return
	}

	// Response
	var response Information
	json.Unmarshal([]byte(stdout), &response)

	// Print the output
	fmt.Printf("IP: %s - Pais: %s - Region: %s - Ciudad %s", response.Ip, response.Country, response.Region_name, response.City)
}
