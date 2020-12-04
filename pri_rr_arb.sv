module arb (
	input clk,rst,
	input [3:0]req,
	output reg [3:0] gnt
);

reg [3:0] gnt_d;
reg [7:0] pri;
reg [3:0] pri_rot;
reg [1:0] prev_win,prev_win_d,winner, winner_act;

reg request;


always @ (*)begin
	gnt_d=gnt;
	prev_win_d=prev_win;
	pri={req,4'h0};
	pri>>=prev_win;
	pri_rot=pri[3:0]|pri[7:4];
	
	request=pri_rot!=0;
	winner=0;
	case (1'b1)
		pri_rot[0]: winner=0;
		pri_rot[1]: winner=1;
		pri_rot[2]: winner=2;
		pri_rot[3]: winner=3;
	endcase
	winner_act=winner+prev_win;
	
	if (request) begin
		gnt_d=1<<winner_act;
		prev_win_d=winner_act+1;
	end
	
	//modify to give 0 grant if no req
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
