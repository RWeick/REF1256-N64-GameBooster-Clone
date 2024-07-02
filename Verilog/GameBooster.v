module GameBooster

(ad, aleh, alel, button, clk, cold_reset, pic_gp4, pic_gp5, read, remote_d0, remote_d1, remote_d2, remote_d3, remote_data_ready, write, cp, dsab, gameboy_a15, gameboy_cs, pport_cp, read_top, shift_dir, sst, sst_ce, sst_oe);

inout [15:0] ad;
input aleh;
input alel;
input button;
input clk;
input cold_reset;
input pic_gp4;
input pic_gp5;
input read;
input remote_d0;
input remote_d1;
input remote_d2;
input remote_d3;
input remote_data_ready;
input write;
output cp;
output dsab;
output gameboy_a15;
output gameboy_cs;
output pport_cp;
output read_top;
output shift_dir;
output [18:0] sst;
output sst_ce;
output sst_oe;

localparam DATA_START = 3'd0, DATA_END = 3'd1, ONE_LOW_START = 3'd0, ONE_LOW_END = 3'd1, ONE_LOW_RESET = 3'd2, DATA_OUT_START = 3'd0, DATA_OUT_END = 3'd1;

reg ad_out_en = 0;
reg [12:0] addr_increment = 13'b0;
reg ale_out_en = 0;
reg [15:0] data1 = 16'd0;
reg [15:0] data2 = 16'd0;
reg data_out_en = 0;
reg data_out_op = 0;
reg [2:0] data_out_state = DATA_OUT_START;
reg [2:0] data_state = DATA_START;
reg eleven_range_en = 1'b0;
reg first_boot = 1'b1;
reg [31:0] n64_ad_store = 32'b0;
reg [15:0] n64_data_store = 16'b0;
reg one_e_range_en = 1'b0;
reg [2:0] one_low_state = ONE_LOW_END;
reg one_op_complete = 1'b0;
reg one_op_en = 0;
reg press = 0;
reg [15:0] r_ad;
reg [19:0] r_button = 20'hFFFFF;
reg r_cp = 0;
reg r_dsab = 0;
reg r_gb_a15;
reg r_gb_cs;
reg r_pport_cp;
reg r_rdr = 0;
reg r_read_top = 0;
reg r_shift_dir;
reg [18:0] r_sst = 0;
reg r_sst_ce = 1;
reg r_sst_oe = 1;
reg r_read = 1;
reg read_high;
reg read_low;
reg seven_seg_enable = 1'b0;
reg [18:0] sst_address = 0;
reg r_write = 1;
reg write_high;
reg write_low;
reg [2:0] write_stat;

assign ad = (ale_out_en && ad_out_en) ? r_ad : 16'hZ;
assign cp = r_cp;
assign dsab = r_dsab;
assign gameboy_a15 = r_gb_a15;
assign gameboy_cs = r_gb_cs;
assign pport_cp = r_pport_cp;
assign read_top = r_read_top;
assign shift_dir = r_shift_dir;
assign sst = r_sst;
assign sst_ce = r_sst_ce;
assign sst_oe = r_sst_oe;

