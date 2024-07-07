package pktwatcher

import (
	"errors"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/google/gopacket"
	"github.com/google/gopacket/pcap"

	"github.com/jafingerhut/p4-guide/golang/pktcollector/ringbuf"
)

const defaultCapacity = 128

type State struct {
	handle *pcap.Handle
	numCapturedPkts int
	numDiscardedPkts int
	packetBuf *ringbuf.Buf
	debug int
}

type PktInfo struct {
	Timestamp time.Time
	InterfaceIndex int
	PacketData []byte
}

func Start(opts map[string]interface{}) (watcherState *State, err error) {
	var w State
	w.debug = 0
	debugVal, ok := opts["debug"]
	if ok {
		w.debug = debugVal.(int)
		fmt.Fprintf(os.Stderr, "pktwatcher.Start found debug=%d\n", w.debug)
	}
	if name, ok := opts["interface_name"]; ok {
		iname := name.(string)
		snaplen := 10000
		promisc := true
		timeout := pcap.BlockForever
		w.handle, err = pcap.OpenLive(iname, int32(snaplen), promisc, timeout)
		if err != nil {
			return nil, err
		}
		if w.debug >= 1 {
			fmt.Fprintf(os.Stderr, "Opened interface %s promisc=%v\n", name, promisc)
		}
	} else if name, ok := opts["file_name"]; ok {
		fname := name.(string)
		w.handle, err = pcap.OpenOffline(fname)
		if err != nil {
			log.Fatal(err)
			return nil, err
		}
		if w.debug >= 1 {
			fmt.Fprintf(os.Stderr, "Opened file %s\n", name)
		}
	} else {
		err = errors.New("neither of the option keys 'interface_name' nor 'file_name' were present")
		log.Fatal(err)
		return nil, err
	}
	capacity := defaultCapacity
	if capacityVal, ok := opts["capacity"]; ok {
		capacity = capacityVal.(int)
	}
	w.numDiscardedPkts = 0
	w.packetBuf, err = ringbuf.New(capacity)
	if err != nil {
		return nil, err
	}
	return &w, nil
}

func capturePackets(w *State) {
	if w.debug >= 1 {
		fmt.Println("started capturing packets to in-memory ringbuf")
	}
	packetSource := gopacket.NewPacketSource(w.handle, w.handle.LinkType())
	w.numCapturedPkts = 0
	w.numDiscardedPkts = 0
	for packet := range packetSource.Packets() {
		w.numCapturedPkts += 1
		pktMeta := packet.Metadata()
		pktTimestamp := pktMeta.Timestamp
		pktInterfaceIndex := pktMeta.InterfaceIndex
		pktData := packet.Data()
		pktDiscarded := w.packetBuf.Append(PktInfo{
			Timestamp: pktTimestamp,
			InterfaceIndex: pktInterfaceIndex,
			PacketData: pktData})
		if pktDiscarded {
			w.numDiscardedPkts += 1
		} else {
			w.numCapturedPkts += 1
		}
		if w.debug >= 2 {
			fmt.Printf("\n%d\n", w.numCapturedPkts)
			fmt.Println(packet.Dump())
			//p := gopacket.NewPacket(packet, CiscoS1PuntHeaderType, gopacket.Lazy)
			//fmt.Println(p)
		}
	}
}
