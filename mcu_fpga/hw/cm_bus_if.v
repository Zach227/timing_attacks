module cm_bus_if (
    input        clk,
    input        rst,

    // FPGA -> MCU
    input  [7:0] data_out,    // byte you want to send
    input        drive_en,    // 1 = FPGA drives bus, 0 = FPGA listens

    // MCU -> FPGA
    output [7:0] data_in,     // byte received from MCU

    inout  [7:0] cm           // shared bus
);

    // Registered output for clean bus timing
    reg [7:0] out_reg;
    always @(posedge clk) begin
        if (rst)
            out_reg <= 8'h00;
        else
            out_reg <= data_out;
    end

    // Tri-state driver:
    // FPGA drives when drive_en = 1
    assign cm = drive_en ? out_reg : 8'bZ;

    // Read MCU data when NOT driving
    assign data_in = cm;

endmodule
