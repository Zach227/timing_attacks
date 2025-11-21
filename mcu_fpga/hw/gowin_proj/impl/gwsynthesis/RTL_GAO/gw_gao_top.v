module gw_gao(
    \SW[0] ,
    \CM[7] ,
    \CM[6] ,
    \CM[5] ,
    \CM[4] ,
    \CM[3] ,
    \CM[2] ,
    \CM[1] ,
    \CM[0] ,
    \LED[7] ,
    \LED[6] ,
    \LED[5] ,
    \LED[4] ,
    \LED[3] ,
    \LED[2] ,
    \LED[1] ,
    \LED[0] ,
    \current_state[3] ,
    \current_state[2] ,
    \current_state[1] ,
    \current_state[0] ,
    \next_state[3] ,
    \next_state[2] ,
    \next_state[1] ,
    \next_state[0] ,
    \data_out[7] ,
    \data_out[6] ,
    \data_out[5] ,
    \data_out[4] ,
    \data_out[3] ,
    \data_out[2] ,
    \data_out[1] ,
    \data_out[0] ,
    \guess_byte[7] ,
    \guess_byte[6] ,
    \guess_byte[5] ,
    \guess_byte[4] ,
    \guess_byte[3] ,
    \guess_byte[2] ,
    \guess_byte[1] ,
    \guess_byte[0] ,
    \data_in[7] ,
    \data_in[6] ,
    \data_in[5] ,
    \data_in[4] ,
    \data_in[3] ,
    \data_in[2] ,
    \data_in[1] ,
    \data_in[0] ,
    \cmb_0/data_out[7] ,
    \cmb_0/data_out[6] ,
    \cmb_0/data_out[5] ,
    \cmb_0/data_out[4] ,
    \cmb_0/data_out[3] ,
    \cmb_0/data_out[2] ,
    \cmb_0/data_out[1] ,
    \cmb_0/data_out[0] ,
    \cmb_0/data_in[7] ,
    \cmb_0/data_in[6] ,
    \cmb_0/data_in[5] ,
    \cmb_0/data_in[4] ,
    \cmb_0/data_in[3] ,
    \cmb_0/data_in[2] ,
    \cmb_0/data_in[1] ,
    \cmb_0/data_in[0] ,
    \cmb_0/cm[7] ,
    \cmb_0/cm[6] ,
    \cmb_0/cm[5] ,
    \cmb_0/cm[4] ,
    \cmb_0/cm[3] ,
    \cmb_0/cm[2] ,
    \cmb_0/cm[1] ,
    \cmb_0/cm[0] ,
    \cmb_0/out_reg[7] ,
    \cmb_0/out_reg[6] ,
    \cmb_0/out_reg[5] ,
    \cmb_0/out_reg[4] ,
    \cmb_0/out_reg[3] ,
    \cmb_0/out_reg[2] ,
    \cmb_0/out_reg[1] ,
    \cmb_0/out_reg[0] ,
    CLK_50,
    CLK_inter,
    drive_en,
    clk_inter_d,
    clk_rise,
    clk_fall,
    saw_rise,
    full_pulse,
    \cmb_0/clk ,
    \cmb_0/rst ,
    \cmb_0/drive_en ,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input \SW[0] ;
input \CM[7] ;
input \CM[6] ;
input \CM[5] ;
input \CM[4] ;
input \CM[3] ;
input \CM[2] ;
input \CM[1] ;
input \CM[0] ;
input \LED[7] ;
input \LED[6] ;
input \LED[5] ;
input \LED[4] ;
input \LED[3] ;
input \LED[2] ;
input \LED[1] ;
input \LED[0] ;
input \current_state[3] ;
input \current_state[2] ;
input \current_state[1] ;
input \current_state[0] ;
input \next_state[3] ;
input \next_state[2] ;
input \next_state[1] ;
input \next_state[0] ;
input \data_out[7] ;
input \data_out[6] ;
input \data_out[5] ;
input \data_out[4] ;
input \data_out[3] ;
input \data_out[2] ;
input \data_out[1] ;
input \data_out[0] ;
input \guess_byte[7] ;
input \guess_byte[6] ;
input \guess_byte[5] ;
input \guess_byte[4] ;
input \guess_byte[3] ;
input \guess_byte[2] ;
input \guess_byte[1] ;
input \guess_byte[0] ;
input \data_in[7] ;
input \data_in[6] ;
input \data_in[5] ;
input \data_in[4] ;
input \data_in[3] ;
input \data_in[2] ;
input \data_in[1] ;
input \data_in[0] ;
input \cmb_0/data_out[7] ;
input \cmb_0/data_out[6] ;
input \cmb_0/data_out[5] ;
input \cmb_0/data_out[4] ;
input \cmb_0/data_out[3] ;
input \cmb_0/data_out[2] ;
input \cmb_0/data_out[1] ;
input \cmb_0/data_out[0] ;
input \cmb_0/data_in[7] ;
input \cmb_0/data_in[6] ;
input \cmb_0/data_in[5] ;
input \cmb_0/data_in[4] ;
input \cmb_0/data_in[3] ;
input \cmb_0/data_in[2] ;
input \cmb_0/data_in[1] ;
input \cmb_0/data_in[0] ;
input \cmb_0/cm[7] ;
input \cmb_0/cm[6] ;
input \cmb_0/cm[5] ;
input \cmb_0/cm[4] ;
input \cmb_0/cm[3] ;
input \cmb_0/cm[2] ;
input \cmb_0/cm[1] ;
input \cmb_0/cm[0] ;
input \cmb_0/out_reg[7] ;
input \cmb_0/out_reg[6] ;
input \cmb_0/out_reg[5] ;
input \cmb_0/out_reg[4] ;
input \cmb_0/out_reg[3] ;
input \cmb_0/out_reg[2] ;
input \cmb_0/out_reg[1] ;
input \cmb_0/out_reg[0] ;
input CLK_50;
input CLK_inter;
input drive_en;
input clk_inter_d;
input clk_rise;
input clk_fall;
input saw_rise;
input full_pulse;
input \cmb_0/clk ;
input \cmb_0/rst ;
input \cmb_0/drive_en ;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire \SW[0] ;
wire \CM[7] ;
wire \CM[6] ;
wire \CM[5] ;
wire \CM[4] ;
wire \CM[3] ;
wire \CM[2] ;
wire \CM[1] ;
wire \CM[0] ;
wire \LED[7] ;
wire \LED[6] ;
wire \LED[5] ;
wire \LED[4] ;
wire \LED[3] ;
wire \LED[2] ;
wire \LED[1] ;
wire \LED[0] ;
wire \current_state[3] ;
wire \current_state[2] ;
wire \current_state[1] ;
wire \current_state[0] ;
wire \next_state[3] ;
wire \next_state[2] ;
wire \next_state[1] ;
wire \next_state[0] ;
wire \data_out[7] ;
wire \data_out[6] ;
wire \data_out[5] ;
wire \data_out[4] ;
wire \data_out[3] ;
wire \data_out[2] ;
wire \data_out[1] ;
wire \data_out[0] ;
wire \guess_byte[7] ;
wire \guess_byte[6] ;
wire \guess_byte[5] ;
wire \guess_byte[4] ;
wire \guess_byte[3] ;
wire \guess_byte[2] ;
wire \guess_byte[1] ;
wire \guess_byte[0] ;
wire \data_in[7] ;
wire \data_in[6] ;
wire \data_in[5] ;
wire \data_in[4] ;
wire \data_in[3] ;
wire \data_in[2] ;
wire \data_in[1] ;
wire \data_in[0] ;
wire \cmb_0/data_out[7] ;
wire \cmb_0/data_out[6] ;
wire \cmb_0/data_out[5] ;
wire \cmb_0/data_out[4] ;
wire \cmb_0/data_out[3] ;
wire \cmb_0/data_out[2] ;
wire \cmb_0/data_out[1] ;
wire \cmb_0/data_out[0] ;
wire \cmb_0/data_in[7] ;
wire \cmb_0/data_in[6] ;
wire \cmb_0/data_in[5] ;
wire \cmb_0/data_in[4] ;
wire \cmb_0/data_in[3] ;
wire \cmb_0/data_in[2] ;
wire \cmb_0/data_in[1] ;
wire \cmb_0/data_in[0] ;
wire \cmb_0/cm[7] ;
wire \cmb_0/cm[6] ;
wire \cmb_0/cm[5] ;
wire \cmb_0/cm[4] ;
wire \cmb_0/cm[3] ;
wire \cmb_0/cm[2] ;
wire \cmb_0/cm[1] ;
wire \cmb_0/cm[0] ;
wire \cmb_0/out_reg[7] ;
wire \cmb_0/out_reg[6] ;
wire \cmb_0/out_reg[5] ;
wire \cmb_0/out_reg[4] ;
wire \cmb_0/out_reg[3] ;
wire \cmb_0/out_reg[2] ;
wire \cmb_0/out_reg[1] ;
wire \cmb_0/out_reg[0] ;
wire CLK_50;
wire CLK_inter;
wire drive_en;
wire clk_inter_d;
wire clk_rise;
wire clk_fall;
wire saw_rise;
wire full_pulse;
wire \cmb_0/clk ;
wire \cmb_0/rst ;
wire \cmb_0/drive_en ;
wire tms_pad_i;
wire tck_pad_i;
wire tdi_pad_i;
wire tdo_pad_o;
wire tms_i_c;
wire tck_i_c;
wire tdi_i_c;
wire tdo_o_c;
wire [9:0] control0;
wire gao_jtag_tck;
wire gao_jtag_reset;
wire run_test_idle_er1;
wire run_test_idle_er2;
wire shift_dr_capture_dr;
wire update_dr;
wire pause_dr;
wire enable_er1;
wire enable_er2;
wire gao_jtag_tdi;
wire tdo_er1;

IBUF tms_ibuf (
    .I(tms_pad_i),
    .O(tms_i_c)
);

IBUF tck_ibuf (
    .I(tck_pad_i),
    .O(tck_i_c)
);

IBUF tdi_ibuf (
    .I(tdi_pad_i),
    .O(tdi_i_c)
);

OBUF tdo_obuf (
    .I(tdo_o_c),
    .O(tdo_pad_o)
);

GW_JTAG  u_gw_jtag(
    .tms_pad_i(tms_i_c),
    .tck_pad_i(tck_i_c),
    .tdi_pad_i(tdi_i_c),
    .tdo_pad_o(tdo_o_c),
    .tck_o(gao_jtag_tck),
    .test_logic_reset_o(gao_jtag_reset),
    .run_test_idle_er1_o(run_test_idle_er1),
    .run_test_idle_er2_o(run_test_idle_er2),
    .shift_dr_capture_dr_o(shift_dr_capture_dr),
    .update_dr_o(update_dr),
    .pause_dr_o(pause_dr),
    .enable_er1_o(enable_er1),
    .enable_er2_o(enable_er2),
    .tdi_o(gao_jtag_tdi),
    .tdo_er1_i(tdo_er1),
    .tdo_er2_i(1'b0)
);

gw_con_top  u_icon_top(
    .tck_i(gao_jtag_tck),
    .tdi_i(gao_jtag_tdi),
    .tdo_o(tdo_er1),
    .rst_i(gao_jtag_reset),
    .control0(control0[9:0]),
    .enable_i(enable_er1),
    .shift_dr_capture_dr_i(shift_dr_capture_dr),
    .update_dr_i(update_dr)
);

ao_top u_ao_top(
    .control(control0[9:0]),
    .data_i({\SW[0] ,\CM[7] ,\CM[6] ,\CM[5] ,\CM[4] ,\CM[3] ,\CM[2] ,\CM[1] ,\CM[0] ,\LED[7] ,\LED[6] ,\LED[5] ,\LED[4] ,\LED[3] ,\LED[2] ,\LED[1] ,\LED[0] ,\current_state[3] ,\current_state[2] ,\current_state[1] ,\current_state[0] ,\next_state[3] ,\next_state[2] ,\next_state[1] ,\next_state[0] ,\data_out[7] ,\data_out[6] ,\data_out[5] ,\data_out[4] ,\data_out[3] ,\data_out[2] ,\data_out[1] ,\data_out[0] ,\guess_byte[7] ,\guess_byte[6] ,\guess_byte[5] ,\guess_byte[4] ,\guess_byte[3] ,\guess_byte[2] ,\guess_byte[1] ,\guess_byte[0] ,\data_in[7] ,\data_in[6] ,\data_in[5] ,\data_in[4] ,\data_in[3] ,\data_in[2] ,\data_in[1] ,\data_in[0] ,\cmb_0/data_out[7] ,\cmb_0/data_out[6] ,\cmb_0/data_out[5] ,\cmb_0/data_out[4] ,\cmb_0/data_out[3] ,\cmb_0/data_out[2] ,\cmb_0/data_out[1] ,\cmb_0/data_out[0] ,\cmb_0/data_in[7] ,\cmb_0/data_in[6] ,\cmb_0/data_in[5] ,\cmb_0/data_in[4] ,\cmb_0/data_in[3] ,\cmb_0/data_in[2] ,\cmb_0/data_in[1] ,\cmb_0/data_in[0] ,\cmb_0/cm[7] ,\cmb_0/cm[6] ,\cmb_0/cm[5] ,\cmb_0/cm[4] ,\cmb_0/cm[3] ,\cmb_0/cm[2] ,\cmb_0/cm[1] ,\cmb_0/cm[0] ,\cmb_0/out_reg[7] ,\cmb_0/out_reg[6] ,\cmb_0/out_reg[5] ,\cmb_0/out_reg[4] ,\cmb_0/out_reg[3] ,\cmb_0/out_reg[2] ,\cmb_0/out_reg[1] ,\cmb_0/out_reg[0] ,CLK_50,CLK_inter,drive_en,clk_inter_d,clk_rise,clk_fall,saw_rise,full_pulse,\cmb_0/clk ,\cmb_0/rst ,\cmb_0/drive_en }),
    .clk_i(CLK_50)
);

endmodule
