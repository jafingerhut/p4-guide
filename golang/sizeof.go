package main

// Getting the size of several types of variables in Go.

// Inspiration from some answers here:
// https://stackoverflow.com/questions/26975738/how-to-get-memory-size-of-variable

import (
	"fmt"
	"reflect"
	"time"
)

type uint16pair struct {
	x uint16
	y uint16
}

func main() {
	var i int
	var b byte
	var i16 int16
	var i32 int32
	var i64 int64
	s1 := "foo"
	s2 := "the quick brown fox jumped over the lazy dog"
	now := time.Now()
	var p uint16pair

	fmt.Printf("%4d reflect.TypeOf(int).Size()\n",
		reflect.TypeOf(i).Size())
	fmt.Printf("%4d reflect.TypeOf(byte).Size()\n",
		reflect.TypeOf(b).Size())
	fmt.Printf("%4d reflect.TypeOf(int16).Size()\n",
		reflect.TypeOf(i16).Size())
	fmt.Printf("%4d reflect.TypeOf(int32).Size()\n",
		reflect.TypeOf(i32).Size())
	fmt.Printf("%4d reflect.TypeOf(int64).Size()\n",
		reflect.TypeOf(i64).Size())
	fmt.Printf("%4d reflect.TypeOf(string with %d chars).Size()\n",
		len(s1), reflect.TypeOf(s1).Size())
	fmt.Printf("%4d reflect.TypeOf(string with %d chars).Size()\n",
		len(s2), reflect.TypeOf(s2).Size())
	fmt.Printf("%4d reflect.TypeOf(time.Time).Size()\n",
		reflect.TypeOf(now).Size())
	fmt.Printf("%4d reflect.TypeOf(uint16pair struct containing 2 uint16 fields).Size()\n",
		reflect.TypeOf(p).Size())
}
