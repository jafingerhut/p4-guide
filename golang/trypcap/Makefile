all: build

format: trypcap.go
	gofmt -w trypcap.go

vet: trypcap.go format
	go vet trypcap.go

build: trypcap.go vet
	go build trypcap.go

