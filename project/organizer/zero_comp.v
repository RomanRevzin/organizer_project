module zero_comp
(
	input[31:0] in,
	output out
);

assign out = !(in == 0);
endmodule