module fifo(
    input clock, 
    input resetn,
    input write_enb, 
    input soft_reset,
    input read_enb, 
    input [7:0] data_in,
    input lfd_state, 

    output empty,
    output full,
    output reg [7:0] data_out
);

reg [8:0] fifo [15:0];   // 9-bit: {lfd_state, data}
reg [3:0] wptr;
reg [3:0] rptr;

reg [8:0] data;
reg [5:0] count;         // packet length counter
reg [7:0] header;        // store header separately


always @(posedge clock)
begin
    if(!resetn || soft_reset)
        wptr <= 4'd0;

    else if (write_enb && !full)
    begin
        fifo[wptr] <= {lfd_state, data_in};
        wptr <= wptr + 1'b1;

        // store header when lfd_state is high
        if(lfd_state)
            header <= data_in;
    end
end


always @(posedge clock)
begin
    if (!resetn || soft_reset)
    begin
        rptr <= 4'd0;
        data <= 9'd0;
    end
    else if (read_enb && !empty)
    begin
        data <= fifo[rptr];
        rptr <= rptr + 1'b1;
    end
end


always @(posedge clock)
begin
    if(!resetn || soft_reset)
        count <= 6'd0;

    else if (read_enb && !empty)
    begin
        if(data[8])  // header detected
            count <= header[7:2] + 1'b1;
        else if (count != 0)
            count <= count - 1'b1;
    end
end


always @(posedge clock)
begin
    if(!resetn || soft_reset)
        data_out <= 8'd0;

    else if(read_enb && !empty)
        data_out <= data[7:0];
end


assign empty = (wptr == rptr);

// Safe FULL condition for circular FIFO
assign full = ((wptr + 1'b1) == rptr);

endmodule