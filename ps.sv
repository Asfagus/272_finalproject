`include "switch.sv"
module ps (NOCI.TI to,NOCI.FO from);

//instantiate the interface for switch
NOCI si (to.clk,to.reset);

//instantiate module for switch
switch s1 (si.TI,si.FO);

//connect wires
assign si.noc_to_dev_ctl=to.noc_to_dev_ctl;
assign si.noc_to_dev_data=to.noc_to_dev_data;
assign from.noc_from_dev_ctl=si.noc_from_dev_ctl;
assign from.noc_from_dev_data=si.noc_from_dev_data;


endmodule
