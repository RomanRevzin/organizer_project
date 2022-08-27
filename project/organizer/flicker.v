module flicker
 (
 ena,
 clk, 
 out
    );
 input ena;
 input clk;
 output out;
 wire tmp_out;
 reg[27:0] tmp;
 
 always @(posedge clk)
 begin
	if(ena == 1)
	begin
		if(tmp == 25000000)
		begin
			tmp_out <= ~tmp_out;
			tmp <= 0;
		end
		else
			tmp <= tmp + 1;
	end
	else
	begin
		tmp <= 0;
		tmp_out <= 0;
	end
			
 end
 
 assign out = tmp_out;
endmodule 