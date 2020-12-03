// An arbitration module 
// This one does priority arbitration

typedef struct {
	int balance;
	int amount_to_add;
	reg [1:0] ID;
} ACCOUNT;

typedef struct {
	int winning_amount;
	reg [1:0] ID;
} WINNING;

module arb(input reg clk, input reg reset, input reg [3:0] req,
	output reg[3:0] grant);
reg [3:0] int_grant,int_grant_d;
reg [1:0] aw; // actual winner
WINNING win, w01, w23;
int bala;

ACCOUNT acnt[3:0],acnt_d[3:0];

function WINNING c2(ACCOUNT Aa,reg reqa,ACCOUNT Ab,reg reqb);

	int bala,balb;
	WINNING win,w01,w23;
	bala=(reqa)?Aa.balance:0;
	balb=(reqb)?Ab.balance:0;
	if(bala>balb) begin
		win.winning_amount=bala;
		win.ID=Aa.ID;
	end else begin
		win.winning_amount=balb;
		win.ID=Ab.ID;	
	end
	return (win);
endfunction : c2

function WINNING c3(WINNING Wa,WINNING Wb);
	WINNING win;
	if(Wa.winning_amount>Wb.winning_amount) begin
		win.winning_amount=Wa.winning_amount;
		win.ID=Wa.ID;
	end else begin
		win.winning_amount=Wb.winning_amount;
		win.ID=Wb.ID;	
	end
	return (win);
endfunction : c3


// combinational logic
always @(*) begin
	bala=acnt[0].balance;
	for(int ix=0; ix < 4; ix+=1) acnt_d[ix]=acnt[ix];
	int_grant_d=0;
	aw=0;
	grant=int_grant;
	w01=c2(acnt[1],req[1],acnt[0],req[0]);
	w23=c2(acnt[2],req[2],acnt[3],req[3]);
	win=c3(w01,w23);
	if(win.winning_amount>0) begin
		int_grant_d=1<<win.ID;
		aw=win.ID;
		acnt_d[aw].balance=(acnt[aw].balance <= 1)?1:acnt[aw].balance-1;
	end
end

// ffs
always @(posedge(clk) or posedge(reset)) begin
	if(reset) begin
		int_grant <= 0;
		acnt[0]<= '{100,100,0};
		acnt[1]<= '{50,50,1};
		acnt[2]<= '{50,50,2};
		acnt[3]<= '{50,50,3};
	end else begin
		int_grant <= #1 int_grant_d;
		for(int ix=0; ix < 4; ix+=1) acnt[ix]<= #1 acnt_d[ix];
	end
end	
	
	
endmodule : arb
