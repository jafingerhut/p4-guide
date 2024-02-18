# Making a P4Runtime API connection from Python program running in the base OS, to infrap4d running in the container

Note: You can ignore this section if you prefer to run P4Runtime API
client programs in the container.

First copy the current cryptographic key/certificate files required
for a client to authenticate itself to the server.  This step only
needs to be done once each time these files change.  One event that
causes these files to change is running `ipdk connect` from the base
OS.

When the container is started, it is done in a way such that the
directory `/tmp` in the container is equivalent to the directory
`$HOME/.ipdk/volume` in the base OS.  That is, any changes made to the
directory on one side is immediately reflected on the other side.

In the container:
```bash
cp /usr/share/stratum/certs/{ca.crt,client.key,client.crt} /tmp/
```

In the base OS:
```bash
mkdir ~/my-certs
sudo cp ~/.ipdk/volume/{ca.crt,client.crt,client.key} ~/my-certs
sudo chown `id --user --name`:`id --group --name` ~/my-certs/*
```

After this setup, you should be able to run the test client program
with this command.  The `test-client.py` program takes an optional
parameter that is the name of a directory where it should find the
files `ca.crt`, `client.crt`, and `client.key` that were copied above.

In the base OS:
```bash
source ~/my-venv/bin/activate
~/p4-guide/ipdk/test-client.py ~/my-certs/
```
