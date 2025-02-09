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

package ringbuf

// Implement a simple finite-capacity ring buffer of elements, where
// the Append method overwrites the oldest element if you Append
// additional elements after the capacity is reached.

// This code is not thread-safe.  That is, it is assumed that if
// multiple threads can call methods on a single ring buffer instance
// concurrently, that the calling threads coordinate the access
// correctly, e.g. by making all calls from a single goroutine that is
// given requests to make such calls via channels, or via a mutex.

import (
	"errors"
)

type Buf struct {
	// The maximum capacity of the ring buffer.
	capacity int
	// The current number of elements in the buffer.
	n int
	// Index of the element appended to the buffer the longest
	// time ago.
	first int
	// Index of the element appended to the buffer most recently.
	last int
	// The elements in the ring buffer.
	elems []interface{}
}

// Return a new ring buffer with the specified capacity, initially
// containing 0 elements.
func New(capacity int) (b *Buf) {
	var x Buf
	x.capacity = capacity
	x.n = 0
	x.first = 0
	x.last = 0
	x.elems = make([]interface{}, capacity)
	return &x
}

// Append a given element to the end of the ring buffer, replacing the
// oldest one if it has reached its capacity.
func (rb *Buf) Append(elem interface{}) (elemDiscarded bool) {
	rb.elems[rb.last] = elem
	rb.last += 1
	if rb.last == rb.capacity {
		rb.last = 0
	}
	if rb.n < rb.capacity {
		rb.n += 1
		return false
	} else {
		// n == capacity, so overwrite the element added
		// longest ago with the new element being appended
		// now.
		rb.first += 1
		if rb.first == rb.capacity {
			rb.first = 0
		}
		return true
	}
}

// Remove the element still in the ring buffer that was appended the
// longest time ago.
func (rb *Buf) RemoveFirst() (elem interface{}, err error) {
	if rb.n == 0 {
		return nil, errors.New("ringbuf is empty")
	}
	rb.n -= 1
	elem = rb.elems[rb.first]
	rb.first += 1
	if rb.first == rb.capacity {
		rb.first = 0
	}
	return elem, nil
}

// Return the length of the ring buffer, i.e. the number of elements
// it currently contains.
func (rb *Buf) Len() (n int) {
	return rb.n
}

// Return a slice of all elements in the ring buffer, with the element
// appended the longest ago in index 0 of the slice, and the element
// appended most recently in the maximum index of the slice, rb.n-1.
func (rb *Buf) Elements() (elems []interface{}) {
	els := make([]interface{}, rb.n)
	j := rb.first
	for i := 0; i < rb.n; i++ {
		els[i] = rb.elems[j]
		j++
		if j == rb.capacity {
			j = 0
		}
	}
	return els
}
