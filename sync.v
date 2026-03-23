module sync(
input detect_add , input write_enb_reg,
input clock ,input resetn,
input [1:0] data_in,
input read_enb_0 ,input read_enb_1 ,input read_enb_2,
input empty_0,input empty_1,input empty_2,
input full_0,input full_1,input full_2,
output vld_out_0,output  vld_out_1,output vld_out_2,
output reg soft_reset_0,output reg soft_reset_1,
output reg soft_reset_2,
output reg fifo_full,
output  [2:0] write_enb
);

reg [1:0] fifo_sel;
reg [4:0] count0;
reg [4:0] count1;
reg [4:0] count2;


//fifo_selection
always@(posedge clock)
begin
        if(!resetn)
                fifo_sel<=0;
        else if (detect_add)
                fifo_sel<=data_in;
end

//fifo full signal
always@(posedge clock)
begin
  if(!resetn)
    fifo_full <= 1'b0;
  else
    begin
        case(fifo_sel)
                2'b00:fifo_full<=full_0;
                2'b01:fifo_full<=full_1;
                2'b10:fifo_full<=full_2;
                default: fifo_full <= 1'b0;
        endcase
    end
end

//fifo_empty logic
assign vld_out_0 = ~empty_0;
assign vld_out_1 = ~empty_1;
assign vld_out_2 = ~empty_2;

//write_enable signal
assign write_enb[0] = write_enb_reg && (fifo_sel == 2'b00);
assign write_enb[1] = write_enb_reg && (fifo_sel == 2'b01);
assign write_enb[2] = write_enb_reg && (fifo_sel == 2'b10);

//fifo 0 soft_reset logic
always@(posedge clock)
begin
        if(!resetn)
        begin
                soft_reset_0<=0;
                count0<=0;
        end
        else if(vld_out_0 && !read_enb_0)
        begin
                if(count0 == 29)
                begin
                        soft_reset_0<=1;
                        count0<=0;
                end
                else
                begin
                        soft_reset_0<=0;
                        count0<=count0+1;
                end
        end
        else
        begin
                soft_reset_0<=0;
                count0<=0;
        end
end

//fifo 1 soft_reset logic
always@(posedge clock)
begin
        if(!resetn)
        begin
                soft_reset_1<=0;
                count1<=0;
        end
        else if (vld_out_1 && !read_enb_1)
        begin
                if(count1==29)
                begin
                        soft_reset_1<=1;
                        count1<=0;
                end
                else
                begin
                        soft_reset_1<=0;
                        count1<=count1+1;
                end
        end
        else
        begin
                soft_reset_1<=0;
                count1<=0;
        end
end

//fifo 2 soft_reset_logic
always@(posedge clock)
begin
        if(!resetn)
        begin
                soft_reset_2<=0;
                count2<=0;
        end
        else if (vld_out_2 && !read_enb_2)
        begin
                if(count2==29)
                begin
                        soft_reset_2<=1;
                        count2<=0;
                end
                else
                begin
                        soft_reset_2<=0;
                        count2<=count2+1;
                end
        end
        else
        begin
                soft_reset_2<=0;
                count2<=0;
        end
end

endmodule
