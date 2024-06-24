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
	"github.com/google/gopacket/pcap"
)

// Things in pcap package:
// func FindAllDevs() (ifs []Interface, err error)

var iface = flag.String("iface", "en0", "Select interface where to capture")

func main() {
	flag.Parse()

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
	handle, err := pcap.OpenLive(*iface, int32(snaplen), promisc, timeout)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("Opened interface %s promisc=%v\n", *iface, promisc)
	fmt.Printf("   handle=%v\n", handle)
	defer handle.Close()

	packetSource := gopacket.NewPacketSource(handle, handle.LinkType())
	n := 0
	for packet := range packetSource.Packets() {
		n += 1
		fmt.Printf("\n%d\n", n)
		fmt.Println(packet)
		//fmt.Printf("%v\n", packet)
	}
}
