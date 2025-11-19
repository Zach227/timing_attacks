There are 3 buttons for the FPGA on the HaHa board.

Human guesses the secret key made up of 4 button presses. E.g. 0, 1, 0, 2.

After the final button press, the FPGA will take 4 cycles to compare the key. If any index does not match the key, it will immediately exit the comparison function and set an LED or GPIO high. If the key is correct, a different LED or GPIO will go high.

**Potential challenges**
* Becuase the buttons must be debounced, the start time of the compare function (which starts when the 4th button is debounced) may vary. This may make it hard to do the timing attack. To help, the FPGA can set an LED high and then start comparing. This will give a reference start point.
* To allow for testing different keys easily, use the switches to set the key so we don't have to rebuild the hw design each time.
