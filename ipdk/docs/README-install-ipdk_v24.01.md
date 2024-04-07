Start by following all of the instructions
[here](README-install-ipdk-networking-container-ubuntu-20.04-and-test.md),
up to, and including, the step where you clone the ipdk repository
with these commands:

```bash
cd $HOME
git clone https://github.com/ipdk-io/ipdk.git
```

From here forward there are a few small changes, and you should follow
only the steps below.

```bash
cd ipdk
git checkout ipdk_v24.01
sed 's/ipdk_v23.07/ipdk_v24.01/' build/networking/scripts/download_nr_src_code.sh > /tmp/foo.sh
cp /tmp/foo.sh build/networking/scripts/download_nr_src_code.sh

cd build
./ipdk install
export PATH=$HOME/ipdk/build:$PATH
cd ..
ipdk install ubuntu2004    # if base OS is Ubuntu
ipdk install fedora33      # if base OS is Fedora

ipdk build --no-cache |& tee $HOME/log-ipdk-build.txt
```
