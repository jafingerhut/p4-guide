package ringbuf

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
