UART Loop Test
=======
UART loop test IP, for siaminer simple test

## Build Instructions (on your regular machine)

```sh
git clone https://github.com/jimmysitu/oh     # clone repo
cd uartloop 
cd ./fpga
./build.sh                                     # build bitstream
sudo cp parallella.bit.bin /media/$user/boot   # burn bitstream onto SD card on laptop/desktop
sync                                           # sync and insert SD card in parallella
```

## Testing Instructions (on Parallella)
```sh
git clone https://github.com/jimmysitu/oh    # clone repo
cd uartloop/sw             
#TODO: add mining scripts

```





