module sync_fifo_sva #(
	parameter WIDTH = 8,
	parameter DEPTH = 16
)
(
    input logic clk,
    input logic rst_n,
    input logic wr_en,
    input logic[WIDTH-1:0] wr_data,
    input logic rd_en,

    input logic[WIDTH-1:0] rd_data,
    input logic empty,
    input logic full,
    input logic[$clog2(DEPTH)-1:0] wr_pointer, 
    input logic[$clog2(DEPTH)-1:0] rd_pointer,
    input logic[$clog2(DEPTH):0] counter
);

//counter logic within tb
logic[$clog2(DEPTH):0] test_counter;

always_ff @(posedge clk) begin
	if(~rst_n) begin
		test_counter <= '0;
	end 

	else begin
		test_counter <= test_counter + (wr_en && !full) - (rd_en && !empty);
	end
end


//data integrity tracker logic (follow one written entry through the fifo and check it comes out unchanged)
logic t_busy; 
logic[WIDTH-1:0] t_data; 
logic[$clog2(DEPTH):0] t_ahead; 
logic t_check;

always_ff @(posedge clk) begin
	if(~rst_n) begin
		t_busy <= 1'b0;
		t_data <= '0;
		t_ahead <= '0;
		t_check <= 1'b0;
	end 

	else begin
		t_check <= 1'b0;

		if (!t_busy) begin
			if ((wr_en && !full)) begin //wr_accepted
				t_busy <= 1'b1;
				t_data <= wr_data;
				t_ahead <= test_counter - (rd_en && !empty); //(rd_accepted) entries in front, minus one if a read leaves this same cycle
			end
		end

		else if ((rd_en && !empty)) begin //rd_accepted
			if (t_ahead==0) begin
				t_busy <= 1'b0;
				t_check <= 1'b1; //test entry was just read, rd_data shows it next cycle
			end
			else begin
				t_ahead <= t_ahead-1'b1;
			end
		end
	end
end


//ASSERTIONS
//if not reset, check that full and empty never asserted together
ast_not_full_and_empty: assert property(
	@(posedge clk)
	disable iff (!rst_n) !(full && empty)
); 
 
//if reset, on the next clock cycle check if empty
ast_empty_after_rstn: assert property(
	@(posedge clk)
	!rst_n |=> empty
);

//write when full doesn't move the write pointer (current pointer value is equal to pointer value 1 clock cycle behind)
ast_wr_ptr_full: assert property(
	@(posedge clk)
	disable iff (!rst_n) full && wr_en |=> wr_pointer == $past(wr_pointer)
);  

//read when empty doesn’t move the read pointer (current pointer value is equal to pointer value 1 clock cycle behind)
ast_rd_ptr_empty: assert property(
	@(posedge clk)
	disable iff (!rst_n) empty && rd_en |=> rd_pointer == $past(rd_pointer)
);

//when accepted write (write enable high and not full), write pointer goes up by exactly 1 on the next cycle
ast_wr_ptr_wraccepted: assert property(
	@(posedge clk)
	disable iff (!rst_n) !full && wr_en |=> wr_pointer-1'd1 == $past(wr_pointer)
);

//when no accepted write, write pointer stays the same
ast_wr_ptr_no_wraccepted: assert property(
	@(posedge clk)
	disable iff (!rst_n) !(!full && wr_en) |=> wr_pointer == $past(wr_pointer)
);

//when accepted read (read enable high and not empty), read pointer goes up by exactly 1 on the next cycle
ast_rd_ptr_rdaccepted: assert property(
	@(posedge clk)
	disable iff (!rst_n) !empty && rd_en |=> rd_pointer-1'd1 == $past(rd_pointer)
);

//when no accepted read, read pointer stays the same
ast_rd_ptr_no_rdaccepted: assert property(
	@(posedge clk)
	disable iff (!rst_n) !(!empty && rd_en) |=> rd_pointer == $past(rd_pointer)
);

//counter is never more than depth
ast_counter_depth: assert property(
	@(posedge clk)
	disable iff (!rst_n) test_counter <= DEPTH
);

//full is high exactly when the counter equals depth
ast_full_when_counter_eq_depth: assert property(
	@(posedge clk)
	disable iff (!rst_n) full == (test_counter==DEPTH)
);

//empy is high exactly when the counter equals 0
ast_empty_when_counter_is_0: assert property(
	@(posedge clk)
	disable iff (!rst_n) empty == (test_counter==0)
);

//simultaneous accepted read and write leave the counter unchanged
ast_rd_and_wr_counter: assert property(
	@(posedge clk)
	disable iff (!rst_n) (!full && wr_en) && (!empty && rd_en) |=> test_counter == $past(test_counter)
);

//after a reset full is low
ast_rst_full_low: assert property(
	@(posedge clk)
	!rst_n |=> full==0
);

//rtl counter always matches the checkers test counter
ast_counter_matches_test: assert property(
	@(posedge clk)
	disable iff (!rst_n) counter==test_counter
);

//without an accepted read, read data keeps its value on the next cycle
ast_no_rd_accepted: assert property(
	@(posedge clk)
	disable iff (!rst_n) !(!empty && rd_en) |=> rd_data == $past(rd_data)
);

//if reset, read data is cleared to 0 on the next cycle
ast_rstn_rd_data: assert property(
	@(posedge clk)
	!rst_n |=> rd_data=='0
);

//data comes out in the order it went in unchanged
ast_data_tracker_integrity: assert property(
	@(posedge clk)
	disable iff (!rst_n) t_check |-> rd_data==t_data
);



//COVERS
//full is reached at some point
cov_full_reached: cover property(
	@(posedge clk)
	disable iff (!rst_n) full==1'b1
);

//both read and write requested at the same time while full
cov_rd_wr_when_full: cover property(
	@(posedge clk)
	disable iff (!rst_n) full==1'b1 && wr_en==1'b1 && rd_en==1'b1
);

//both read and write requested at the same time while empty
cov_rd_wr_when_empty: cover property(
	@(posedge clk)
	disable iff (!rst_n) empty==1'b1 && wr_en==1'b1 && rd_en==1'b1
);

//write requested when fifo is full
cov_wr_when_full: cover property(
	@(posedge clk)
	disable iff (!rst_n) full==1'b1 && wr_en==1'b1
);

//read requested when fifo is empty
cov_rd_when_empty: cover property(
	@(posedge clk)
	disable iff (!rst_n) empty==1'b1 && rd_en==1'b1
);

//write pointer wraps from DEPTH-1 back to 0
cov_wr_ptr_wrap: cover property(
	@(posedge clk)
	disable iff (!rst_n) wr_pointer==DEPTH-1 ##1 wr_pointer=='0
);

//read pointer wraps from DEPTH-1 back to 0
cov_rd_ptr_wrap: cover property(
	@(posedge clk)
	disable iff (!rst_n) rd_pointer==DEPTH-1 ##1 rd_pointer=='0
);


endmodule


bind sync_fifo sync_fifo_sva #(
	.WIDTH(WIDTH), .DEPTH(DEPTH)
) 
sva_u (.*);
