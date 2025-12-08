


## challenges
- For the previous lab the MC interconnect was an input to the fpga and an output for the MCU. But for this timing attack I need the fpga to send guess to the MCU, and the for the MCU to respond. The bus has to switch between input and output as the MCU and FPGA talk to each other. Hopefully I don't break the board by by both tyring to drive the bus at the same time.
- I wrote an implementation of a timing attack but it was too big for the FPGA



| Number of Bytes | Time |
|----------|----------|
| 1 | 0.3 | 
| 2 | 0.6 | 
| 4 | 0.9 | 
| 8 | 1.8 | 
| 16 | 3.6 |
| 32 | 7.25 |

estimated time to brute force 1 byte = 0.225
estimated time to make one guess = 0.225/250 = 0.0009s = 900 us
estimated time to brute force 2 bytes = 900us * 250^2 = 56.25 seconds
estimated time to brute force 4 bytes = 900us * 250^4 = 40.7 days
estimated time to brute force 8 bytes = 900us * 250^8 = 441 million years




