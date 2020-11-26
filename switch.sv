`include "box.sv"

module switch (NOCI.TI to,NOCI.FO from);

//box1 device 40 intferace and module instantiation
NOCI bi1 (to.clk, to.reset);
box b1 (bi1.TI,bi1.FO);


//box1 device 40 wires
assign bi1.noc_to_dev_ctl=to.noc_to_dev_ctl;
assign bi1.noc_to_dev_data=to.noc_to_dev_data;
assign from.noc_from_dev_ctl=bi1.noc_from_dev_ctl;
assign from.noc_from_dev_data=bi1.noc_from_dev_data;


endmodule
