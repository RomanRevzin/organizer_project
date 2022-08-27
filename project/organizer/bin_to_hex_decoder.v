module bcd_7seg_decoder(input [3:0] bcd, output reg [6:0] seven_seg);

always @(*)
case (bcd)
    4'b0000:seven_seg = 7'b0000001;
    4'b0001:seven_seg = 7'b1001111;
    4'b0010:seven_seg = 7'b0010010;
    4'b0011:seven_seg = 7'b0000110;
    4'b0100:seven_seg = 7'b1001100;
    4'b0101:seven_seg = 7'b0100100;
    4'b0110:seven_seg = 7'b0100000;
    4'b0111:seven_seg = 7'b0001111;
    4'b1000:seven_seg = 7'b0000000;
    4'b1001:seven_seg = 7'b0000100;
endcase
endmodule