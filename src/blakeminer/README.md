BLAKECOIN
=======

A FPGA-Blakecoin-Miner on Parallella 

## Build Instructions (on your regular machine)

```sh
git clone https://github.com/jimmysitu/oh     # clone repo
cd blakecoin/dv
./build.sh                                     # build
./run.sh tests/hello.emf                       # load data
gtkwave waveform.vcd                           # view waveform
emacs ../hdl/accelerator.v                     # "put code here"
cd ../fpga
./build.sh                                     # build bitstream
sudo cp parallella.bit.bin /media/$user/boot   # burn bitstream onto SD card on laptop/desktop
sync                                           # sync and insert SD card in parallella
```

## Testing Instructions (on Parallella)
```sh
git clone https://github.com/jimmysitu/oh    # clone repo
cd blakecoin/sw             
#TODO: add mining scripts

```





