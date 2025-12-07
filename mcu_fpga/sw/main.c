#include "haha.h"

#define START_BYTE 0x01
#define BEGIN_GUESSING 0x02
#define YES 0x03
#define NO 0x04
#define END_BYTE 0x05

#define SECRET_CODE_LEN 16
const uint8_t SECRET_CODE[SECRET_CODE_LEN] = {0x2A, 0x98, 0xF3, 0x66, 0x2A, 0x87, 0x11, 0xCA, 0x14, 0x33, 0xE6, 0x6D, 0x0F, 0x67, 0x27, 0x55};

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
    _delay_us(5);
    }

    if (correct) {
      haha_send_to_fpga(YES);
      haha_uart_print_str("Correct guess!\r\n");
      haha_uart_print_str("Secret Code was:");
      
      for (uint8_t i = 0; i < index; i++) {
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