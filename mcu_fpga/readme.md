


## challenges
- For the previous lab the MC interconnect was an input to the fpga and an output for the MCU. But for this timing attack I need the fpga to send guess to the MCU, and the for the MCU to respond. The bus has to switch between input and output as the MCU and FPGA talk to each other. Hopefully I don't break the board by by both tyring to drive the bus at the same time.
- I wrote an implementation of a timing attack but it was too big for the FPGA