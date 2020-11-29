`include "box.sv"
`include "fifo.v"

//remove later

module switch (NOCI.TI to,NOCI.FO from);

//Registers

//enum for device select
enum reg [2:0] {reset_ds,devsel_ds}ps_ds,ns_ds;
//enum for driving selected device
enum reg [2:0] {reset_dr,devsel_dr}ps_dr,ns_dr;
//enum for storing data from dev 40 in fifo
enum reg [2:0] {reset_f40,store_f40}ps_f40,ns_f40;
//enum for storing data from dev 41 in fifo
enum reg [2:0] {reset_f41,store_f41}ps_f41,ns_f41;
//enum for storing data from dev 42 in fifo
enum reg [2:0] {reset_f42,store_f42}ps_f42,ns_f42;
//enum for storing data from dev 43 in fifo
enum reg [2:0] {reset_f43,store_f43}ps_f43,ns_f43;

//enum for read data from dev 40 in fifo
enum reg [2:0] {reset_f40r,read_f40r}ps_f40r,ns_f40r;	//remove later

//enum for read data from dev 41 in fifo
enum reg [2:0] {reset_f41r,read_f41r}ps_f41r,ns_f41r;	//remove later

//enum for round robin
enum reg [2:0] {reset_rr,d40_rr,d41_rr,d42_rr,d43_rr}ps_rr,ns_rr;

//ff to store cmd byte from noc_to_dev_data
reg [7:0] cmd,cmd_d;

//destination ID 40,41,42,43
reg [7:0] dest_id_d,dest_id;

//delay to.noc_to_dev_data two cycles
reg [7:0]delay,delay_d,delay1,delay1_d;

//delay to.noc_to_dev_ctl two cycles
reg delayctl,delayctl_d,delayctl1,delayctl1_d;

//fifo 40 regs
parameter depth=8,fifo_bitsize=9;
reg [fifo_bitsize-1:0] din_f40;
wire [fifo_bitsize-1:0] dout_f40;
reg wen_f40,ren_f40;
wire empty_f40,full_f40;

//fifo 41 regs
reg [fifo_bitsize-1:0] din_f41;
wire [fifo_bitsize-1:0] dout_f41;
reg wen_f41,ren_f41;
wire empty_f41,full_f41;

//fifo 42,43 regs
reg [fifo_bitsize-1:0] din_f42,din_f43;
wire [fifo_bitsize-1:0] dout_f42,dout_f43;
reg wen_f42,ren_f42,wen_f43,ren_f43;
wire empty_f42,full_f42,empty_f43,full_f43;

//variable to tell if there is data in any fifo
reg data_ready;

//Instantiations

//selected interface for to 
NOCI sel (to.clk, to.reset);

//box1 device 40 intferace and module instantiation
NOCI bi1 (to.clk, to.reset);
box b1 (bi1.TI,bi1.FO);

//box2 device 41 intferace and module instantiation
NOCI bi2 (to.clk, to.reset);
box b2 (bi2.TI,bi2.FO);

//box3 device 42 intferace and module instantiation
NOCI bi3 (to.clk, to.reset);
box b3 (bi3.TI,bi3.FO);

//box4 device 43 intferace and module instantiation
NOCI bi4 (to.clk, to.reset);
box b4 (bi4.TI,bi4.FO);

//instantiating fifo for storing from data from device 40
fifo #(depth,fifo_bitsize) f_40 (to.clk,to.reset,din_f40,wen_f40,ren_f40,dout_f40,empty_f40,full_f40);
fifo #(depth,fifo_bitsize) f_41 (to.clk,to.reset,din_f41,wen_f41,ren_f41,dout_f41,empty_f41,full_f41);
fifo #(depth,fifo_bitsize) f_42 (to.clk,to.reset,din_f42,wen_f42,ren_f42,dout_f42,empty_f42,full_f42);
fifo #(depth,fifo_bitsize) f_43 (to.clk,to.reset,din_f43,wen_f43,ren_f43,dout_f43,empty_f43,full_f43);


