// ------------------------------------------------------------------
// cm_bus_if: tri-state bus interface used by top
// - data_out is sampled/registered on rising edge of CLK_inter to
//   give stable outputs synchronized with MCU clock
// - when drive_en==1 the FPGA drives the bus; otherwise bus is Z
// - data_in reads the bus (unsigned 8-bit)
// ------------------------------------------------------------------
module cm_bus_if (
    input  wire       clk,       // MCU clock line
    input  wire       rst,
    input  wire [7:0] data_out,  // value to drive when drive_en=1
    input  wire       drive_en,
    output wire [7:0] data_in,
    inout  wire [7:0] cm
);
    // register outgoing data synchronized to clk (helps setup/hold)
    reg [7:0] out_reg;
    always @(posedge clk or posedge rst) begin
        if (rst)
            out_reg <= 8'h00;
        else
            out_reg <= data_out;
    end

    // tri-state driver: cm driven only when drive_en is asserted
    assign cm = drive_en ? out_reg : 8'bZZ;

    // sample bus asynchronously into FPGA domain via simple assign
    // (top synchronizes usage of data_in using full_pulse and CLK_50 domain)
    assign data_in = cm;

endmodule
