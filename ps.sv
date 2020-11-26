`include "switch.sv"
module ps (NOCI.TI to,NOCI.FO from);

wire clk,reset;
wire tod_ctl,frm_ctl;
wire [7:0] tod_data,frm_data;


assign clk=to.clk;
assign reset=to.reset;
assign tod_ctl=to.noc_to_dev_ctl;
assign tod_data=to.noc_to_dev_data;
assign from.noc_from_dev_ctl=frm_ctl;
assign from.noc_from_dev_data=frm_data;

switch s1 (clk,reset,tod_ctl,tod_data,frm_ctl,frm_data);

endmodule
