#include "haha.h"

#define BEGIN 0xCC
#define YES 0xA5
#define NO 0x5A

#define SECRET_CODE 0x42

int main() {
  haha_uart_init();
  haha_inter_init();

  haha_uart_print_str("Starting program\r\n");
  haha_send_to_fpga(BEGIN);

  while(1) {
    uint8_t guess = haha_receive_from_fpga();
    haha_uart_print_str("Received from FPGA: ");
    haha_uart_print_u8_hex(guess);
    haha_uart_print_str("\r\n");
    if (guess == SECRET_CODE) {
      haha_send_to_fpga(YES);
    }
    else {
      haha_send_to_fpga(NO);
    }
  }
}