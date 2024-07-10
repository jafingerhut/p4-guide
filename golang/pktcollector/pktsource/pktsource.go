package pktsource

// Get packets from either a live capture from a network interface, or
// from a pcap file, and write them to a channel.  The intent is that
// some other part of the program will be processing these packets
// after reading them from the channel.

// If packets are obtained from a network interface, write them to the
// channel as soon as possible after they are captured.

// TODO: The comments below describe the behavior I would like to
// implement for this package when reading from a pcap file, but so
// far the only behavior implemented is to write packets from the pcap
// file to the channel as quickly as possible, which is the desired
// behavior if firstPacketWaitTimeSeconds == 0.0 and timeScale == 0.0.

// If packets are obtained from a pcap file, attempt to write them to
// the channel with similar separations of time as are recorded in the
// pcap file.

// More precisely, let S be the time that packet production from a
// pcap file began, and let F be the time recorded with the first
// packet of the pcap file, and let T be the time recorded for some
// other packet in the pcap file after the first.

// There are two input parameters used to control when packets are
// produced: firstPacketWaitTimeSeconds, abbreviated W, and timeScale,
// abbreviated C.

// The first packet is sent to the channel as soon after time S+W as
// possible, but no earlier.

// Later packets with time T in the file are sent to the channel as
// soon after time (S+W)+C*(T-F) as possible, but no earlier.

// Examples:

// If C=0.0, then packets are produced as fast as possible, starting at
// time (S+W).

// If C=1.0, then packets are produced as close to the rate recorded
// in the pcap file times as possible, starting at time (S+W).

// If C=3.0, then packets are produced 1/3 as quickly as the rate
// recorded in the pcap file, starting at time (S+W).

import (
	"errors"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/google/gopacket"
	"github.com/google/gopacket/pcap"
)

type State struct {
	fromFile bool
	firstPacketWaitTimeSeconds float64
	timeScale float64
	numCapturedPkts int
	debug int
	handle *pcap.Handle
	packetSource *gopacket.PacketSource
	c <- chan gopacket.Packet
}

func Start(opts map[string]interface{}) (c <- chan gopacket.Packet, s *State, err error) {
	var w State
	w.debug = 0
	debugVal, ok := opts["debug"]
	if ok {
		w.debug = debugVal.(int)
		fmt.Fprintf(os.Stderr, "pktsource.Start found debug=%d\n", w.debug)
	}
	intfName, ok1 := opts["interface_name"]
	fileName, ok2 := opts["file_name"]
	if (ok1 && ok2) || (!ok1 && !ok2) {
		err = errors.New("must specify exactly one of the option keys 'interface_name' nor 'file_name'")
		log.Fatal(err)
		return nil, nil, err
	}
	returnDelayedChannel := false
	if ok1 {
		iname := intfName.(string)
		snaplen := 10000
		promisc := true
		timeout := pcap.BlockForever
		w.handle, err = pcap.OpenLive(iname, int32(snaplen), promisc, timeout)
		if err != nil {
			return nil, nil, err
		}
		w.fromFile = false
		if w.debug >= 1 {
			fmt.Fprintf(os.Stderr, "Opened interface %s promisc=%v\n", intfName, promisc)
		}
	} else if ok2 {
		fname := fileName.(string)
		w.handle, err = pcap.OpenOffline(fname)
		if err != nil {
			log.Fatal(err)
			return nil, nil, err
		}
		w.fromFile = true
		if w.debug >= 1 {
			fmt.Fprintf(os.Stderr, "Opened file %s\n", fileName)
		}
		w.firstPacketWaitTimeSeconds = 0.0
		if num, ok := opts["firstPacketWaitTimeSeconds"]; ok {
			w.firstPacketWaitTimeSeconds = num.(float64)
		}
		w.timeScale = 1.0
		if num, ok := opts["timeScale"]; ok {
			w.timeScale = num.(float64)
		}
		returnDelayedChannel = true
		if w.firstPacketWaitTimeSeconds == 0.0 && w.timeScale == 0.0 {
			returnDelayedChannel = false
		}
	}
	w.packetSource = gopacket.NewPacketSource(w.handle, w.handle.LinkType())
	w.c = w.packetSource.Packets()
	if returnDelayedChannel {
		dc := delayedChannel(&w)
		w.c = dc
	}
	return w.c, &w, nil
}

func delayedChannel(s *State) (delayedChan <- chan gopacket.Packet) {
	origChan := s.c
	c := make(chan gopacket.Packet)
	go feedDelayedChannel(s, origChan, c)
	return c
}

func feedDelayedChannel(s *State, origChan <- chan gopacket.Packet, delayedChan chan<- gopacket.Packet) {
	// Calculate the time that the first packet should be written to
	// delayedChan.
	startTime := time.Now()
	firstPkt := true
	delta := time.Duration(s.firstPacketWaitTimeSeconds * float64(time.Second))
	firstPktSendTime := startTime.Add(delta)

	var firstOrigPktTime time.Time
	var nextPktSendTime time.Time
	for pkt := range origChan {
		pktMeta := pkt.Metadata()
		pktTimestamp := pktMeta.Timestamp
		if firstPkt {
			firstPkt = false
			firstOrigPktTime = pktTimestamp
			nextPktSendTime = firstPktSendTime
		} else {
			// origTimeDelta is the Duration after the first packet's
			// time stamp, until the current packet's time stamp.
			// Typically we expect this should be a positive duration.
			origTimeDelta := pktTimestamp.Sub(firstOrigPktTime)
			// sendTimeDelta is equalto origTimeDelta, scaled by the
			// parameter s.timeScale, so we can speed up or slow down
			// the inter-packet times.
			sendTimeDelta := time.Duration(float64(origTimeDelta) * s.timeScale)
			nextPktSendTime = firstPktSendTime.Add(sendTimeDelta)
		}
		time.Sleep(nextPktSendTime.Sub(time.Now()))
		delayedChan <- pkt
	}
}
