module router_top(
    input clock,
    input resetn,
    input pkt_valid,
    input [7:0] data_in,
    input read_enb_0,
    input read_enb_1,
    input read_enb_2,

    output [7:0] data_out_0,
    output [7:0] data_out_1,
    output [7:0] data_out_2,
    output vld_out_0,
    output vld_out_1,
    output vld_out_2,
    output err,
    output busy
);

// INTERNAL SIGNALS 

wire [7:0] dout;

wire parity_done, low_pkt_valid;
wire detect_add, ld_state, laf_state, lfd_state, full_state;
wire write_enb_reg, rst_int_reg;

wire [2:0] write_enb;

wire fifo_full;

wire soft_reset_0, soft_reset_1, soft_reset_2;

wire empty_0, empty_1, empty_2;
wire full_0, full_1, full_2;
  

// FIFO 0

fifo fifo0(
    .clock(clock),
    .resetn(resetn),
    .write_enb(write_enb[0]),
    .soft_reset(soft_reset_0),
    .read_enb(read_enb_0),
    .data_in(dout),
    .lfd_state(lfd_state),
    .empty(empty_0),
    .data_out(data_out_0),
    .full(full_0)
);


//FIFO 1 

fifo fifo1(
    .clock(clock),
    .resetn(resetn),
    .write_enb(write_enb[1]),
    .soft_reset(soft_reset_1),
    .read_enb(read_enb_1),
    .data_in(dout),
    .lfd_state(lfd_state),
    .empty(empty_1),
    .data_out(data_out_1),
    .full(full_1)
);


//FIFO 2

fifo fifo2(
    .clock(clock),
    .resetn(resetn),
    .write_enb(write_enb[2]),
    .soft_reset(soft_reset_2),
    .read_enb(read_enb_2),
    .data_in(dout),
    .lfd_state(lfd_state),
    .empty(empty_2),
    .data_out(data_out_2),
    .full(full_2)
);
  
  
//REGISTER 

register reg1(
    .clock(clock),
    .resetn(resetn),
    .pkt_valid(pkt_valid),
    .data_in(data_in),
    .fifo_full(fifo_full),
    .rst_int_reg(rst_int_reg),
    .detect_add(detect_add),
    .ld_state(ld_state),
    .laf_state(laf_state),
    .full_state(full_state),
    .lfd_state(lfd_state),
    .parity_done(parity_done),
    .low_pkt_valid(low_pkt_valid),
    .err(err),
    .dout(dout)
);


// SYNC 

sync sync1(
    .detect_add(detect_add),
    .write_enb_reg(write_enb_reg),
    .clock(clock),
    .resetn(resetn),
    .data_in(data_in[1:0]),

    .read_enb_0(read_enb_0),
    .read_enb_1(read_enb_1),
    .read_enb_2(read_enb_2),

    .empty_0(empty_0),
    .empty_1(empty_1),
    .empty_2(empty_2),

    .full_0(full_0),
    .full_1(full_1),
    .full_2(full_2),

    .vld_out_0(vld_out_0),
    .vld_out_1(vld_out_1),
    .vld_out_2(vld_out_2),

    .soft_reset_0(soft_reset_0),
    .soft_reset_1(soft_reset_1),
    .soft_reset_2(soft_reset_2),

    .fifo_full(fifo_full),
    .write_enb(write_enb)
);


// CONTROL

control ctrl(
    .clock(clock),
    .resetn(resetn),
    .pkt_valid(pkt_valid),
    .parity_done(parity_done),
    .data_in(data_in[1:0]),

    .soft_reset_0(soft_reset_0),
    .soft_reset_1(soft_reset_1),
    .soft_reset_2(soft_reset_2),

    .fifo_full(fifo_full),
    .low_pkt_valid(low_pkt_valid),

    .fifo_empty_0(empty_0),
    .fifo_empty_1(empty_1),
    .fifo_empty_2(empty_2),

    .busy(busy),
    .detect_add(detect_add),
    .ld_state(ld_state),
    .full_state(full_state),
    .write_enb_reg(write_enb_reg),
    .rst_int_reg(rst_int_reg),
    .lfd_state(lfd_state),
    .laf_state(laf_state)
);


endmodule