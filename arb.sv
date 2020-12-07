//my code
module arb (
	input clk,rst,
	input [3:0]req,
	output reg [3:0] gnt
);

reg [3:0] gnt_d;
reg [7:0] pri;
reg [3:0] pri_rot;
reg [1:0] prev_win,prev_win_d,winner, winner_act;

always @ (*)begin
	gnt_d=gnt;
	prev_win_d=prev_win;
	winner=0;
	pri={req,4'h0}>>prev_win;
	pri_rot=pri[7:4]|pri[3:0];
	
	if(pri_rot[0])
		winner=0;
	else if(pri_rot[1])
	 	winner=1;
	else if (pri_rot[2])
		winner=2;
	else if(pri_rot[3])
		winner=3;
	winner_act=winner+prev_win;
	
	if (pri_rot) begin
		gnt_d=1<<winner_act;
		prev_win_d=winner_act+1;
	end
	//give 0 grant if no req
	if(req==0)
		gnt_d=0;
end


always @ (posedge clk or posedge rst)begin
	if (rst)begin
		gnt<=0;
		prev_win<=0;
	end
	else begin
		gnt<= #1 gnt_d;
		prev_win<= #1 prev_win_d;
	end
end


endmodule
