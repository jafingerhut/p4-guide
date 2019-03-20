The file [`README-scapy.md`](README-scapy.md) was created while using
the Scapy library for Python 2.  This file attempts to reproduce all
of the experiments there, updating them for Python 3.

One issue with Python 3 and Scapy is that there are (at least) two
major versions of Scapy for Python 3.  A description of the current
situation as of 2019-Mar-19 is below, copied from https://scapy.net on
that date:

An independent fork of Scapy was created from v2.2.0 in 2015, aimed at
supporting only Python3
([scapy3k](https://github.com/phaethon/kamene)).  The fork diverged,
did not follow evolutions and fixes, and has had its own life without
contributions back to Scapy.  Unfortunately, it has been packaged as
`python3-scapy` in some distributions, and as `scapy-python3` on PyPI
leading to confusion amongst users.  It should not be the case anymore
soon.  Scapy supports Python3 in addition to Python2 since 2.4.0.
Scapy v2.4.0 should be favored as the official Scapy code base.  The
fork has been renamed as `kamene`.

As of 2019-Mar-19, Ubuntu 18.04 Linux package `python3-scapy` is the
`kamene` version described above.


## Base Python software installed on Ubuntu 16.04.6 Desktop Linux for amd64 arch

```bash
$ which python
/usr/bin/python
$ python -V
Python 2.7.12

$ which python3
/usr/bin/python3
$ python3 -V
Python 3.5.2

$ which pip
[ ... no output, because it is not installed ... ]

[I believe that this command installs pip only for Python 2]
$ sudo apt-get install python-pip
$ pip list | wc -l
5

$ sudo apt-get install python3-pip
$ pip3 list | wc -l
66
```


## Base Python software installed on Ubuntu 18.04.2 Desktop Linux for amd64 arch, minimal install


Prerequisite for the experiments below:

```python
from scapy.all import *
```


## Python type `bytes` vs. `str`

One primary difference seems to be that Python 3 Scapy uses the Python
type `bytes` rather than `str` in many places.  While the following is
probably common knowledge to more experienced Python programmers, here
are some differences between type `str` and `bytes` that I have
determined via experiments, run in Python 3.6.7:

A value of type `str` is a sequence of 1-character strings.  You can
get its `len`, you can get length 1 values of type `str` by index via
an expression `v[int_index]`, and you can get arbitrary length
substrings of type `str` via a slice expression like
`v[start_index:end_index]`.

```python
>>> type('\x83\x03\x10')
<class 'str'>
>>> len('\x83\x03\x10')
3

>>> type('\x83\x03\x10'[1])
<class 'str'>
>>> '\x83\x03\x10'[1]
'\x03'
>>> len('\x83\x03\x10'[1])
1

>>> type('\x83\x03\x10'[1:3])
<class 'str'>
>>> '\x83\x03\x10'[1:3]
'\x03\x10'
```

A literal value of type `bytes` can be written by prefixing it with
the character `b`.

A value of type `bytes` is a sequence of `int` values in the range
`[0, 255]`.  You can get its `len`, you can get a single value of type
`int` by index via an expression `v[int_index]`, and you can get
arbitrary length sub-bytearrays of type `bytes` via a slice expression
like `v[start_index:end_index]`.

```python
>>> type(b'\x83\x03\x10')
<class 'bytes'>
>>> len(b'\x83\x03\x10')
3
>>> type(b'\x83\x03\x10'[1])
<class 'int'>
>>> b'\x83\x03\x10'[1]
3

>>> type(b'\x83\x03\x10'[1:3])
<class 'bytes'>
>>> b'\x83\x03\x10'[1:3]
b'\x03\x10'
>>> len(b'\x83\x03\x10'[1:3])
2
```

TBD: There must be built-in methods for converting between type `str`
and `bytes`, I would guess.  There might even be more than one,
depending upon character set encoding, perhaps?


## Some very basic differences from Scapy on Python 2 to Scapy on Python 3

With Scapy on Python 2, you can construct a packet, then call `str` or
`bytes` on it and get back a value of type `str` in both cases, and
those values are the same regardless of whether you called `str` or
`bytes`:

```python
# Scapy on Python 2

>>> pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5792, dport=80)
>>> pkt1s=str(pkt1)
>>> pkt1b=bytes(pkt1)
>>> type(pkt1s)
<type 'str'>
>>> len(pkt1s)
54
>>> type(pkt1b)
<type 'str'>
>>> len(pkt1b)
54
>>> pkt1s == pkt1b
True
>>> pkt1
<Ether  type=0x800 |<IP  frag=0 proto=tcp dst=10.1.0.1 |<TCP  sport=5792 dport=http |>>>
>>> pkt1s
"\xff\xff\xff\xff\xff\xff\x08\x00'V\x85\xa4\x08\x00E\x00\x00(\x00\x01\x00\x00@\x06d\xbf\n\x00\x02\x0f\n\x01\x00\x01\x16\xa0\x00P\x00\x00\x00\x00\x00\x00\x00\x00P\x02 \x00b\xe2\x00\x00"
>>> pkt1b
"\xff\xff\xff\xff\xff\xff\x08\x00'V\x85\xa4\x08\x00E\x00\x00(\x00\x01\x00\x00@\x06d\xbf\n\x00\x02\x0f\n\x01\x00\x01\x16\xa0\x00P\x00\x00\x00\x00\x00\x00\x00\x00P\x02 \x00b\xe2\x00\x00"
```

With Scapy on Python 3, I can construct the packet similarly to the
above, but it seems to require super-user (i.e. root) privileges in
order to convert it to type `bytes`.  That seems _very_ weird to me.
Perhaps the Ubuntu `python3-scapy` package is has not been created
correctly?


## Alternate way to install Scapy for Python 3, using `virtualenv`

Install `virtualenv` on Ubuntu 18.04 Linux using:

```bash
$ sudo apt-get install virtualenv
```

Try to create a `virtualenv` for Python 3 and install Scapy using
`pip`:

```bash
$ virtualenv --python=python3 my-venv --system-site-packages
$ source my-venv/bin/activate

# Long list of packages inherited from the system-wide Python 3
# installed packages, because this virtualenv was created using
# `--system-site-packages` option above:

$ pip list | wc
     64     128    2688

# Including the Scapy for Python 3 package that I had installed
# earlier using `sudo apt-get install python3-scapy` on Ubuntu 18.04
# Linux:

$ pip list | grep -i scapy
scapy-python3         0.23               

$ pip3 install scapy-python3
Requirement already satisfied: scapy-python3 in /usr/lib/python3/dist-packages (0.23)
```

Try again without using `--system-site-packages`:

```bash
# Delete former virtualenv
$ /bin/rm -fr my-venv

$ virtualenv --python=python3 my-venv
$ source my-venv/bin/activate

# Much shorter pip package list this time:

$ pip list | wc
      6      12     132

# And Scapy is not one of them:

$ pip list
Package       Version
------------- -------
pip           19.0.3 
pkg-resources 0.0.0  
setuptools    40.8.0 
wheel         0.33.1 

$ pip3 install scapy-python3
Collecting scapy-python3
  Downloading https://files.pythonhosted.org/packages/4f/f3/e33d21e25b0dda2ffeebcc3ad06d26eff7f913c9b8b397c30f443b68b8e4/scapy-python3-0.26.tar.gz
Building wheels for collected packages: scapy-python3
  Building wheel for scapy-python3 (setup.py) ... done
  Stored in directory: /home/jafinger/.cache/pip/wheels/0b/50/c1/76fa505f0e9f227db58be19be5f7cb1245d379b38f61c290af
Successfully built scapy-python3
Installing collected packages: scapy-python3
Successfully installed scapy-python3-0.26

$ which python
/home/jafinger/p4-guide/bin/my-venv/bin/python

$ python -V
Python 3.6.7
```

Interesting message when I try to run Python 3 with this version of
Scapy:

```python
>>> from scapy.all import *

        PIP package scapy-python3 used to provide scapy3k, which was a fork from scapy implementing python3 compatibility since 2016. This package was included in some of the Linux distros under name of python3-scapy. Starting from scapy version 2.4 (released in March, 2018) mainstream scapy supports python3. To reduce any confusion scapy3k was renamed to kamene. 
You should use either pip package kamene for scapy3k (see http://github.com/phaethon/kamene for differences in use) or mainstream scapy (pip package scapy, http://github.com/secdev/scapy).  

Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "/home/jafinger/p4-guide/bin/my-venv/lib/python3.6/site-packages/scapy/all.py", line 5, in <module>
    raise Exception(msg)
```

It looks like I should not be installing this package, but simply `pip
install scapy` instead.  Try that in the next section.



## Yet another way to install Scapy for Python 3, using `virtualenv`

```bash
$ sudo apt-get install virtualenv
```

Create a `virtualenv` without using `--system-site-packages`:

```bash
# Delete former virtualenv
$ /bin/rm -fr my-venv

$ virtualenv --python=python3 my-venv
$ source my-venv/bin/activate

# Much shorter pip package list this time:

$ pip list | wc
      6      12     132

# And Scapy is not one of them:

$ pip list
Package       Version
------------- -------
pip           19.0.3 
pkg-resources 0.0.0  
setuptools    40.8.0 
wheel         0.33.1 

$ pip3 install scapy
Collecting scapy
  Using cached https://files.pythonhosted.org/packages/d0/04/b8512e5126a1816581767bf95cbf525e0681a22c055bcd45f47ecff60170/scapy-2.4.2.tar.gz
Building wheels for collected packages: scapy
  Building wheel for scapy (setup.py) ... error
  Complete output from command /home/jafinger/p4-guide/bin/my-venv/bin/python3 -u -c "import setuptools, tokenize;__file__='/tmp/pip-install-j5vi_z3o/scapy/setup.py';f=getattr(tokenize, 'open', open)(__file__);code=f.read().replace('\r\n', '\n');f.close();exec(compile(code, __file__, 'exec'))" bdist_wheel -d /tmp/pip-wheel-k329ptch --python-tag cp36:
  running bdist_wheel
  running build
  running build_py
  creating build
  creating build/lib
  creating build/lib/scapy

[ ... many lines of output not included here ... ]

  running install_scripts
  creating build/bdist.linux-x86_64/wheel/scapy-2.4.2.data/scripts
  copying build/scripts-3.6/UTscapy -> build/bdist.linux-x86_64/wheel/scapy-2.4.2.data/scripts
  copying build/scripts-3.6/scapy -> build/bdist.linux-x86_64/wheel/scapy-2.4.2.data/scripts
  changing mode of build/bdist.linux-x86_64/wheel/scapy-2.4.2.data/scripts/UTscapy to 755
  changing mode of build/bdist.linux-x86_64/wheel/scapy-2.4.2.data/scripts/scapy to 755
  error: [Errno 2] No such file or directory: 'LICENSE'
  
  ----------------------------------------
  Failed building wheel for scapy
  Running setup.py clean for scapy
Failed to build scapy
Installing collected packages: scapy
  Running setup.py install for scapy ... done
Successfully installed scapy-2.4.2

[I see the error messages there, but will try proceeding despite them,
in hopes that they do not hurt my ability to use Scapy on Python 3.]

$ which python
/home/jafinger/p4-guide/bin/my-venv/bin/python

$ python -V
Python 3.6.7
```

I got consistent errors when trying to convert a Scapy packet object
to type `str` or `bytes`, which went away when I ran Python as
super-user/root.  Here are what the error messages looked like when I
ran as a non-root user:

```python
>>> from scapy.all import *
>>> pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5792, dport=80)
>>> pkt1s=str(pkt1)
Exception ignored in: <bound method SuperSocket.__del__ of <scapy.arch.linux.L2Socket object at 0x7f8dde757a90>>
Traceback (most recent call last):
  File "/home/jafinger/p4-guide/bin/my-venv/lib/python3.6/site-packages/scapy/supersocket.py", line 123, in __del__
    self.close()
  File "/home/jafinger/p4-guide/bin/my-venv/lib/python3.6/site-packages/scapy/arch/linux.py", line 481, in close
    set_promisc(self.ins, self.iface, 0)
AttributeError: 'L2Socket' object has no attribute 'ins'
```

Here are the results when I ran as user root via the command `sudo
python`:

```python
>>> from scapy.all import *
>>> pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5792, dport=80)
>>> pkt1s=str(pkt1)
>>> pkt1b=bytes(pkt1)
>>> type(pkt1s)
<type 'str'>
>>> type(pkt1b)
<type 'str'>
>>> pkt1s==pkt1b
True
```


## Create Scapy packet with IPv4 options

I found a working example of using Scapy to generate IPv4 headers with
IP options here: http://allievi.sssup.it/techblog/archives/631

This version works with Python 2 Scapy, but gives an error with Python
3 Scapy, I suspect because of the type `str` argument to `IPOption`:

```python
pkt_with_opts=Ether() / IP(dst='10.1.0.1', options=IPOption('\x83\x03\x10')) / TCP(sport=5792, dport=80)
```

Try changing the type of that parameter to `bytes` by prefixing the
string literal with a `b`:

```python
pkt1=Ether() / IP(dst='10.1.0.1') / TCP(sport=5792, dport=80)
pkt_with_opts=Ether() / IP(dst='10.1.0.1', options=IPOption(b'\x83\x03\x10')) / TCP(sport=5792, dport=80)
```
