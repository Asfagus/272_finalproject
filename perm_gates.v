/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Ultra(TM) in wire load mode
// Version   : K-2015.06-SP5-1
// Date      : Sat Nov 28 21:49:07 2020
/////////////////////////////////////////////////////////////


module ps ( \to.clk , \to.reset , \to.noc_to_dev_ctl , \to.noc_to_dev_data , 
        \from.clk , \from.reset , \from.noc_from_dev_ctl , 
        \from.noc_from_dev_data  );
  input [7:0] \to.noc_to_dev_data ;
  output [7:0] \from.noc_from_dev_data ;
  input \to.clk , \to.reset , \to.noc_to_dev_ctl , \from.clk , \from.reset ;
  output \from.noc_from_dev_ctl ;

  tri   \to.clk ;
  tri   \to.reset ;
  tri   \to.noc_to_dev_ctl ;
  tri   [7:0] \to.noc_to_dev_data ;
  tri   \from.noc_from_dev_ctl ;
  tri   [7:0] \from.noc_from_dev_data ;

  switch s1 ( .p1(\to.clk ), .p2(\to.reset ), .p3(\to.noc_to_dev_ctl ), .p4(
        \to.noc_to_dev_data ), .p5(\to.clk ), .p6(\to.reset ), .p7(
        \from.noc_from_dev_ctl ), .p8(\from.noc_from_dev_data ) );
endmodule

