//this module encapsulates the NOC and 4 mems and perm from switch

`include "perm.sv"
`include "m55.sv"
`include "nochw2.sv"

module box (NOCI.TI to,NOCI.FO from);

wire clk,reset;
wire tod_ctl,frm_ctl;
wire [7:0] tod_data,frm_data;

assign clk=to.clk;
assign reset=to.reset;
assign tod_ctl=to.noc_to_dev_ctl;
assign tod_data=to.noc_to_dev_data;
assign from.noc_from_dev_ctl=frm_ctl;
assign from.noc_from_dev_data=frm_data;


reg [63:0] din,dout;
reg [2:0] m1ax,m1ay,m1wx,m1wy,m2ax,m2ay,m2wx,m2wy,m3ax,m3ay,m3wx,m3wy,m4ax,m4ay,m4wx,m4wy;
reg [63:0] m1rd,m1wd,m2rd,m2wd,m3rd,m3wd,m4rd,m4wd;


//device 40
perm_blk perm(clk,reset,pushin,stopin,firstin,din,
    m1ax,m1ay,m1rd,m1wx,m1wy,m1wr,m1wd,
    m2ax,m2ay,m2rd,m2wx,m2wy,m2wr,m2wd,
    m3ax,m3ay,m3rd,m3wx,m3wy,m3wr,m3wd,
    m4ax,m4ay,m4rd,m4wx,m4wy,m4wr,m4wd,
    pushout,stopout,firstout,dout);
    
m55 m1(clk,reset,m1ax,m1ay,m1rd,m1wx,m1wy,m1wr,m1wd);
m55 m2(clk,reset,m2ax,m2ay,m2rd,m2wx,m2wy,m2wr,m2wd);
m55 m3(clk,reset,m3ax,m3ay,m3rd,m3wx,m3wy,m3wr,m3wd);
m55 m4(clk,reset,m4ax,m4ay,m4rd,m4wx,m4wy,m4wr,m4wd);

noc_intf n(clk,reset,
    tod_ctl,tod_data,frm_ctl,frm_data,
    pushin,firstin,stopin,din,pushout,firstout,stopout,dout);

endmodule
