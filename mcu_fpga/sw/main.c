#include "haha.h"

#define BEGIN 0xCC
#define YES 0xA5
#define NO 0x5A

int main() {
  haha_uart_init();
  haha_inter_init();

  haha_uart_print_str("Starting program\r\n");
  haha_send_to_fpga(BEGIN);

  while(1) {
    uint8_t response = haha_receive_from_fpga();
    haha_uart_print_str("Received from FPGA: ");
    haha_uart_print_u8_hex(response);
    haha_uart_print_str("\r\n");
    haha_send_to_fpga(YES);
  }

}