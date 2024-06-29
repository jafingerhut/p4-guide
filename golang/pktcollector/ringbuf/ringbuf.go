package ringbuf

import (
	"errors"
)

type Buf struct {
	capacity, n, first, last int
	elems []interface{}
}

func New(capacity int) (b *Buf, err error) {
	var x Buf
	x.capacity = capacity
	x.n = 0
	x.first = 0
	x.last = 0
	x.elems = make([]interface{}, capacity)
	return &x, nil
}

func (rb *Buf) Append(elem interface{}) {
	rb.elems[rb.last] = elem
	rb.last += 1
	if rb.n < rb.capacity {
		rb.n += 1
	} else {
		// n == capacity, so overwrite the element added
		// longest ago
		rb.first += 1
	}
}

func (rb *Buf) RemoveFirst() (elem interface{}, err error) {
	if rb.n == 0 {
		return nil, errors.New("ringbuf is empty")
	}
	rb.n -= 1
	elem = rb.elems[rb.first]
	rb.first += 1
	return elem, nil
}
