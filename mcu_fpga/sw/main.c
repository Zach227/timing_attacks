#include "haha.h"

#define START_BYTE 0x01
#define BEGIN_GUESSING 0x02
#define YES 0x03
#define NO 0x04
#define END_BYTE 0x05


#define SECRET_CODE_LEN 1
const uint8_t SECRET_CODE[SECRET_CODE_LEN] = {0x5A};


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
    
    haha_uart_print_str("Received start byte: ");
    haha_uart_print_u8_hex(received_byte);
    haha_uart_print_str("\r\n");


    uint8_t index = 0;

    while(1) {
      received_byte = haha_receive_from_fpga();
      if (received_byte == END_BYTE) {
        haha_uart_print_str("Received end byte: ");
        haha_uart_print_u8_hex(received_byte);
        haha_uart_print_str("\r\n");
        break;
      }

      if (index < sizeof(receive_buffer)) {
        receive_buffer[index++] = received_byte;
      }
      haha_uart_print_str("Received data\r\n");
    }

    haha_uart_print_str("Received guess: ");
    for (uint8_t i = 0; i < index; i++) {
      haha_uart_print_u8_hex(receive_buffer[i]);
      haha_uart_print_str(" ");
    }
    haha_uart_print_str("\r\n\n");

    uint8_t correct = 1;
    for (uint8_t i = 0; i < SECRET_CODE_LEN; i++) {
      if (receive_buffer[i] != SECRET_CODE[i]) {
        correct = 0;
        break;
      }
    }

    if (correct) {
      haha_uart_print_str("Correct guess!\r\n");
      haha_send_to_fpga(YES);
    }
    else {
      haha_send_to_fpga(NO);
    }
  }
}