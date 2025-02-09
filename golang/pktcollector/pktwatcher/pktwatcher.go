// Copyright 2024 Andy Fingerhut
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0

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
	"time"

	"github.com/google/gopacket"

	"github.com/jafingerhut/p4-guide/golang/pktcollector/ringbuf"
)

const defaultCapacity = 128

type respReadAndClear struct {
	packetBuf *ringbuf.Buf
}

type cmdReadAndClear struct {
	resp chan<- respReadAndClear
}

type State struct {
	capacity int
	numCapturedPkts int
	numDiscardedPkts int
	packetBuf *ringbuf.Buf
	debug int
	c <-chan gopacket.Packet
	cmdsRAC chan cmdReadAndClear
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
		if w.debug >= 1 {
			fmt.Fprintf(os.Stderr, "pktwatcher.Start found debug=%d\n", w.debug)
		}
	}
	w.capacity = defaultCapacity
	if capacityVal, ok := opts["capacity"]; ok {
		w.capacity = capacityVal.(int)
	}
	w.numCapturedPkts = 0
	w.numDiscardedPkts = 0
	w.packetBuf = ringbuf.New(w.capacity)
	w.c = c
	w.cmdsRAC = make(chan cmdReadAndClear)
	go capturePackets(&w)
	return &w, nil
}

func (w *State) ReadAndClearPackets() (curPackets *ringbuf.Buf) {
	respChan := make(chan respReadAndClear)
	w.cmdsRAC <- cmdReadAndClear{resp: respChan}
	resp := <-respChan
	pkts := resp.packetBuf
	return pkts
}

func capturePackets(w *State) {
	if w.debug >= 1 {
		fmt.Println("started capturing packets to in-memory ringbuf")
	}
	w.numCapturedPkts = 0
	w.numDiscardedPkts = 0
	for {
		select {
		case packet, ok := <-w.c:
			if !ok {
				w.c = nil
				if w.debug >= 2 {
					fmt.Println("pktwatcher read channel was closed.  Assigning it nil.")
				}
				continue
			}
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
		case cmd := <-w.cmdsRAC:
			// Get the current ring buffer, and replace it with a new,
			// empty one.
			r := respReadAndClear{packetBuf: w.packetBuf}
			w.packetBuf = ringbuf.New(w.capacity)
			cmd.resp <- r
		}
	}
}
