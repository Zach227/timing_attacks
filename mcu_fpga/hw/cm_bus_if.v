module cm_bus_if (
    input        drive_en,
    input  [7:0] data_out,
    inout  [7:0] cm,
    output [7:0] data_in
);

    assign cm      = drive_en ? data_out : 8'bZ;
    assign data_in = cm;

endmodule
