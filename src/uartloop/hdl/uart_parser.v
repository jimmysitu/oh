//---------------------------------------------------------------------------------------
// uart parser module  
//
//---------------------------------------------------------------------------------------

module uart_parser(/*AUTOARG*/);
//---------------------------------------------------------------------------------------

// modules inputs and outputs 
input 			clock;			// global clock input 
input 			reset;			// global reset input 
output	[7:0]	tx_data;		// data byte to transmit 
output			new_tx_data;	// asserted to indicate that there is a new data byte for transmission 
input 			tx_busy;		// signs that transmitter is busy 

input	[7:0]	rx_data;		// data byte received 
input 			new_rx_data;	// signs that a new byte was received 

output            valid;    // new work is valid
output  [639:0]   work;     // 80B work data
output  [31:0]    target;   // hash target

input             found;    // found hash < target
input   [31:0]    nonce;    // nonce of current hash

// internal constants 
// receive state machine states 
`define RX_IDL      4'b0000
`define RX_CMD	    4'b0001
`define RX_LEN      4'b0010
`define RX_DAT      4'b0011

// transmit state machine 
`define TX_IDL		4'b0000
`define TX_HDR		4'b0001
`define TX_CMD      4'b0010
`define TX_LEN      4'b0011
`define TX_DAT      4'b0100

// command is indicated by command byte 
`define CMD_WORK		8'h00
`define CMD_LOOP_TEST	8'h01
`define CMD_FOUND	    8'h00
`define CMD_LOOP_ACK	8'h01

/*AUTOWIRE*/
/*AUTOREG*/

// internal wires and registers
reg [3:0] rx_sm;			// rx state machine
reg [3:0] tx_sm;			// tx state machine
reg [7:0] rx_byte_count;	// rx byte counter
reg [7:0] tx_byte_count;	// tx byte counter
reg [7:0] rx_cmd;           // recevied command
reg [7:0] tx_cmd;           // transmit command

reg [7:0] tx_len;           // transmit length

wire rx_last_byte;		    // last byte flag for receive
wire tx_last_byte;          // last byte flag for transmit

reg loop_test;              // internal test command
reg [7:0] loop_data;        // test data

reg s_tx_busy;				// sampled tx_busy for falling edge detection
wire tx_end_p;				// transmission end pulse
reg [31:0] s_nonce;         // sampled nonce

//---------------------------------------------------------------------------------------
// module implementation
// rx state machine
always @ (posedge clock or posedge reset) begin
	if (reset)
		rx_sm <= `RX_IDL;
	else if (new_rx_data) begin
		case (rx_sm)
			`RX_IDL:
				// check if received character is header
				if (rx_data == 8'hAA)
					// an all zeros received byte enters binary mode
					rx_sm <= `RX_CMD;
				else
					// any other character wait to downstream header)
					rx_sm <= `RX_IDL;
			`RX_CMD:
				// check if command is a known command
				if ((rx_data == `CMD_WORK) || (rx_data == `CMD_LOOP_TEST))
					rx_sm <= `RX_LEN;
				else
					// not a known command, continue receiving parameters
					rx_sm <= `RX_IDL;
			`RX_LEN:
			        // wait for length parameter - one byte
					rx_sm <= `RX_DAT;
			`RX_DAT:
				// if this is the last data byte then return to idle
				if (rx_last_byte)
					rx_sm <= `RX_IDL;
			default:
			    // go to idle
				rx_sm <= `RX_IDL;
		endcase
	end
end

// valid flag
always @ (posedge clock or posedge reset) begin
	if (reset)
	    valid <= 1'b0;
	else if (rx_last_byte && new_rx_data && (rx_cmd == `CMD_WORK))
		// read command is started on reception of a read command
		valid <= 1'b1;
	else
		// read command ends on transmission of the last byte read
		valid <= 1'b0;
end

// target and work
always @ (posedge clock or posedge reset) begin
	if (reset)
		{target, work} <= 672'h0;
	else if ((rx_sm == `RX_DAT) && (rx_cmd == `CMD_WORK) && new_rx_data)
        {target, work} <= {rx_data, target[31:0], work[639:8]};
end

