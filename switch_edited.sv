`include "box.sv"
`include "fifo.v"
`include "pri_rr_arb.sv"
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

//enum for round robin arbiter
enum reg [2:0] {reset_arb,check_arb,checkhp_arb,decide_arb}ps_arb,ns_arb;


//ff to store cmd byte from noc_to_dev_data
reg [7:0] cmd,cmd_d;

//destination ID 40,41,42,43
reg [7:0] dest_id_d,dest_id;

//delay to.noc_to_dev_data two cycles
reg [7:0]delay,delay_d,delay1,delay1_d;

//delay to.noc_to_dev_ctl two cycles
reg delayctl,delayctl_d,delayctl1,delayctl1_d;

//fifo 40 regs
//parameter depth=8,9=9;
reg [9-1:0] din_f40;
wire [9-1:0] dout_f40;
reg wen_f40,ren_f40;
wire empty_f40,full_f40;

//fifo 41 regs
reg [9-1:0] din_f41;
wire [9-1:0] dout_f41;
reg wen_f41,ren_f41;
wire empty_f41,full_f41;

//fifo 42,43 regs
reg [9-1:0] din_f42,din_f43;
wire [9-1:0] dout_f42,dout_f43;
reg wen_f42,ren_f42,wen_f43,ren_f43;
wire empty_f42,full_f42,empty_f43,full_f43;

//variable to tell if there is data in any fifo
reg data_ready;

//req grant for read responses
reg [3:0] req_hp,req_hp_d,grant_hp,grant_hp_d;

//req grant for remaining responses
reg [3:0] req_lp,req_lp_d,grant_lp,grant_lp_d;

//grant for final arb output
reg [3:0] grant_out,grant_out_d;

//regs for checking if read resp exists in device
reg rr40_exists,rr40_exists_d,rr41_exists,rr41_exists_d;
reg rr42_exists,rr42_exists_d,rr43_exists,rr43_exists_d;

//give arbiter slower clk or else it does bad syncing lockup only to one device
reg arb_clk;

//add variables for checking length of the read resp

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
fifo f_40 (to.clk,to.reset,din_f40,wen_f40,ren_f40,dout_f40,empty_f40,full_f40);
fifo f_41 (to.clk,to.reset,din_f41,wen_f41,ren_f41,dout_f41,empty_f41,full_f41);
fifo f_42 (to.clk,to.reset,din_f42,wen_f42,ren_f42,dout_f42,empty_f42,full_f42);
fifo f_43 (to.clk,to.reset,din_f43,wen_f43,ren_f43,dout_f43,empty_f43,full_f43);

//instantiating priority RR arb for High (Read resp) and Low priority (remaining resp) reqs
arb a_hp (arb_clk,to.reset,req_hp,grant_hp);
arb a_lp (arb_clk,to.reset,req_lp,grant_lp);

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
	din_f40=0;
	din_f41=0;
	din_f42=0;
	din_f43=0;
	bi1.noc_to_dev_ctl=0;
	bi1.noc_to_dev_data=0;
	bi2.noc_to_dev_ctl=0;
	bi2.noc_to_dev_data=0;
	bi3.noc_to_dev_ctl=0;
	bi3.noc_to_dev_data=0;
	bi4.noc_to_dev_ctl=0;
	bi4.noc_to_dev_data=0;
	{from.noc_from_dev_ctl,from.noc_from_dev_data}={1,8'h0};
	
	//arb sm and other req grant regs
	ns_arb=ps_arb;
	grant_out_d=grant_out;
	rr40_exists_d=rr40_exists;
	rr41_exists_d=rr41_exists;
	rr42_exists_d=rr42_exists;
	rr43_exists_d=rr43_exists;
	req_lp_d=req_lp;
	req_hp_d=req_hp;
	arb_clk=0;
	
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
			 	
			 	//check if cmd has read resp
				if (din_f40[2:0]==3'b011)	
					rr40_exists_d=1;
			 	
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
			 	
			//check if cmd has read resp
			if (din_f41[2:0]==3'b011)	
				rr41_exists_d=1;
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
			 	
			 //check if cmd has read resp
			if (din_f41[2:0]==3'b011)	
				rr42_exists_d=1;
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
			 
			 //check if cmd has read resp
			if (din_f41[2:0]==3'b011)	
				rr43_exists_d=1;
				
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
		if(!empty_f40 ||!empty_f41||!empty_f42||!empty_f43)
			ns_f40r=read_f40r;
			
	end
	read_f40r:begin
		//round robin response logic
		case (ps_rr)
		reset_rr:begin
			//added PRR arbitration scheme and removed greedy master
			if (grant_out==4'b1000) begin
				ns_rr=d40_rr;
			end
			else if(grant_out==4'b0100) begin
				ns_rr=d41_rr;
			end
			else if (grant_out==4'b0010) begin
				ns_rr=d42_rr;
			end
			else if(grant_out==4'b0001) begin
				ns_rr=d43_rr;
			end
			else ;//$display ("noone was granted");
			
			{from.noc_from_dev_ctl,from.noc_from_dev_data}={1,8'h0};	
		end
		d40_rr:begin
			//this logic empties the fifo fully before going to reset
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
	
	//sm to manage arbitration and select grant_out
	case (ps_arb)
	reset_arb:begin
		//default grant out is 0
		//commenting for now
		//grant_out_d=0;
		
		//if rr exists, then next is check arb or else check lp_arb
			
			ns_arb=check_arb;
	
	end
	check_arb:begin
		//here we check arb for low priority
		
		//in the 4 bit request lines: device 40 is 8, device 41 is 4, device 42 is 2, device 43 is 1
		
		//req lp for dev 40
		if (!empty_f40 && rr40_exists==0) begin
			req_lp_d[3]=1'b1;
		end
		else if (rr40_exists)
			;//$display("read resp arrived for dev 40");
		else ;//$display ("dev 40 fifo empty");
	
		//req lp for dev 41
		if (!empty_f41 && rr41_exists==0) begin
			req_lp_d[2]=1'b1;
		end
		else if (rr41_exists)
			;//$display("read resp arrived for dev 41");
		else ;//$display ("dev 41 fifo empty");
		
		//req lp for dev 42
		if (!empty_f42 && rr42_exists==0) begin
			req_lp_d[1]=1'b1;
		end
		else if (rr42_exists)
			;//$display("read resp arrived for dev 42");
		else ;//$display ("dev 42 fifo empty");
		
		//req lp for dev 43
		if (!empty_f43 && rr43_exists==0) begin
			req_lp_d[0]=1'b1;
		end
		else if (rr43_exists)
			;//$display("read resp arrived for dev 43");
		else ;//$display ("dev 43 fifo empty");
	
		ns_arb=checkhp_arb;
	end
	checkhp_arb:begin
		//checks if read response exists to req high priority grant
		//only works with one read resp at a time
		//check if not greedy
		if (rr40_exists)begin
			req_hp_d[3]=1;
		end
		if (rr41_exists)begin
			req_hp_d[2]=1;
		end
		if (rr42_exists)begin
			req_hp_d[1]=1;
		end
		if (rr43_exists)begin
			req_hp_d[0]=1;
		end
		ns_arb=decide_arb;
	end
	decide_arb:begin
		//decide if lp or hp wins
		ns_arb=reset_arb;

		if (req_hp==0) begin
			grant_out_d=grant_lp;
			//clear specific req signal
			req_lp_d[grant_lp]=0;
		end
		else begin
			grant_out_d=grant_hp;
			//clear req signal 
			
			//clear read resp_exists signal
			//this logic treats read resp exists signals individually, not in a 200 byte set
			
			if (grant_hp==8) begin
				rr40_exists_d=0;
				req_hp_d[3]=0;
			end
			if (grant_hp==4) begin
				rr41_exists_d=0;
				req_hp_d[2]=0;
			end
			if (grant_hp==2) begin
				rr42_exists_d=0;
				req_hp_d[1]=0;
			end
			if (grant_hp==1) begin
				rr43_exists_d=0;
				req_hp_d[0]=0;
			end
		end
		
		arb_clk=!arb_clk;
	end
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
		ps_arb<=reset_arb;
		grant_out<=0;
		rr40_exists<=0;
		rr41_exists<=0;
		rr42_exists<=0;
		rr43_exists<=0;
		req_lp<=0;
		req_hp<=0;
		
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
		ps_arb<= #1 ns_arb;
		grant_out<= #1 grant_out_d;
		rr40_exists<= #1 rr40_exists_d;
		rr41_exists<= #1 rr41_exists_d;
		rr42_exists<= #1 rr42_exists_d;
		rr43_exists<= #1 rr43_exists_d;
		req_lp<= #1 req_lp_d;
		req_hp<= #1 req_hp_d;
	end
end
endmodule

