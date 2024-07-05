// Copyright © 2024 Andy Fingerhut
// License: https://www.apache.org/licenses/LICENSE-2.0

// trypcap exercises a few features of the pcap library from Go

package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	//"time"

	"github.com/google/gopacket/pcap"

	"github.com/jafingerhut/p4-guide/golang/pktcollector/pktwatcher"
)

// Things in pcap package:
// func FindAllDevs() (ifs []Interface, err error)

var iface = flag.String("iface", "", "Select interface where to capture")
var fname = flag.String("file", "", "pcap file to read packets from")
var debug = flag.Int("debug", 0, "debug level")

func printUsage(progName string) {
	fmt.Fprintf(os.Stderr, "usage: %s\n", progName)
	fmt.Fprintln(os.Stderr, "            [ --iface <interface_name> ]")
	fmt.Fprintln(os.Stderr, "            [ --file <pcap_filename> ]")
	fmt.Fprintln(os.Stderr)
}

func main() {
	flag.Parse()
	if (*iface == "" && *fname == "") || (*iface != "" && *fname != "") {
		fmt.Fprintf(os.Stderr, "You must specify exactly one of --iface and --file options\n")
		printUsage(os.Args[0])
		os.Exit(1)
	}
	var watcherOpts map[string]interface{}
	var successMsg string
	if *iface != "" {
		if *debug >= 2 {
			intfs, err := pcap.FindAllDevs()
			if err != nil {
				fmt.Fprintln(os.Stderr, err)
				return
			}
			fmt.Printf("Found %d interfaces:\n\n", len(intfs))
			for idx, intf := range intfs {
				fmt.Printf("%2d 0x%04x %s %s %d addresses: %v\n", idx, intf.Flags, intf.Name, intf.Description, len(intf.Addresses), intf.Addresses)
			}
		}
		watcherOpts = map[string]interface{}{
			"interface_name": *iface,
		}
		successMsg = fmt.Sprintf("Opened interface %s for live packet capture", *iface)
	}
	if *fname != "" {
		watcherOpts = map[string]interface{}{
			"file_name": *fname,
		}
		successMsg = fmt.Sprintf("Opened file %s\n", *fname)
	}
	watcherOpts["debug"] = *debug
	w, err := pktwatcher.Start(watcherOpts)
	if err != nil {
		log.Fatal(err)
		os.Exit(1)
	}
	fmt.Println(successMsg)

	if *debug >= 1 {
		fmt.Printf("w=%v\n", w)
	}
	// Open socket as server listening for incoming connection
	// requests.  Incoming connections can contain commands like
	// "readPkts", "readPktsAndClear", "stopPktCapture"
	listener, err := net.Listen("tcp", "localhost:8000")
	for {
		conn, err := listener.Accept()
		if err != nil {
			log.Print(err)
			continue
		}
		handleConn(conn)
	}
}

func handleConn(c net.Conn) {
	defer c.Close()
	if *debug >= 1 {
		fmt.Printf("handleConn started parsing input from new connection\n")
	}
	scanner := bufio.NewScanner(c)
	for scanner.Scan() {
		cmd := scanner.Text()
		if *debug >= 1 {
			fmt.Printf("handleConn read line from client: %s\n", cmd)
		}
		switch cmd {
		case "readPackets":
			// todo
		case "readAndClearPackets":
			// todo
		case "clearPackets":
			// todo
			io.WriteString(c, "OK\n")
		//case "stopCapture":
		//case "startCapture":
		default:
			io.WriteString(c, "ERR\n")
		}
	}
	if *debug >= 1 {
		fmt.Printf("handleConn scanner.Scan() returned false\n")
	}
	//	for {
	//		_, err := io.WriteString(c, time.Now().Format("15:04:05\n"))
	//		if err != nil {
	//			return // e.g., client disconnected
	//		}
	//		time.Sleep(1 * time.Second)
	//	}
}