always @(posedge clk)
begin
	ad_out_en <= 0;
	data_out_en <= 0;
	one_op_complete <= 0;
	one_op_en <= 0;
	press <= 0;
	r_button [19:0] <= {r_button [18:0], button};
	r_gb_a15 <= 1;
   	r_gb_cs <= 1;
	r_pport_cp <= 1'b1;
	r_rdr <= remote_data_ready;
	r_read_top <= read;
	r_shift_dir <= 0;
	r_sst_ce <= 1;
	r_sst_oe <= 1;
	r_read <= read;
	r_write <= write;
	read_high <= read && r_read;
	read_low <= !read && !r_read;
	write_high <= write && r_write;
	write_low <= !write && !r_write;
	write_stat [2:0] <= {write_stat [1:0], write};
		
	if (alel && !aleh)
		begin
		n64_ad_store [15:0] <= ad;
		addr_increment <= 13'b0;
		end

	if (alel && aleh)
		begin
		n64_ad_store [31:16] <= ad;
		one_op_complete <= 1'b1;
		end
	
	if (data_state == DATA_START)
		begin
		if (read_low)
			begin
			sst_address [18:0] <= (n64_ad_store [19:1] + addr_increment);
			ale_out_en <= 1;
			data_state <= DATA_END;
			end
		
		if (write_low)
			begin
			n64_data_store [15:0] <= ad;
			sst_address [18:0] <= (n64_ad_store [19:1] + addr_increment);
			data_state <= DATA_END;
			end
		end
	
	if (data_state == DATA_END)
		begin
		if (read_high && write_high)
			begin
			addr_increment <= (addr_increment + 1'b1);
			ale_out_en <= 0;
			data_state <= DATA_START;
			end
		end
		
	if (one_low_state == ONE_LOW_START)
		begin
		if ((read_low || write_low) && one_op_en)
			begin
			r_sst_ce <= (write_low || read_low) ? 1'b0 : 1'b1;
			one_low_state <= ONE_LOW_END;
			end
		end
			
	if (one_low_state == ONE_LOW_END)
		begin
		r_sst_ce <= (write_low || read_low) ? 1'b0 : 1'b1;
		if (read_high && write_high)
			begin
			one_low_state <= ONE_LOW_RESET;
			end
		end
	
	if (one_low_state == ONE_LOW_RESET)
		begin
		if (one_op_complete == 1'b1)
			begin
			one_low_state <= ONE_LOW_START;
			end
		end
		
	if (data_out_state == DATA_OUT_START)
		begin
		if ((read_low) && data_out_en)
			begin
			data_out_op <= 1;
			ad_out_en <= 1;
			r_ad <= data1;
			end
		if ((read_high) && data_out_op)
			begin
			data_out_state <= DATA_OUT_END;
			data_out_op <= 0;
			end
		end
	
	if (data_out_state == DATA_OUT_END)
		begin
		if ((read_low) && data_out_en)
			begin
			data_out_op <= 1;
			ad_out_en <= 1;
			r_ad <= data2;
			end
		if ((read_high) && data_out_op)
			begin
			data_out_state <= DATA_OUT_START;
			data_out_op <= 0;
			end
		end
		
	if (r_button [19:0] == 20'h0)
		begin
		press <= 1;
		end
		
	if ((n64_ad_store >= 32'h10000000) && (n64_ad_store <= 32'h1000003F) && first_boot)
		begin
		r_sst [18:0] <= sst_address [18:0];
		r_read_top <= 1;
		r_sst_oe <= !read_low;
		r_sst_ce <= (write_low || read_low) ? 1'b0 : 1'b1;
		end

	if ((n64_ad_store >= 32'h10001000) && (n64_ad_store <= 32'h1001FFFF) && first_boot)
		begin
		r_sst [18:0] <= sst_address [18:0];
		r_read_top <= 1;
		r_sst_oe <= !read_low;
		r_sst_ce <= (write_low || read_low) ? 1'b0 : 1'b1;
		end

	if ((n64_ad_store >= 32'h10020000) && (n64_ad_store <= 32'h10100FFF) && first_boot)
		begin
		ad_out_en <= 1;
		r_ad <= 16'b0;
		r_read_top <= 1;
		end
		
	if ((n64_ad_store == 32'h10300261) && first_boot)
		begin
		data_out_en <= 1;
		data1 <= 16'h5445;
		data2 <= 16'h0;
		r_read_top <= 1;
		end
		
	if (n64_ad_store == 32'h10400400)
		begin
		r_sst [18:0] <= 19'b0;
		if (n64_data_store == 16'h11)
			begin
			first_boot <= 1'b0;
			eleven_range_en <= 1'b1;
			end
		if (n64_data_store == 16'h1E)
			begin
			first_boot <= 1'b0;
			one_e_range_en <= 1'b1;
			end
		end

	if ((n64_ad_store [31:20] == 12'h10C) && first_boot)
		begin
		r_sst [18:0] <= sst_address [18:0];
		r_read_top <= 1;
		r_sst_oe <= !read_low;
		r_sst_ce <= (write_low || read_low) ? 1'b0 : 1'b1;
		end

	if ((n64_ad_store == 32'h10400600) && n64_data_store [9] && first_boot)
		begin
		seven_seg_enable <= n64_data_store [10];
		end

	if ((n64_ad_store == 32'h10400800) && seven_seg_enable && first_boot)
		begin
		r_dsab <= n64_data_store [9];
		r_cp <= n64_data_store [10];
		end
	
	if ((n64_ad_store >= 32'h11000000) && (n64_ad_store <= 32'h1100003F) && eleven_range_en)
		begin
		r_sst [18:0] <= sst_address [18:0];
		r_read_top <= 1;
		r_sst_oe <= !read_low;
		r_sst_ce <= (write_low || read_low) ? 1'b0 : 1'b1;
		end
	
	if ((n64_ad_store == 32'h11300220) && eleven_range_en)
		begin
		data_out_en <= 1;
		data1 <= 16'h4441;
		data2 <= 16'h0;
		r_read_top <= 1;
		end
		
	if ((n64_ad_store == 32'h11400000) && eleven_range_en)
		begin
		r_ad [0] <= 1'b0;
		r_ad [1] <= 1'b0;
		r_ad [2] <= 1'b0;
		r_ad [3] <= 1'b0;
		r_ad [4] <= 1'b0;
		r_ad [5] <= 1'b0;
		r_ad [6] <= 1'b0;
		r_ad [7] <= 1'b0;
		r_ad [8] <= 1'b1;
		r_ad [9] <= 1'b0;
		r_ad [10] <= !press;
		r_ad [11] <= 1'b1;
		r_ad [12] <= 1'b0;
		r_ad [13] <= 1'b1;
		r_ad [14] <= 1'b1;
		r_ad [15] <= 1'b1;
		ad_out_en <= 1;
		r_read_top <= 1;
		end
		
	if ((n64_ad_store == 32'h11400600) && n64_data_store [9] && eleven_range_en)
		begin
		seven_seg_enable <= n64_data_store [10];
		end

	if ((n64_ad_store == 32'h11400800) && seven_seg_enable && eleven_range_en)
		begin
		r_dsab <= n64_data_store [8];
		r_cp <= n64_data_store [9];
		end
		
	if ((n64_ad_store >= 32'h11500000) && (n64_ad_store <= 32'h115FFFFF) && eleven_range_en) //Lower to 1100_0000 for GB Hunter
		begin
		r_sst [18:0] <= sst_address [18:0];
		r_pport_cp <= (write_low || read_low) ? 1'b0 : 1'b1;
		end
		
	if ((n64_ad_store [31:20] == 12'h11C) && eleven_range_en)
		begin
		r_sst [18:0] <= sst_address [18:0];
		r_read_top <= 1;
		r_sst_oe <= !read_low;
		r_sst_ce <= !read_low;
		end
		
	if ((n64_ad_store [31:20] == 12'h11E) && eleven_range_en)
		begin
		r_read_top <= 1;
		r_sst [18:0] <= (n64_ad_store [19:1]);
		r_sst_oe <= !read_low;
		one_op_en <= 1;
		end

	if ((n64_ad_store [31:20] == 12'h11F) && eleven_range_en)
		begin
		r_sst [18:0] <= ((n64_ad_store [19:1]) + 1'b1);
		r_read_top <= 1;
		r_sst_oe <= !read_low;
		one_op_en <= 1;
		end

	if ((n64_ad_store == 32'h1E400000) && one_e_range_en)
		begin
		r_ad [0] <= remote_d0;
		r_ad [1] <= remote_d1;
		r_ad [2] <= remote_d2;
		r_ad [3] <= remote_d3;
		r_ad [4] <= (r_rdr && remote_data_ready);
		r_ad [5] <= pic_gp4;
		r_ad [6] <= pic_gp5;
		r_ad [9:7] <= 3'h7;
		r_ad [10] <= !press;
		r_ad [15:11] <= 5'h1F;
		ad_out_en <= 1;
		r_read_top <= 1;
		end

	if (((n64_ad_store == 32'h1E400600) && n64_data_store [9]) && one_e_range_en)
		begin
		seven_seg_enable <= n64_data_store [10];
		first_boot <= 0;
		end

	if (((n64_ad_store == 32'h1E400800) && seven_seg_enable) && one_e_range_en)
		begin
		r_dsab <= n64_data_store [9];
		r_cp <= n64_data_store [10];
		end

	if ((n64_ad_store >= 32'h1E500000) && (n64_ad_store <= 32'h1E5FFFFF) && one_e_range_en)
		begin
		r_pport_cp <= (write_low || read_low) ? 1'b0 : 1'b1;
		end

	if ((n64_ad_store [31:20] == 12'h1EC) && one_e_range_en)
		begin
		r_sst [18:0] <= sst_address [18:0];
		r_read_top <= 1;
		r_sst_oe <= !read_low;
		r_sst_ce <= ((write_stat [2:0] == 0) || read_low) ? 1'b0 : 1'b1;
		end

	if ((n64_ad_store [31:20] == 12'h1EE) && one_e_range_en)
		begin
		r_read_top <= 1;
		r_sst [18:0] <= (n64_ad_store [19:1]);
		r_sst_oe <= !read_low;
		one_op_en <= 1;
		end

	if ((n64_ad_store [31:20] == 12'h1EF) && one_e_range_en)
		begin
		r_sst [18:0] <= ((n64_ad_store [19:1]) + 1'b1);
		r_read_top <= 1;
		r_sst_oe <= !read_low;
		one_op_en <= 1;
		end
		
	if (!r_pport_cp && !r_sst [15]) //For GB Hunter: A15/A16 both low for A15 low. A16 high for CS low only.
		begin
		r_gb_a15 <= 0;
		r_shift_dir <= read_low;
		end
		
	if (!r_pport_cp && !r_sst [16])
		begin
		r_gb_cs <= 0;
		r_shift_dir <= read_low;
		end
end
endmodule