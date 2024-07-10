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

	"github.com/google/gopacket"
	"github.com/google/gopacket/pcap"

	"github.com/jafingerhut/p4-guide/golang/pktcollector/pktsource"
	"github.com/jafingerhut/p4-guide/golang/pktcollector/pktwatcher"
)

var iface = flag.String("iface", "", "Select interface where to capture")
var fname = flag.String("file", "", "pcap file to read packets from")
var firstPacketWaitTimeSeconds = flag.Float64("delay", 0.0, "when reading packets from pcap file, the duration in seconds to wait before processing the first packet")
var timeScale = flag.Float64("timescale", 0.0, "when reading packets from pcap file, the value to multiply the inter-packet times read from the pcap file, when processing consecutive packets")
var debug = flag.Int("debug", 0, "debug level")
var capacity = flag.Int("capacity", 0, "ring buffer capacity for capturing packets")

func main() {
	flag.Parse()
	if (*iface == "" && *fname == "") || (*iface != "" && *fname != "") {
		fmt.Fprintf(os.Stderr, "You must specify exactly one of -file and -iface options\n")
		flag.PrintDefaults()
		os.Exit(1)
	}
	var sourceOpts map[string]interface{}
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
		sourceOpts = map[string]interface{}{
			"interface_name": *iface,
		}
		successMsg = fmt.Sprintf("Opened interface %s for live packet capture", *iface)
	}
	if *fname != "" {
		sourceOpts = map[string]interface{}{
			"file_name":                  *fname,
			"firstPacketWaitTimeSeconds": *firstPacketWaitTimeSeconds,
			"timeScale":                  *timeScale,
		}
		successMsg = fmt.Sprintf("Opened file %s\n", *fname)
	}
	sourceOpts["debug"] = *debug
	packetChan, _, err := pktsource.Start(sourceOpts)
	if err != nil {
		log.Fatal(err)
		os.Exit(1)
	}
	fmt.Println(successMsg)

	watcherOpts := map[string]interface{}{}
	watcherOpts["debug"] = *debug
	if *capacity != 0 {
		watcherOpts["capacity"] = *capacity
	}
	watcherState, err := pktwatcher.Start(watcherOpts, packetChan)

	// Open socket as server listening for incoming connection
	// requests.  Incoming connections can issue commands the ones
	// handled in function handleConn.
	listener, err := net.Listen("tcp", "localhost:8000")
	for {
		conn, err := listener.Accept()
		if err != nil {
			log.Print(err)
			continue
		}
		exit := handleConn(conn, watcherState)
		if exit {
			break
		}
	}
}

func handleConn(c net.Conn, w *pktwatcher.State) (quit bool) {
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
		case "readAndClearPackets", "rac":
			pkts := w.ReadAndClearPackets()
			fmt.Fprintf(c, "\n%d packets\n", pkts.Len())
			for idx, pkt := range pkts.Elements() {
				p := pkt.(gopacket.Packet)
				fmt.Fprintf(c, "\n%3d %v\n", idx, p)
				fmt.Fprintf(c, "\n%s\n", p.Dump())
			}
		//case "stopCapture", "stopcap":
		//case "startCapture", "startcap:
		case "quit":
			// Client is disconnecting, but this server
			// process should remaing running, waiting for
			// connections from new clients.
			io.WriteString(c, "OK\n")
			return false
		case "exit":
			// Client is ordering server to exit.
			io.WriteString(c, "OK\n")
			return true
		default:
			io.WriteString(c, "ERR\n")
		}
	}
	if *debug >= 1 {
		fmt.Printf("handleConn scanner.Scan() returned false\n")
	}
	return false
}
