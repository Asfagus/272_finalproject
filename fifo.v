
module fifo (clk, rstp, data_in, writep, readp, 
	 data_out, emptyp, fullp);
	 
parameter	DEPTH = 8,		// 2 bits, e.g. 4 words in the FIFO. 2^8 bits
			bitsize=44,
		MAX_COUNT = (1<<DEPTH);	// topmost address in FIFO.

input		clk;
input		rstp;
input [bitsize-1:0] data_in;
input		readp;
input		writep;
output [bitsize-1:0] data_out;
output		emptyp;
output		fullp;

// Defines sizes in terms of bits.
//
reg 		emptyp;
reg		fullp;

// Registered output.
reg [bitsize-1:0]	data_out;

// Define the FIFO pointers.  A FIFO is essentially a circular queue.
//
reg [(DEPTH-1):0]	tail;
reg [(DEPTH-1):0]	head;

// Define the FIFO counter.  Counts the number of entries in the FIFO which
// is how we figure out things like Empty and Full.
//
reg [DEPTH:0]	count;

// Define our regsiter bank.  This is actually synthesizable!

reg [bitsize-1:0] fifomem[MAX_COUNT:0];

// Dout is registered and gets the value that tail points to RIGHT NOW.
//
integer i;
assign data_out = fifomem[tail];
always @(posedge clk or posedge rstp) begin
   if (rstp == 1) begin
      for(i=0;i<32;i=i+1)begin
	fifomem[i] <= 0;	
      end
   end
   else if (writep == 1'b1 && fullp == 1'b0)
      fifomem[head] <= #1 {data_in};
end 
     
// Update the head register.
//
always @(posedge clk) begin
   if (rstp == 1'b1) begin
      head <= 0;
   end
   else begin
      if (writep == 1'b1 && fullp == 1'b0) begin
         // WRITE
         head <= #1 head + 1;
      end
   end
end

// Update the tail register.
//
always @(posedge clk) begin
   if (rstp == 1'b1) begin
      tail <= 0;
   end
   else begin
      if (readp == 1'b1 && emptyp == 1'b0) begin
         // READ               
         tail <= #1 tail + 1;
      end
   end
end

// Update the count regsiter.
//
always @(posedge clk) begin
   if (rstp == 1'b1) begin
      count <= 0;
   end
   else begin
      case ({readp, writep})
         2'b00: count <= #1 count;
         2'b01: 
            // WRITE
            if (!fullp) 
               count <= #1 count + 1;
         2'b10: 
            // READ
            if (!emptyp)
               count <= #1 count - 1;
         2'b11:
            // Concurrent read and write.. no change in count
            count <= #1 count;
      endcase
   end
end

         
// *** Update the flags
//
// First, update the empty flag.
//
always @(count) begin
   if (count == 0)
     emptyp = 1'b1;
   else
     emptyp = 1'b0;
end


// Update the full flag
//
always @(count) begin
   if (count < MAX_COUNT)
      fullp = 1'b0;
   else
      fullp = 1'b1;
end

endmodule


