# Determining which Python modules are imported by scapy and bf_pktpy

Often importing one Python module results in many others being
imported as a consequence.

Much of the code in this directory is written to make it clear exactly
which modules are imported as a result of importing the `scapy` or
`bf_pktpy` modules.

```bash
./create-test-venvs.sh
./test.sh
```
