module serial_transmit # (
   parameter baud_rate = 115_200,
   parameter comm_clk_frequency = 100_000_000 )
  (clk, TxD, busy, send, word);
   
   // split 4-byte output into bytes

   wire TxD_start;
   wire TxD_ready;
   
   reg [7:0]  out_byte = 0;
   reg        serial_start = 0;
   reg [3:0]  mux_state = 4'b0000;

   assign TxD_start = serial_start;

   input      clk;
   output     TxD;
   
   input [31:0] word;
   input 	send;
   output 	busy;

   reg [31:0] 	word_copy = 0;
   
   assign busy = (|mux_state);

   always @(posedge clk)
     begin
	// Testing for busy is problematic if we are keeping the
	// module busy all the time :-/ So we need some wait stages
	// between the bytes.

	if (!busy && send)
	  begin
	     mux_state <= 4'b1000;
	     word_copy <= word;
	  end  

	else if (mux_state[3] && ~mux_state[0] && TxD_ready)
	  begin
	     serial_start <= 1;
	     mux_state <= mux_state + 1;

	     out_byte <= word_copy[31:24];
	     word_copy <= (word_copy << 8);
	  end
	
	// wait stages
	else if (mux_state[3] && mux_state[0])
	  begin
	     serial_start <= 0;
	     if (TxD_ready) mux_state <= mux_state + 1;
	  end
     end

   uart_transmitter #(.comm_clk_frequency(comm_clk_frequency), .baud_rate(baud_rate)) utx (.clk(clk), .uart_tx(TxD), .rx_new_byte(TxD_start), .rx_byte(out_byte), .tx_ready(TxD_ready));

endmodule // serial_send
