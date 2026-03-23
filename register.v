module register(input clock,input resetn,
input pkt_valid, input [7:0] data_in,input fifo_full,input rst_int_reg,input detect_add,
input ld_state,input laf_state,input full_state,input lfd_state, output reg parity_done,
output  reg  low_pkt_valid ,output reg err,output reg [7:0] dout);

reg [7:0] header_byte;
reg [7:0] fifo_full_state_byte;
reg [7:0] internal_parity;
reg [7:0] packet_parity_byte;


always@(posedge clock or negedge resetn)
begin
        //parity_done logic
        if(!resetn)
        begin
                parity_done<=1'b0;
                low_pkt_valid<=1'b0;
                err<=1'b0;
                dout<=8'b0;

                header_byte<=8'b0;
                fifo_full_state_byte<=8'b0;
                internal_parity<=8'b0;
                packet_parity_byte<=8'b0;
        end
        else
        begin

        //parity_done logic
        if (detect_add)
                parity_done<=1'b0;
        else if((ld_state && !fifo_full && !pkt_valid) || (laf_state && low_pkt_valid && !parity_done))
                parity_done<=1'b1;
        else
                parity_done<=1'b0;

        //low_pkt_valid logic
        if (rst_int_reg)
                low_pkt_valid<=1'b0;
        else if(ld_state && !pkt_valid)
                low_pkt_valid<=1'b1;
        else
                low_pkt_valid<=1'b0;

        //header_byte
        if (detect_add && pkt_valid)
                header_byte<=data_in;

        //payload byte
        if(ld_state && fifo_full && pkt_valid)
                fifo_full_state_byte<=data_in;

        //parity byte
        if(ld_state && !pkt_valid && !fifo_full)
                packet_parity_byte<=data_in;
        else if(laf_state && low_pkt_valid)
                packet_parity_byte<=data_in;


        //output logic
        if(lfd_state)
                dout<=header_byte;
        else if(ld_state && !fifo_full)
                dout<=data_in;
        else if(laf_state)
                dout<=fifo_full_state_byte;

        //internal parity calculation
        if(detect_add)
                internal_parity<=8'b0;
        else if(lfd_state)
                internal_parity <= header_byte;
        else if (ld_state && pkt_valid && !fifo_full)
                internal_parity <= internal_parity ^ data_in;
        else if (full_state)
                internal_parity <= internal_parity ^ fifo_full_state_byte;

        if (rst_int_reg)
            err <= 1'b0;
        else if (parity_done)
            err <= (internal_parity != packet_parity_byte);

end

end
endmodule