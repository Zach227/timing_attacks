#include "haha.h"

#define START_BYTE 0x01
#define BEGIN_GUESSING 0x02
#define YES 0x03
#define NO 0x04
#define END_BYTE 0x05

#define SECRET_CODE_LEN 32
const uint8_t SECRET_CODE[32] = {
0xa3, 0xf9, 0x1c, 0x7e, 0x54, 0xb2, 0x89, 0xd0,
0xe1, 0xc4, 0xfa, 0x66, 0x78, 0xd9, 0xb2, 0xc1,
0x35, 0x0e, 0x9a, 0xfd, 0x44, 0x32, 0x1b, 0xe0,
0xc7, 0xd8, 0xf5, 0x09, 0xe2, 0xaa, 0x97, 0x77};


#define DEBUG_MODE 0


int main() {
  haha_uart_init();
  haha_inter_init();

  haha_uart_print_str("Starting program\r\n");
  haha_send_to_fpga(BEGIN_GUESSING);

  uint8_t receive_buffer[256];

  while(1) {
    uint8_t received_byte = haha_receive_from_fpga();
    if (received_byte != START_BYTE) {
      continue;
    }
    
    if (DEBUG_MODE) {
      haha_uart_print_str("Received start byte: ");
      haha_uart_print_u8_hex(received_byte);
      haha_uart_print_str("\r\n");
    }

    uint8_t index = 0;

    while(1) {
      received_byte = haha_receive_from_fpga();
      if (received_byte == END_BYTE) {
        if (DEBUG_MODE) {
          haha_uart_print_str("Received end byte: ");
          haha_uart_print_u8_hex(received_byte);
          haha_uart_print_str("\r\n");
        }
        break;
      }

      if (index < sizeof(receive_buffer)) {
        receive_buffer[index++] = received_byte;
      }
      if (DEBUG_MODE) {
        haha_uart_print_str("Received data\r\n");
      }
    }

    if (DEBUG_MODE) {
      haha_uart_print_str("Received guess: ");
      for (uint8_t i = 0; i < index; i++) {
        haha_uart_print_u8_hex(receive_buffer[i]);
        haha_uart_print_str(" ");
      }
      haha_uart_print_str("\r\n\n");
    }

    uint8_t correct = 1;
    for (uint8_t i = 0; i < SECRET_CODE_LEN; i++) {
      if (receive_buffer[i] != SECRET_CODE[i]) {
        correct = 0;
        break;
      }
    }

    if (correct) {
      haha_send_to_fpga(YES);
      haha_uart_print_str("Correct guess!\r\n");
      haha_uart_print_str("Secret Code was:");
      
      for (uint8_t i = 0; i < SECRET_CODE_LEN; i++) {
        haha_uart_print_u8_hex(receive_buffer[i]);
        haha_uart_print_str(" ");
      }

      haha_uart_print_str("\r\n");
    }
    else {
      haha_send_to_fpga(NO);
    }
  }
}