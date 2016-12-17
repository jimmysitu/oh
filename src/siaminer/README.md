SIACOIN MINER
=======

A FPGA-Siacoin-Miner on Parallella 

## Build Instructions (on your regular machine)

```sh
git clone https://github.com/jimmysitu/oh     # clone repo
cd siaminer
# TODO: add generate rtl script here
cd ./fpga
./build.sh                                     # build bitstream
sudo cp parallella.bit.bin /media/$user/boot   # burn bitstream onto SD card on laptop/desktop
sync                                           # sync and insert SD card in parallella
```

## Testing Instructions (on Parallella)
```sh
git clone https://github.com/jimmysitu/oh    # clone repo
cd siaminer/sw             
#TODO: add mining scripts

```





