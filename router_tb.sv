module router_top_tb;

// Inputs
reg clock;
reg resetn;
reg pkt_valid;
reg [7:0] data_in;
reg read_enb_0;
reg read_enb_1;
reg read_enb_2;

// Outputs
wire [7:0] data_out_0;
wire [7:0] data_out_1;
wire [7:0] data_out_2;
wire vld_out_0;
wire vld_out_1;
wire vld_out_2;
wire err;
wire busy;

// DUT
router_top DUT (
    .clock(clock),
    .resetn(resetn),
    .pkt_valid(pkt_valid),
    .data_in(data_in),
    .read_enb_0(read_enb_0),
    .read_enb_1(read_enb_1),
    .read_enb_2(read_enb_2),
    .data_out_0(data_out_0),
    .data_out_1(data_out_1),
    .data_out_2(data_out_2),
    .vld_out_0(vld_out_0),
    .vld_out_1(vld_out_1),
    .vld_out_2(vld_out_2),
    .err(err),
    .busy(busy)
);


// CLOCK

initial begin
    clock = 0;
    forever #5 clock = ~clock; // 10ns clock
end


// RESET

task reset;
begin
    resetn = 0;
    #20;
    resetn = 1;
end
endtask


// PACKET TASK

task send_packet;
input [1:0] addr;
input [5:0] payload_len;
integer i;
reg [7:0] parity;
begin
    parity = 0;

    // HEADER: {length[7:2], addr[1:0]}
    @(posedge clock);
    pkt_valid = 1;
    data_in = {payload_len, addr};
    parity = parity ^ data_in;

    // PAYLOAD
    for(i = 0; i < payload_len; i = i + 1)
    begin
        @(posedge clock);
        data_in = $random;
        parity = parity ^ data_in;
    end

    // PARITY BYTE
    @(posedge clock);
    pkt_valid = 0;
    data_in = parity;

end
endtask


// READ TASK

task read_fifo0;
begin
    while(vld_out_0)
    begin
        @(posedge clock);
        read_enb_0 = 1;
    end
    read_enb_0 = 0;
end
endtask

task read_fifo1;
begin
    while(vld_out_1)
    begin
        @(posedge clock);
        read_enb_1 = 1;
    end
    read_enb_1 = 0;
end
endtask

task read_fifo2;
begin
    while(vld_out_2)
    begin
        @(posedge clock);
        read_enb_2 = 1;
    end
    read_enb_2 = 0;
end
endtask


// TEST SEQUENCE

initial begin
    // Initialize
    pkt_valid = 0;
    data_in = 0;
    read_enb_0 = 0;
    read_enb_1 = 0;
    read_enb_2 = 0;

    // Reset
    reset;


    // TEST 1: Send packet to FIFO 0

    send_packet(2'b00, 4);
    #50;
    read_fifo0();


    // TEST 2: Send packet to FIFO 1

    send_packet(2'b01, 5);
    #50;
    read_fifo1();


    // TEST 3: Send packet to FIFO 2

    send_packet(2'b10, 3);
    #50;
    read_fifo2();


    // TEST 4: Back-to-back packets

    send_packet(2'b00, 3);
    send_packet(2'b01, 3);
    send_packet(2'b10, 3);

    #100;
    read_fifo0();
    read_fifo1();
    read_fifo2();

    // TEST 5: Parity error (intentional)

    @(posedge clock);
    pkt_valid = 1;
    data_in = {6'd3, 2'b00};

    @(posedge clock);
    data_in = 8'hAA;

    @(posedge clock);
    data_in = 8'hBB;

    @(posedge clock);
    pkt_valid = 0;
    data_in = 8'h00; // WRONG parity

    #50;

    #200;
    $finish;
end

// MONITOR

initial begin
    $monitor("Time=%0t | busy=%b | err=%b | vld0=%b vld1=%b vld2=%b | dout0=%h dout1=%h dout2=%h",
              $time, busy, err, vld_out_0, vld_out_1, vld_out_2,
              data_out_0, data_out_1, data_out_2);
end

endmodule