package pktwatcher

import (
	"fmt"
	"log"
	"os"

	"github.com/google/gopacket/pcap"
)

type PktwatcherState struct {
	handle *pcap.Handle
}

func init(opts map[string]interface{}) (err error) {
	var handle *pcap.Handle
	if name, ok := opts["interface_name"]; ok {
		snaplen := 10000
		promisc := true
		timeout := pcap.BlockForever
		handle, err = pcap.OpenLive(name, int32(snaplen), promisc, timeout)
		if err != nil {
			log.Fatal(err)
			return err
		}
		if opts["debug"] {
			fmt.Fprintf(os.Stderr, "Opened interface %s promisc=%v\n", name, promisc)
		}
	} else if name, ok := opts["file_name"]; ok {
		handle, err = pcap.OpenOffline(*fname)
		if err != nil {
			log.Fatal(err)
			return err
		}
		if opts["debug"] {
			fmt.Fprintf(os.Stderr, "Opened file %s\n", name)
		}
	} else {
		err = error.New("neither of the option keys 'interface_name' nor 'file_name' were present")
		log.Fatal(err)
		return err
	}
}
