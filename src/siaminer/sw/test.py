#!/usr/bin/python

import serial
import array
import re
import os

if __name__ ==  "__main__":

    os.system("./fclk_set 3 20000000")
    os.system("sudo dd of=/dev/xdevcfg if=/home/parallella/siaminer.fclk3_20MHz.bit.bin")

    # 115200, 8, N, 1
    ser = serial.Serial('/dev/ttyPS1', 115200, timeout=100)

    # loop test
    tByte = 0x23
    txData = array.array('B', [0xAA, 0x01, 0x1, tByte]).tostring()
    ser.write(txData)
    rxData = list(ser.read(4))
    print("loop test result:")
    print("%x" % ord(rxData[0]))
    print("%x" % ord(rxData[1]))
    print("%x" % ord(rxData[2]))
    print("%x" % ord(rxData[3]))

    # work test
    works = open('../dv/tests/work.dat', 'r')
    nonces = open('../dv/tests/nonce.dat', 'r')
    targets = open('../dv/tests/target.dat', 'r')

    for work in works:
        work = re.sub(r'_', r'', work)
        print("work: %s" % work.rstrip())

        target = targets.readline()
        nonce = nonces.readline().rstrip()
        data = target.rstrip() + work.rstrip()
        print("data: %s" % data)

        hex_data = data.decode("hex")
        array_data = array.array('B', hex_data)
        array_data.reverse()
        array_data.insert(0, 0xAA)
        array_data.insert(1, 0x00)
        array_data.insert(2, 0x54)

        txData = array_data.tostring()
        ser.write(txData)

        rxData = list(ser.read(7))

        hex_nonce = nonce.decode("hex")
        array_nonce = array.array('B', hex_nonce)
        array_nonce.reverse()
        list_nonce = array_nonce.tolist()

        print("golden:")
        print("%02x" % list_nonce[0])
        print("%02x" % list_nonce[1])
        print("%02x" % list_nonce[2])
        print("%02x" % list_nonce[3])
        if 0x00 == ord(rxData[1]):
            print("nonce:")
            print("%02x" % ord(rxData[3]))
            print("%02x" % ord(rxData[4]))
            print("%02x" % ord(rxData[5]))
            print("%02x" % ord(rxData[6]))
            if (ord(rxData[3]) == list_nonce[0]) \
                & (ord(rxData[4]) == list_nonce[1]) \
                & (ord(rxData[5]) == list_nonce[2]) \
                & (ord(rxData[6]) == list_nonce[3]):
                print("Nonce match with golden")
        else:
            print("error:")
            print("%02x" % ord(rxData[0]))
            print("%02x" % ord(rxData[1]))
            print("%02x" % ord(rxData[2]))
            print("%02x" % ord(rxData[3]))
            print("%02x" % ord(rxData[4]))
            print("%02x" % ord(rxData[5]))
            print("%02x" % ord(rxData[6]))


