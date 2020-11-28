`include "box.sv"

//exchange 40 and 91 in fromdata


module switch (NOCI.TI to,NOCI.FO from);

//selected interface for to 
NOCI sel (to.clk, to.reset);

//box1 device 40 intferace and module instantiation
NOCI bi1 (to.clk, to.reset);
box b1 (bi1.TI,bi1.FO);

//box2 device 41 intferace and module instantiation
NOCI bi2 (to.clk, to.reset);
box b2 (bi2.TI,bi2.FO);

//enum for device select
enum reg [2:0] {reset_ds,devsel_ds,remain_ds}ps_ds,ns_ds;
//enum for driving selected device
enum reg [2:0] {reset_dr,devsel_dr}ps_dr,ns_dr;


//ff to store cmd byte from noc_to_dev_data
reg [7:0] cmd,cmd_d;

//destination ID 40,41,42,43
reg [7:0] dest_id_d,dest_id;

//delay to.noc_to_dev_data two cycles
reg [7:0]delay,delay_d,delay1,delay1_d;

//delay to.noc_to_dev_ctl two cycles
reg delayctl,delayctl_d,delayctl1,delayctl1_d;

always @ (*)begin
	ns_ds=ps_ds;
	cmd_d=cmd;
	dest_id_d=dest_id;
	ns_dr=ps_dr;
	//delay flops
	delay_d=delay;
	delay1_d=delay1;
	delayctl_d=delayctl;
	delayctl1_d=delayctl1;
	//delay todevice data
	delay_d=to.noc_to_dev_data;
	delay1_d=delay;
	//delay ctl
	delayctl_d=to.noc_to_dev_ctl;
	delayctl1_d=delayctl;
	
	//return path is hardwired to box1
	from.noc_from_dev_ctl=bi1.noc_from_dev_ctl;
	from.noc_from_dev_data=bi1.noc_from_dev_data;
	
	//state machine to sample the destination ID
	case (ps_ds) 
	reset_ds: begin
		if (to.noc_to_dev_ctl==0) begin
			ns_ds=devsel_ds;
			dest_id_d=to.noc_to_dev_data;
		end
		else cmd_d=to.noc_to_dev_data;//assign command byte into address len, Data len and cmd
	end
	devsel_ds: begin
		//next state logic
		if (to.noc_to_dev_ctl) begin
			ns_ds=reset_ds;
			cmd_d=to.noc_to_dev_data;
		end
	end
	remain_ds:begin
		;
	end
	
	default: begin
		;
	end
	endcase
	
	//this sm gives values to selected device and NOP to others
	case (ps_dr)
	reset_dr:begin
		//if (ns_ds==devsel_ds)
			ns_dr=devsel_dr;
	end
	devsel_dr:begin
		//default all to Nops
		bi1.noc_to_dev_ctl=1;
		bi1.noc_to_dev_data=0;
		bi2.noc_to_dev_ctl=1;
		bi2.noc_to_dev_data=0;
		
		//give values to the selected dev
		case(dest_id)
		8'h40:begin
			bi1.noc_to_dev_ctl=delayctl1;
			bi1.noc_to_dev_data=delay1;
		end
		8'h41:begin
			bi2.noc_to_dev_ctl=to.noc_to_dev_ctl;
			bi2.noc_to_dev_data=to.noc_to_dev_data;
		end
		default :;
		endcase
		
		if (to.noc_to_dev_ctl)
			ns_dr=reset_dr;
	end
	default:;
	endcase

end


always @ (posedge to.clk or to.reset) begin
	if (to.reset) begin
		ps_ds<= reset_ds;
		cmd<=0;
		dest_id<=0;
		ps_dr<=reset_dr;
		delay<=0;
		delay1<=0;
		delayctl<=0;
		delayctl1<=0;
	end
	else begin
		ps_ds<= #1 ns_ds;
		cmd<= #1 cmd_d;
		dest_id<= #1 dest_id_d;
		ps_dr<= #1 ns_dr;	
		delay<= #1 delay_d;
		delay1<= #1 delay1_d;
		delayctl<= #1 delayctl_d;
		delayctl1<= #1 delayctl1_d;
	end
end


endmodule
