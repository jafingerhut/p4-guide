// Copyright © 2024 Andy Fingerhut
// License: https://www.apache.org/licenses/LICENSE-2.0

// trypcap exercises a few features of the pcap library from Go

package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	//"time"

	"github.com/google/gopacket"
	//"github.com/google/gopacket/layers"
	"github.com/google/gopacket/pcap"
)

// Things in pcap package:
// func FindAllDevs() (ifs []Interface, err error)

var iface = flag.String("iface", "", "Select interface where to capture")
var fname = flag.String("file", "", "pcap file to read packets from")

func printUsage(progName string) {
	fmt.Fprintf(os.Stderr, "usage: %s\n", progName)
	fmt.Fprintln(os.Stderr, "            [ --iface <interface_name> ]")
	fmt.Fprintln(os.Stderr, "            [ --file <pcap_filename> ]")
	fmt.Fprintln(os.Stderr)
}

func main() {
	flag.Parse()

	if *iface == "" && *fname == "" {
		printUsage(os.Args[0])
		os.Exit(1)
	}

	var handle *pcap.Handle
	if *iface != "" {
		intfs, err := pcap.FindAllDevs()
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return
		}
		fmt.Printf("Found %d interfaces:\n\n", len(intfs))
		for idx, intf := range intfs {
			fmt.Printf("%2d 0x%04x %s %s %d addresses: %v\n", idx, intf.Flags, intf.Name, intf.Description, len(intf.Addresses), intf.Addresses)
		}

		// Opening Device
		snaplen := 10000
		promisc := true
		//timeout := 30 * time.Second
		timeout := pcap.BlockForever
		handle, err = pcap.OpenLive(*iface, int32(snaplen), promisc, timeout)
		if err != nil {
			log.Fatal(err)
		}
		defer handle.Close()
		fmt.Printf("Opened interface %s promisc=%v\n", *iface, promisc)
	}
	if *fname != "" {
		var err error
		handle, err = pcap.OpenOffline(*fname)
		if err != nil {
			log.Fatal(err)
		}
		defer handle.Close()
		fmt.Printf("Opened file %s\n", *fname)
	}
	fmt.Printf("   handle=%v\n", handle)

	packetSource := gopacket.NewPacketSource(handle, handle.LinkType())
	n := 0
	for packet := range packetSource.Packets() {
		n += 1
		fmt.Printf("\n%d\n", n)
		fmt.Println(packet.Dump())

		//p := gopacket.NewPacket(packet, CiscoS1PuntHeaderType, gopacket.Lazy)
		//fmt.Println(p)
	}
}