always @ (*)begin
	ns_ds=ps_ds;
	cmd_d=cmd;
	dest_id_d=dest_id;
	ns_dr=ps_dr;
	
	//delay flops
	//delay todev data
	delay_d=delay;
	delay1_d=delay1;
	delayctl_d=delayctl;
	delayctl1_d=delayctl1;
	//delay todevice data
	delay_d=to.noc_to_dev_data;
	delay1_d=delay;
	//delay to ctl
	delayctl_d=to.noc_to_dev_ctl;
	delayctl1_d=delayctl;
	//fifo 40
	ns_f40=ps_f40;
	ns_f40r=ps_f40r;
	wen_f40=0;
	ren_f40=0;
	//fifo 41
	ns_f41=ps_f41;
	ns_f41r=ps_f41r;
	wen_f41=0;
	ren_f41=0;
	data_ready=0;
	ns_rr=ps_rr;
	wen_f42=0;
	ren_f42=0;
	wen_f43=0;
	ren_f43=0;
	ns_f42=ps_f42;
	ns_f43=ps_f43;
	
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
	default: ;
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
		bi3.noc_to_dev_ctl=1;
		bi3.noc_to_dev_data=0;
		bi4.noc_to_dev_ctl=1;
		bi4.noc_to_dev_data=0;
		//if (to.noc_to_dev_ctl) 
		//	ns_dr=reset_dr;
		
		//give values to the selected dev
		case(dest_id)
		8'h40:begin
			bi1.noc_to_dev_ctl=delayctl1;
			bi1.noc_to_dev_data=delay1;
		end
		8'h41:begin
			bi2.noc_to_dev_ctl=delayctl1;
			bi2.noc_to_dev_data=delay1;
		end
		8'h42:begin
			bi3.noc_to_dev_ctl=delayctl1;
			bi3.noc_to_dev_data=delay1;
		end
		8'h43:begin
			bi4.noc_to_dev_ctl=delayctl1;
			bi4.noc_to_dev_data=delay1;
		end
		default :;
		endcase
		
	end
	default:;
	endcase
	
	//sm to store data from device 40 in fifo
	case (ps_f40)
	reset_f40:begin
	//go to ns at start of new packet
		if (bi1.noc_from_dev_ctl && bi1.noc_from_dev_data) begin
			//store cmd byte
			if (!full_f40&&!ren_f40)begin	
				wen_f40=1;
			 	din_f40={bi1.noc_from_dev_ctl,bi1.noc_from_dev_data};
			 	ns_f40=store_f40;
			end
			else $display("tried to write cmd to f40 while full or reading");
		end
	end
	store_f40:begin
		if (!full_f40&&!ren_f40) begin
			 if (!bi1.noc_from_dev_ctl) begin
			 	// data other than NOP
			 	wen_f40=1;
			 	din_f40={bi1.noc_from_dev_ctl,bi1.noc_from_dev_data};
			 end
			 else if (bi1.noc_from_dev_ctl && !bi1.noc_from_dev_data)begin
			 	//Nops
			 	ns_f40=reset_f40;
			 	wen_f40=1;
			 	din_f40={bi1.noc_from_dev_ctl,bi1.noc_from_dev_data};
			 end
			 else if (bi1.noc_from_dev_ctl && bi1.noc_from_dev_data)begin
			 	wen_f40=1;
			 	din_f40={bi1.noc_from_dev_ctl,bi1.noc_from_dev_data};
			 end
			 
		end
		else begin
		 	wen_f40=0;
		 	$display("tried to write rem to f40 while full or reading");
		end	
	end
	default:;
	endcase
	
	//sm to store data from device 41 in fifo
	case (ps_f41)
	reset_f41:begin
	//go to ns at start of new packet
		if (bi2.noc_from_dev_ctl && bi2.noc_from_dev_data) begin
			//store cmd byte
			if (!full_f41&&!ren_f41)begin	
				wen_f41=1;
			 	din_f41={bi2.noc_from_dev_ctl,bi2.noc_from_dev_data};
			 	ns_f41=store_f41;
			end
			else $display("tried to write cmd to f41 while full or reading");
		end
	end
	store_f41:begin
		if (!full_f41&&!ren_f41) begin
			 if (!bi2.noc_from_dev_ctl) begin
			 	// data other than NOP
			 	wen_f41=1;
			 	din_f41={bi2.noc_from_dev_ctl,bi2.noc_from_dev_data};
			 end
			 else if (bi2.noc_from_dev_ctl && !bi2.noc_from_dev_data)begin
			 	//Nops
			 	ns_f41=reset_f41;
			 	wen_f41=1;
			 	din_f41={bi2.noc_from_dev_ctl,bi2.noc_from_dev_data};
			 end
			 else if (bi2.noc_from_dev_ctl && bi2.noc_from_dev_data)begin
			 	wen_f41=1;
			 	din_f41={bi2.noc_from_dev_ctl,bi2.noc_from_dev_data};
			 end
		end
		else begin
		 	wen_f41=0;
		 	$display("tried to write rem to f41 while full or reading");
		end	
	end
	default:;
	endcase
	
	//sm to store data from device 42 in fifo
	case (ps_f42)
	reset_f42:begin
	//go to ns at start of new packet
		if (bi3.noc_from_dev_ctl && bi3.noc_from_dev_data) begin
			//store cmd byte
			if (!full_f42&&!ren_f42)begin	
				wen_f42=1;
			 	din_f42={bi3.noc_from_dev_ctl,bi3.noc_from_dev_data};
			 	ns_f42=store_f42;
			end
			else $display("tried to write cmd to f42 while full or reading");
		end
	end
	store_f42:begin
		if (!full_f42&&!ren_f42) begin
			 if (!bi3.noc_from_dev_ctl) begin
			 	// data other than NOP
			 	wen_f42=1;
			 	din_f42={bi3.noc_from_dev_ctl,bi3.noc_from_dev_data};
			 end
			 else if (bi3.noc_from_dev_ctl && !bi3.noc_from_dev_data)begin
			 	//Nops
			 	ns_f42=reset_f42;
			 	wen_f42=1;
			 	din_f42={bi3.noc_from_dev_ctl,bi3.noc_from_dev_data};
			 end
			 else if (bi3.noc_from_dev_ctl && bi3.noc_from_dev_data)begin
			 	wen_f42=1;
			 	din_f42={bi3.noc_from_dev_ctl,bi3.noc_from_dev_data};
			 end
			 
		end
		else begin
		 	wen_f42=0;
		 	;//$display("tried to write rem to f42 while full or reading");
		end	
	end
	default:;
	endcase
	
	//sm to store data from device 43 in fifo
	case (ps_f43)
	reset_f43:begin
	//go to ns at start of new packet
		if (bi4.noc_from_dev_ctl && bi4.noc_from_dev_data) begin
			//store cmd byte
			if (!full_f43&&!ren_f43)begin	
				wen_f43=1;
			 	din_f43={bi4.noc_from_dev_ctl,bi4.noc_from_dev_data};
			 	ns_f43=store_f43;
			end
			else $display("tried to write cmd to f43 while full or reading");
		end
	end
	store_f43:begin
		if (!full_f43&&!ren_f43) begin
			 if (!bi4.noc_from_dev_ctl) begin
			 	// data other than NOP
			 	wen_f43=1;
			 	din_f43={bi4.noc_from_dev_ctl,bi4.noc_from_dev_data};
			 end
			 else if (bi4.noc_from_dev_ctl && !bi4.noc_from_dev_data)begin
			 	//Nops
			 	ns_f43=reset_f43;
			 	wen_f43=1;
			 	din_f43={bi4.noc_from_dev_ctl,bi4.noc_from_dev_data};
			 end
			 else if (bi4.noc_from_dev_ctl && bi4.noc_from_dev_data)begin
			 	wen_f43=1;
			 	din_f43={bi4.noc_from_dev_ctl,bi4.noc_from_dev_data};
			 end
		end
		else begin
		 	wen_f43=0;
		 	;//$display("tried to write rem to f43 while full or reading");
		end	
	end
	default:;
	endcase
	
	//sm for reading data from fifo dev40 and dev41 and dev42 and dev 43
	case (ps_f40r)
	reset_f40r:begin
		if(!empty_f40 ||!empty_f41)
			ns_f40r=read_f40r;
	end
	read_f40r:begin
		//round robin response logic
		case (ps_rr)
		reset_rr:begin
			//greedy master
			if (!empty_f40&&!wen_f40)
				ns_rr=d40_rr;
			else if(!empty_f41&&!wen_f41)
				ns_rr=d41_rr;
			else if (!empty_f42&&!wen_f42)
				ns_rr=d42_rr;
			else if(!empty_f43&&!wen_f43)
				ns_rr=d43_rr;
			
			{from.noc_from_dev_ctl,from.noc_from_dev_data}={1,8'h0};	
		end
		d40_rr:begin
			if (empty_f40)begin
				ns_rr=reset_rr;
				{from.noc_from_dev_ctl,from.noc_from_dev_data}={1,8'h0};
			end
			else begin
				ren_f40=1;
				{from.noc_from_dev_ctl,from.noc_from_dev_data}=	dout_f40;
			end
		end
		d41_rr:begin
			if (empty_f41) begin
				ns_rr=reset_rr;
				{from.noc_from_dev_ctl,from.noc_from_dev_data}={1,8'h0};
			end
			else begin
				ren_f41=1;
				{from.noc_from_dev_ctl,from.noc_from_dev_data}=	dout_f41;
			end
		end
		d42_rr:begin
			if (empty_f42)begin
				ns_rr=reset_rr;
				{from.noc_from_dev_ctl,from.noc_from_dev_data}={1,8'h0};
			end
			else begin
				ren_f42=1;
				{from.noc_from_dev_ctl,from.noc_from_dev_data}=	dout_f42;
			end
		end
		d43_rr:begin
			if (empty_f43) begin
				ns_rr=reset_rr;
				{from.noc_from_dev_ctl,from.noc_from_dev_data}={1,8'h0};
			end
			else begin
				ren_f43=1;
				{from.noc_from_dev_ctl,from.noc_from_dev_data}=	dout_f43;
			end
		end
		default :;
		endcase
	end
	default :;
	endcase

end

always @ (posedge to.clk or posedge to.reset) begin
	if (to.reset) begin
		ps_ds<= reset_ds;
		cmd<=0;
		dest_id<=0;
		ps_dr<=reset_dr;
		delay<=0;
		delay1<=0;
		delayctl<=0;
		delayctl1<=0;
		ps_f40<=reset_f40;
		ps_f40r<=reset_f40r;
		ps_f41<=reset_f41;
		ps_f41r<=reset_f41r;
		ps_rr<=reset_rr;
		ps_f42<=reset_f42;
		ps_f43<=reset_f43;
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
		ps_f40<= #1 ns_f40;
		ps_f40r<= #1 ns_f40r;
		ps_f41<= #1 ns_f41;
		ps_f41r<= #1 ns_f41r;
		ps_rr<= #1 ns_rr;
		ps_f42<= #1 ns_f42;
		ps_f43<= #1 ns_f43;
	end
end
endmodule
