module control(input clock,input resetn,input pkt_valid,
        input parity_done,input [1:0] data_in,
        input soft_reset_0,input soft_reset_1,input soft_reset_2,
        input fifo_full,input low_pkt_valid,input fifo_empty_0,input fifo_empty_1,input fifo_empty_2,
        output reg busy,output reg detect_add , output reg ld_state,output reg full_state ,
        output reg write_enb_reg , output reg rst_int_reg ,output reg lfd_state,output reg laf_state);

parameter DECODE_ADDRESS = 3'b000,
        LOAD_FIRST_DATA = 3'b001,
        LOAD_DATA = 3'b010,
        WAIT_TILL_EMPTY = 3'b011,
        LOAD_PARITY = 3'b100,
        FIFO_FULL_STATE = 3'b101,
        LOAD_AFTER_FULL = 3'b110,
        CHECK_PARITY_ERROR = 3'b111;
reg [2:0] state , next_state;
reg [1:0] addr;

//present state logic
always@(posedge clock or negedge resetn)
begin
        if (!resetn)
        begin
                state<=DECODE_ADDRESS;
                addr <= 0;
        end

        else
        begin
                state<=next_state;
                if(detect_add)
                        addr<=data_in;
        end
end

//next_state and output logic
always@(*)
begin
        next_state = state;
        detect_add = 0;
        ld_state = 0;
        lfd_state = 0 ;
        laf_state = 0 ;
        full_state = 0 ;

        write_enb_reg = 0 ;
        rst_int_reg = 0 ;
        busy = 0 ;

        if((soft_reset_0 && addr == 2'b00)
        || (soft_reset_1 && addr ==2'b01)
        || (soft_reset_2 && addr ==2'b10))
        next_state = DECODE_ADDRESS;
        else
        begin
        case(state)
                DECODE_ADDRESS:
                begin
                        detect_add = 1'b1;
                        busy = 1'b0;
                        

                        if((pkt_valid && (data_in==2'b00) && fifo_empty_0)
                                || (pkt_valid && (data_in==2'b01) && fifo_empty_1)
                                || (pkt_valid && (data_in==2'b10)&& fifo_empty_2))

                                next_state = LOAD_FIRST_DATA;

                        else if ((pkt_valid && (data_in==2'b00) && !fifo_empty_0)
                                || (pkt_valid && (data_in==2'b01)&& !fifo_empty_1)
                                || (pkt_valid && (data_in == 2'b10) && !fifo_empty_2))

                                next_state = WAIT_TILL_EMPTY;
                        else
                                next_state = DECODE_ADDRESS;
                end

                LOAD_FIRST_DATA:
                begin
                        lfd_state=1'b1;
                        busy = 1'b1;
                        next_state = LOAD_DATA;
                end

                LOAD_DATA:
                begin
                        ld_state = 1'b1;
                        busy = 1'b1;
                        write_enb_reg = 1'b1;
                        if(fifo_full)
                                next_state = FIFO_FULL_STATE;
                        else if(!pkt_valid)
                                next_state = LOAD_PARITY;
                        else
                                next_state = LOAD_DATA;
                end

                LOAD_PARITY:
                begin
                        busy = 1'b1;
                        write_enb_reg = 1'b1;
                        next_state = CHECK_PARITY_ERROR;
                end

                FIFO_FULL_STATE:
                begin
                        busy = 1'b1;
                        write_enb_reg=1'b0;
                        full_state=1'b1;
                        if(fifo_full)
                                next_state = FIFO_FULL_STATE;
                        else
                                next_state = LOAD_AFTER_FULL;
                end

                LOAD_AFTER_FULL:
                begin
                        laf_state = 1'b1;
                        busy = 1'b1;
                        write_enb_reg = 1'b1;
                        if(!parity_done && !low_pkt_valid)
                                next_state = LOAD_DATA;
                        else if (!parity_done && low_pkt_valid)
                                next_state = LOAD_PARITY;
                        else if (parity_done)
                                next_state = DECODE_ADDRESS;
                        else
                                next_state = LOAD_AFTER_FULL;
                    
                end

                WAIT_TILL_EMPTY:
                begin
                        busy= 1'b1;
                        write_enb_reg = 1'b0;
                        if((fifo_empty_0 && (addr ==2'b00))
                        ||(fifo_empty_1 && (addr ==2'b01))
                ||(fifo_empty_2 && (addr == 2'b10)))

                next_state = LOAD_FIRST_DATA;

                else
                        next_state = WAIT_TILL_EMPTY;

                end

                CHECK_PARITY_ERROR:
                begin
                        rst_int_reg = 1'b1;
                        busy = 1'b1;
                        next_state = DECODE_ADDRESS;
                end

                default: begin
                  next_state = DECODE_ADDRESS;
                  busy = (state != DECODE_ADDRESS);	
                end
        endcase
end
end


endmodule