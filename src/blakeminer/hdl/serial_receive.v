module serial_receive # (
    parameter baud_rate = 115_200,
    parameter comm_clk_frequency = 100_000_000 )
    ( clk, RxD, data1, data2, target, rx_done );
    input      clk;
    input      RxD;
   
   wire       RxD_data_ready;
   wire [7:0] RxD_data;


   `ifdef CONFIG_SERIAL_TIMEOUT
	parameter SERIAL_TIMEOUT = `CONFIG_SERIAL_TIMEOUT;
   `else
        // Timeout after 8 million clock at 100Mhz is 80ms, which should be
        // OK for all sensible clock speeds eg 20MHz is 400ms, 200MHz is 40ms
	parameter SERIAL_TIMEOUT = 24'h800000;
   `endif

   uart_receiver #(.comm_clk_frequency(comm_clk_frequency), .baud_rate(baud_rate)) urx (.clk(clk), .uart_rx(RxD), .tx_new_byte(RxD_data_ready), .tx_byte(RxD_data));
      
   output [255:0] data1;	// midstate
   output [127:0] data2;
   output [31:0] target;

   output reg rx_done = 1'b0;
   
   // 80 bytes data (including nonce) + 4 bytes target = 84 bytes / 672 bits
   
   reg [415:0] input_buffer = 0;
   reg [415:0] input_copy = 0;
   reg [6:0]   demux_state = 7'b0000000;
   reg [23:0]  timer = 0;

   // ltcminer.py sends target first then data
`ifdef SIM	// Sane data for simulation - NB disable if simulating serial data loading
   assign target = input_copy[415:384];		// Not needed since no RxD_data_ready strobe to load targetreg
   assign data1 = 256'h3171e6831d493f45254964259bc31bade1b5bb1ae3c327bc54073d19f0ea633b; // midstate
   assign data2 = 128'hffbd9207ffff001e11f35052d554469e;  // NB ffbd9207 is loaded into nonce
   // assign data2 = 128'hffbd9206ffff001e11f35052d554469e;  // Test using prior nonce ffbd9206
`else   
   assign target = input_copy[415:384];
   assign data2 = input_copy[383:256];
   assign data1 = input_copy[255:0];
`endif
   // kramble: changed this as clock crossing requires timing consistency so
   // rx_done is now registered and strobes in sync with the data output
   // hence the following is no longer true...
   // Needed to reset the nonce for new work. There is a 1-cycle delay
   // in the main miner loop, because reset only zeroes nonce_next, so
   // we can do this already at this stage.
   // assign rx_done = (demux_state == 7'd52);
   
   always @(posedge clk)
     case (demux_state)
       7'd52:				// 52 bytes loaded
	 begin
		rx_done <= 1;
	    input_copy <= input_buffer;
	    demux_state <= 0;
	 end
       
       default:
     begin
        rx_done <= 0;
	    if(RxD_data_ready)
	      begin
	         input_buffer <= input_buffer << 8;
             input_buffer[7:0] <= RxD_data;
             demux_state <= demux_state + 1;
	         timer <= 0;
	      end
	      else
	      begin
	         timer <= timer + 1;
	         if (timer == SERIAL_TIMEOUT)
	           demux_state <= 0;
	      end
     end // default
     endcase // case (demux_state)
   
endmodule // serial_receive