// loop test
always @ (posedge clock or posedge reset) begin
    if (reset) begin
        loop_test <= 1'b0;
        loop_data <= 8'h0;
    end else if ((rx_sm == `RX_IDL)) begin
        loop_test <= 1'b0;
        loop_data <= loop_data;
    end else if ((rx_sm == `RX_DAT) && (rx_cmd == `CMD_LOOP_TEST) && new_rx_data) begin
        loop_test <= 1'b1;
        loop_data <= rx_data;
    end
end

// command byte counter is loaded with the length parameter and counts down to zero.
// NOTE: a value of zero for the length parameter indicates a command of 256 bytes.
always @ (posedge clock or posedge reset) begin
	if (reset)
		rx_byte_count <= 8'b0;
	else if ((rx_sm == `RX_LEN) && new_rx_data)
		rx_byte_count <= rx_data;
	else if ((rx_sm == `RX_DAT) && new_rx_data)
		rx_byte_count <= rx_byte_count - 8'h1;
end

// last byte in command flag
assign rx_last_byte = (rx_byte_count == 8'h01) ? 1'b1 : 1'b0;

// receive command
always @ (posedge clock or posedge reset) begin
    if (reset) begin
        rx_cmd <= 8'h00;
	end else if ((rx_sm == `RX_CMD) && new_rx_data) begin
		rx_cmd <= rx_data;
	end
end

// transmit state machine
always @ (posedge clock or posedge reset) begin
	if (reset) begin
		tx_sm <= `TX_IDL;
    end else begin
		case (tx_sm)
			`TX_IDL:
				if (found || loop_test)
					tx_sm <= `TX_HDR;
			`TX_HDR:
				if (~tx_busy)
					tx_sm <= `TX_CMD;
            `TX_CMD:
				if (tx_end_p)
					tx_sm <= `TX_LEN;
			`TX_LEN:
				if (tx_end_p)
					tx_sm <= `TX_DAT;
			`TX_DAT:
				if (tx_last_byte && tx_end_p)
					tx_sm <= `TX_IDL;
			default:
				tx_sm <= `TX_IDL;
        endcase
    end
end

// sampled nonce
always @ (posedge clock or posedge reset) begin
    if(reset)
        s_nonce <= 8'h00;
    else if(found)
        s_nonce <= nonce;
    else if((tx_sm == `TX_DAT) && (tx_cmd == `CMD_FOUND) && tx_end_p)
        s_nonce <= {s_nonce[7:0], s_nonce[31:8]};
end

// transmit command
always @ (posedge clock or posedge reset) begin
    if(reset)
        tx_cmd <= 8'h00;
    else if(found)
        tx_cmd <= `CMD_FOUND;
    else if(loop_test)
        tx_cmd <= `CMD_LOOP_ACK;
end

// sampled tx_busy
always @ (posedge clock or posedge reset) begin
	if (reset)
		s_tx_busy <= 1'b0;
	else
		s_tx_busy <= tx_busy;
end
// tx end pulse
assign tx_end_p = ~tx_busy & s_tx_busy;

// command byte counter is loaded with the length parameter and counts down to zero.
// NOTE: a value of zero for the length parameter indicates a command of 256 bytes.
always @ (posedge clock or posedge reset) begin
	if (reset)
		tx_byte_count <= 8'b0;
	else if ((tx_sm == `TX_LEN) && (tx_cmd == `CMD_FOUND))
		tx_byte_count <= 8'h4;
	else if ((tx_sm == `TX_LEN) && (tx_cmd == `CMD_LOOP_ACK))
		tx_byte_count <= 8'h1;
	else if ((tx_sm == `TX_DAT) && tx_end_p)
		tx_byte_count <= tx_byte_count - 8'h1;
end

// last byte in command flag
assign tx_last_byte = (tx_byte_count == 8'h01) ? 1'b1 : 1'b0;

// tx_data and new_tx_data
always @ (posedge clock or posedge reset) begin
    if (reset) begin
        tx_data <= 8'h00;
        new_tx_data <= 1'b0;
    end else if((tx_sm == `TX_HDR) && ~tx_busy) begin
        tx_data <= 8'h55;
        new_tx_data <= 1'b1;
    end else if((tx_sm == `TX_CMD) && tx_end_p) begin
        tx_data <= tx_cmd;
        new_tx_data <= 1'b1;
    end else if((tx_sm == `TX_LEN) && tx_end_p) begin
        tx_data <= tx_byte_count;
        new_tx_data <= 1'b1;
    end else if((tx_sm == `TX_DAT) && (tx_cmd == `CMD_FOUND) && tx_end_p) begin
        tx_data <= s_nonce[7:0];
        new_tx_data <= 1'b1;
    end else if((tx_sm == `TX_DAT) && (tx_cmd == `CMD_LOOP_ACK) && tx_end_p) begin
        tx_data <= loop_data + 8'h1;
        new_tx_data <= 1'b1;
    end else begin
        tx_data <= 8'h00;
        new_tx_data <= 1'b0;
    end
end

endmodule
//---------------------------------------------------------------------------------------
//						Th.. Th.. Th.. Thats all folks !!!
//---------------------------------------------------------------------------------------
