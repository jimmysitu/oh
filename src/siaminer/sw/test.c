#include <fcntl.h>
#include <termios.h>
#include <stdio.h>
#include <stdint.h>
#include <unistd.h>

#define BAUDRATE B115200
#define TTYDEVICE "/dev/ttyPS1"

void main(){
    int fd;
    int *dev = &fd;
    struct termios options;
    fd = open(TTYDEVICE, O_RDWR | O_NOCTTY | O_NDELAY);
    if(*dev == -1){
        printf("Failed to open tty device\n");
        return;
    }
    
    fcntl(*dev, F_SETFL, 0);
    
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

    // Misc setting
    options.c_iflag &= ~(BRKINT | ICRNL | IMAXBEL);
    options.c_oflag &= ~(OPOST | ONLCR);
    options.c_lflag &= ~(ISIG | ICANON | IEXTEN | ECHO | ECHOE | ECHOK | ECHOCTL | ECHOKE);

    options.c_cc[VMIN]  = 0;
    options.c_cc[VTIME] = 10;
    
    // Setting configuration
    tcsetattr(*dev, TCSANOW, &options);

    uint8_t loop_test[4] = {0xAA, 0x01, 0x01, 0x00};
    uint8_t loop_ack[4];

    int t;
    t = write(*dev, loop_test, 4);
    if(4 == t){
        printf("loop test sent: 0x%02X, 0x%02X, 0x%02X, 0x%02X\n",
                loop_test[0], loop_test[1], loop_test[2], loop_test[3]);
    }else{
        printf("Loop test error, wrote %d\n", t);
    }
    
    sleep(2);

    t = read(*dev, loop_ack, 4);
    if(4 == t){
        printf("loop ack got: 0x%02X, 0x%02X, 0x%02X, 0x%02X\n",
                loop_ack[0], loop_ack[1], loop_ack[2], loop_ack[3]);
    }else{
        printf("Loop ack error, read %d\n", t);
    }

    if(1 == (loop_ack[3] - loop_test[3])){
        printf("Loop test pass, detected tty device works fine\n");
    }else{
        printf("Loop test fail, ack btye error\n");
    }

    // Hash test
//    uint64_t data[10] = {     
//        0x5D02000000000000,
//        0x4C1530E8862513E8,
//        0x474B940BBABEEEEF,
//        0x6EA321EB235C2AE9,
//        0x0000000000000000,
//        0x00000000584AB401,
//        0x3E1D8DBFA05F73E8,
//        0xFD53C016085D46B4,
//        0xAE8FBD793A2C3DFF,
//        0xE285A7BB9EACC0A5
//    };
    uint64_t data[3][10] = {
        {
            0x1400000000000000,
            0xF1B9293F98C707A1,
            0x5E2B51347B3A22C2,
            0x3EE4BE13A9EA7BA5,
            0x0000000000000000,
            0x0000000059468AB0,
            0x25C1B405F6900E2C,
            0x534A5B20279C2B44,
            0xAF5F4C366197B471,
            0xC18A8649991E3F7D
        },{
            0x1400000000000000,
            0xF1B9293F98C707A1,
            0x5E2B51347B3A22C2,
            0x3EE4BE13A9EA7BA5,
            0x0000000000000000,
            0x0000000059468AD1,
            0xBD4147A948D78F59,
            0x2FF67A1916DA81EF,
            0xB3C426E39A978F87,
            0xCF0C3FBFCF973AE5
        },{
            0x5D02000000000000,
            0x4C1530E8862513E8,
            0x474B940BBABEEEEF,
            0x6EA321EB235C2AE9,
            0x0000000000000000,
            0x00000000584AB401,
            0x3E1D8DBFA05F73E8,
            0xFD53C016085D46B4,
            0xAE8FBD793A2C3DFF,
            0xE285A7BB9EACC0A5
        }
    };
    
    
    uint32_t golden_nonce = 0x881C0A02;
    uint32_t target[1] = {0xFFFFFFFF};
    
    // send work (data and target) to tty device
    uint8_t header[3] = {0xAA, 0x00, 0x54};  // Send work command header
    write(*dev, header, 3);
    write(*dev, &data[0], 80);
    write(*dev, target, 4);
    
    uint32_t last_nonce;
    uint8_t msg[7];

    int cnt = 0;
    while(cnt < 1000){
        // Read tty device to get the golden nonces
        int rd = read(*dev, msg, 7);
        if(7 == rd){
            last_nonce = *((uint32_t*)&msg[3]);
            printf("[TTY] tty device found something, nonce: 0x%08x\n", last_nonce);
            printf("[TTY] golden nonce: 0x%08x\n", golden_nonce);
            break;
        }else if(0 == rd){
            printf("[TTY] tty device read %d btyes, waiting %d\n", rd, cnt);
            cnt++;
        }else{
            printf("[TTY] tty device read %d btyes, error\n", rd);
            cnt++;
        }
        
        // Try to refresh work, and check
        if(0 == (cnt % 7)){
            write(*dev, header, 3);
            write(*dev, &data[cnt % 3], 80);
            write(*dev, target, 4);
            printf("[TTY] Refresh with new work %d\n", cnt % 3);
        }
    }



    // Close tty device
    close(*dev);
}
