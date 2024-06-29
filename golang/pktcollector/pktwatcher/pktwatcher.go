package pktwatcher

import (
	"errors"
	"fmt"
	"log"
	"os"

	"github.com/google/gopacket/pcap"
)

type PktWatcherState struct {
	handle *pcap.Handle
}

func Start(opts map[string]interface{}) (watcherState *PktWatcherState, err error) {
	var w PktWatcherState
	debug := false
	debugVal, ok := opts["debug"]
	if ok {
		debug = debugVal.(bool)
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
		if debug {
			fmt.Fprintf(os.Stderr, "Opened interface %s promisc=%v\n", name, promisc)
		}
	} else if name, ok := opts["file_name"]; ok {
		fname := name.(string)
		w.handle, err = pcap.OpenOffline(fname)
		if err != nil {
			log.Fatal(err)
			return nil, err
		}
		if debug {
			fmt.Fprintf(os.Stderr, "Opened file %s\n", name)
		}
	} else {
		err = errors.New("neither of the option keys 'interface_name' nor 'file_name' were present")
		log.Fatal(err)
		return nil, err
	}
	return &w, nil
}
