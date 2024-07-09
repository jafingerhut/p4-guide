all: build

format: pktcollector.go
	gofmt -w pktcollector.go

vet: pktcollector.go format
	go vet pktcollector.go

build: pktcollector.go vet
	go build pktcollector.go

clean:
	/bin/rm -f pktcollector
