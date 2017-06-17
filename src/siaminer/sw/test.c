#include <fcntl.h>
#include <termios.h>
#include <stdio.h>

#define BAUDRATE B115200
#define TTYDEVICE "/dev/ttyPS1"

void main(){
    int fd;
    int *dev = &fd;
    struct termios options;
    fd = open(TTYDEVICE, O_RDWR | O_NOCTTY);
    if(*dev == -1){
        printf("Failed to open tty device");
        return;
    }

    // Get current options
    tcgetattr(*dev, &options);

    // Setting baudrate
    cfsetispeed(&options, BAUDRATE);
    cfsetospeed(&options, BAUDRATE);

    // Enable the receiver and set local mode, 8N1
    options.c_cflag |= (CLOCAL | CREAD);
    options.c_cflag &= ~PARENB;
    options.c_cflag &= ~CSTOPB;
    options.c_cflag &= ~CSIZE;
    options.c_cflag |= CS8;

    // Setting configuration
    tcsetattr(*dev, TCSANOW, &options);

    uint8_t loop_test[4] = {0xAA, 0x01, 0x01, 0x00};
    uint8_t loop_ack[4];

    int t;
    t = write(*dev, loop_test, 4);
    if(4 == t){
        printf("loop test sent: 0x%02X, 0x%02X, 0x%02X, 0x%02X",
                loop_test[0], loop_test[1], loop_test[2], loop_test[3]);
    }else{
        printf("Loop test error");
    }

    t = read(*dev, loop_ack, 4);
    if(4 == t){
        printf("loop ack got: 0x%02X, 0x%02X, 0x%02X, 0x%02X",
                loop_ack[0], loop_ack[1], loop_ack[2], loop_ack[3]);
    }else{
        printf("Loop ack error");
    }

    if(1 == (loop_ack[4] - loop_test[4])){
        printf("Loop test pass, detected tty device works fine");
    }

    // close tty device
    close(*dev);
}
