# RVBug2

- Find the bugs and fix them!

## Installation

```bash
$ git clone https://github.com/shmknrk/rvbug2.git
$ cd rvbug2
$ git submodule update --init --recursive
$ echo 'export PATH="/path/to/riscv-gnu-toolchain:$PATH"' >> ~/.bashrc
$ echo 'export PATH="/path/to/simrv:$PATH"' >> ~/.bashrc
$ source ~/.bashrc
$ make -C prog/riscv-tests
$ make -C prog/coremark
```

## Usage

```bash
$ cd rvbug2

# riscv-tests/isa
$ make add
$ make sub
...
$ make auipc

# all riscv-tests/isa
$ make isa

# coremark
$ make coremark
```
