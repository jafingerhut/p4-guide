Without apt-get libssl-dev:
+ protobuf build succeeded
+ grpc build failed

With apt-get libssl-dev:
+ protobuf build succeeded
+ grpc build failed, with warnings about a function named
  `ENGINE_free()` being deprecated since OpenSSL 3.0


Try changing this option to cmake for gRPC build:
```
      -DgRPC_SSL_PROVIDER=package && \
```
to this:
```
      -DgRPC_SSL_PROVIDER=module && \
```

That _also_ failed to build gRPC v1.62.3 from source.

On aarch64 Ubuntu 24.04:

```bash
sudo apt-get install python3-venv python3-dev
python3 -m venv ~/myvenv1
source ~/myvenv1/bin/activate
# This installs _very_ quickly
python3 -m pip install protobuf==4.21.12
# This takes longer before I find out whether it works.
# Fails without installing python3-dev first.
python3 -m pip install grpcio==1.51.1


# aarch64 Ubuntu 24.04
sudo apt-get install python3-dev python3-venv
# libssl-dev package was not installed
python3 -m venv ~/myvenv1
source ~/myvenv1/bin/activate
python3 -m pip install --upgrade pip
python3 -m pip install --upgrade setuptools

python3 -m pip install grpcio==1.51.1  # slow fails cygrpc.c
python3 -m pip install grpcio==1.51.3  # slow fails cygrpc.c
python3 -m pip install grpcio==1.53.2  # slow fails cygrpc.c
python3 -m pip install grpcio==1.54.3  # slow fails cygrpc.c
python3 -m pip install grpcio==1.55.3  # slow fails cygrpc.c
python3 -m pip install grpcio==1.56.2  # slow fails cygrpc.c
python3 -m pip install grpcio==1.57.0  # slow fails cygrpc.c
pip3 install --no-cache-dir  --force-reinstall -Iv grpcio==1.58.3 # fails cygrpc.c

# All of the following versions also install successfully
# and quickly on x86_64 Ubuntu 24.04.
pip3 install --no-cache-dir  --force-reinstall -Iv grpcio==1.59.5 # fast success, probably installing from precompiled binary
pip3 install --no-cache-dir  --force-reinstall -Iv grpcio==1.60.2 # fast success, probably installing from precompiled binary
pip3 install --no-cache-dir  --force-reinstall -Iv grpcio==1.61.3 # fast success, probably installing from precompiled binary
pip3 install --no-cache-dir  --force-reinstall -Iv grpcio==1.62.3 # fast success, probably installing from precompiled binary
pip3 install --no-cache-dir  --force-reinstall -Iv grpcio==1.63.2 # fast success, probably installing from precompiled binary
pip3 install --no-cache-dir  --force-reinstall -Iv grpcio==1.64.3 # fast success, probably installing from precompiled binary
```
