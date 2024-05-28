compile:
	p4c --target bmv2 \
	    --arch v1model \
	    --p4runtime-files flowcache.p4info.txtpb \
	    flowcache.p4

runswitch:
	sudo simple_switch_grpc \
	     --log-file ss-log \
	     --log-flush \
	     --dump-packet-data 10000 \
	     -i 0@veth0 \
	     -i 1@veth2 \
	     -i 2@veth4 \
	     -i 3@veth6 \
	     -i 4@veth8 \
	     -i 5@veth10 \
	     -i 6@veth12 \
	     -i 7@veth14 \
	     --no-p4 \
	     -- --cpu-port 510

loadp4prog:
	./with-pythonpath ./loadp4prog.py

runcontroller:
	./with-pythonpath ./controller.py

terminals:
	../bin/create-terminal-windows.sh port1-veth3 port2-veth5 port3-veth7 port4-veth9

clean:
	/bin/rm \
	    flowcache.json \
	    flowcache.p4i \
	    flowcache.p4info.txtpb \
	    ss-log.txt
