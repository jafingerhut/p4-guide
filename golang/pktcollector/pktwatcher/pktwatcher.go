package pktwatcher

// When this package's Start function is called, a goroutine is
// started that reads packets (type gopacket.Packet) from the provided
// channel, and processes each one.

// In this case, processing a packet is pretty trivial: append it to a
// ring buffer, which causes the packet appended longest ago to be
// forgotten if the ring buffer is at its capacity.

// The function ReadAndClearPackets can be called at any time.  It
// returns the current contents of the ring buffer, and creates a new
// empty ring buffer for recording any packets read from the channel
// later.

import (
	"fmt"
	"os"
	"sync"
	"time"

	"github.com/google/gopacket"

	"github.com/jafingerhut/p4-guide/golang/pktcollector/ringbuf"
)

const defaultCapacity = 128

type State struct {
	capacity int
	numCapturedPkts int
	numDiscardedPkts int
	packetBuf *ringbuf.Buf
	debug int
	c <-chan gopacket.Packet
	mu sync.Mutex  // guards this entire struct
}

type PktInfo struct {
	Timestamp time.Time
	InterfaceIndex int
	PacketData []byte
}

func Start(opts map[string]interface{}, c <-chan gopacket.Packet) (watcherState *State, err error) {
	var w State
	w.debug = 0
	debugVal, ok := opts["debug"]
	if ok {
		w.debug = debugVal.(int)
		fmt.Fprintf(os.Stderr, "pktwatcher.Start found debug=%d\n", w.debug)
	}
	w.capacity = defaultCapacity
	if capacityVal, ok := opts["capacity"]; ok {
		w.capacity = capacityVal.(int)
	}
	w.numCapturedPkts = 0
	w.numDiscardedPkts = 0
	w.packetBuf = ringbuf.New(w.capacity)
	w.c = c
	go capturePackets(&w)
	return &w, nil
}

func (w *State) ReadAndClearPackets() (curPackets *ringbuf.Buf) {
	// Create a new ring buffer to use for later packets
	rb := ringbuf.New(w.capacity)

	// Get the current ring buffer, and replace it with the new,
	// empty one.
	w.mu.Lock()
	pkts := w.packetBuf
	w.packetBuf = rb
	w.mu.Unlock()
	return pkts
}

func capturePackets(w *State) {
	if w.debug >= 1 {
		fmt.Println("started capturing packets to in-memory ringbuf")
	}
	w.numCapturedPkts = 0
	w.numDiscardedPkts = 0
	for packet := range w.c {
		w.mu.Lock()
		pktDiscarded := w.packetBuf.Append(packet)
		if pktDiscarded {
			w.numDiscardedPkts += 1
		} else {
			w.numCapturedPkts += 1
		}
		if w.debug >= 2 {
			fmt.Printf("\n%d\n", w.numCapturedPkts)
			fmt.Println(packet.Dump())
		}
		w.mu.Unlock()
	}
}
