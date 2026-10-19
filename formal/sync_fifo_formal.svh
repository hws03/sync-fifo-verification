//this does the same checks as sync_fifo_sva.sv but in immediate assertions rather than concurrent assertions
//reason for this is that open-source Yosys only understands a small part of SVA, 
//   full concurrent assertions (assert property (@(posedge clk) …), |=>, disable iff, ##1) and bind mostly need the commercial verific front end

//included within sync_fifo.sv rtl with
//  `ifdef FORMAL
//      `include "sync_fifo_formal.svh"
//  `endif

//start in reset
initial assume (!rst_n);


//f_past_valid goes high after the first clock edge so $past() is never used on cycle 0
logic f_past_valid = 1'b0;
always_ff @(posedge clk) begin
    f_past_valid <= 1'b1;
end


//counter
logic[$clog2(DEPTH):0] f_counter;
always @(posedge clk) begin
    if (!rst_n) 
        f_counter <= '0;
    else
        f_counter <= f_counter + (wr_en && !full) - (rd_en && !empty);
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
                t_ahead <= f_counter - (rd_en && !empty); //(rd_accepted) entries in front, minus one if a read leaves this same cycle
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
//same-cycle checks (same as disable iff (!rst_n) ...)
always @(*) begin
    if (rst_n) begin
        //check that full and empty never asserted together
        ast_not_full_and_empty: assert(!(full && empty));

        //counter is never more than depth
        ast_counter_depth: assert(f_counter<=DEPTH);

        //full is high exactly when the counter equals depth
        ast_full_when_counter_eq_depth: assert(full == (f_counter==DEPTH));

        //empty is high exactly when the counter equals 0
        ast_empty_when_counter_is_0: assert(empty == (f_counter==0));

        //rtl counter always matches the checkers test counter
        ast_counter_matches_test: assert(counter==f_counter);

        //data comes out in the order it went in unchanged
        if (t_check) begin
            ast_data_tracker_integrity: assert(rd_data==t_data);
        end

        //helper assertions to rule out impossible states so induction can complete
        //write pointer is always count entries ahead of the read pointer
        ast_ptrs_match_count: assert(wr_pointer == rd_pointer + f_counter[$clog2(DEPTH)-1:0]);

        if (t_busy) begin
            //the tracked entry is still inside the fifo
            ast_tracked_in_fifo: assert(t_ahead < f_counter);

            //the tracked data really is stored in memory, t_ahead places in front of the read pointer
            ast_tracked_data_in_mem: assert(fifo_mem[rd_pointer + t_ahead[$clog2(DEPTH)-1:0]] == t_data);
        end
    end
end


//checks on the cycle after reset (same as !rst_n |=> ...)
always @(posedge clk) begin
    if (f_past_valid && !$past(rst_n)) begin
        //if reset, on the next clock cycle check if empty
        ast_empty_after_rstn: assert(empty==1'b1);

        //after a reset full is low
        ast_rst_full_low: assert(full==0);

        //if reset, read data is cleared to 0 on the next cycle
        ast_rstn_rd_data: assert(rd_data=='0);
    end
end


//next-cycle checks (same as disable iff (!rst_n) ... |=> ...)
always @(posedge clk) begin
    if (f_past_valid && $past(rst_n) && rst_n) begin
        //write when full doesn't move the write pointer (current pointer value is equal to pointer value 1 clock cycle behind)
        if ($past(full && wr_en)) begin
            ast_wr_ptr_full: assert(wr_pointer == $past(wr_pointer));
        end

        //read when empty doesn't move the read pointer (current pointer value is equal to pointer value 1 clock cycle behind)
        if ($past(empty && rd_en)) begin
            ast_rd_ptr_empty: assert(rd_pointer == $past(rd_pointer));
        end

        //when accepted write (write enable high and not full), write pointer goes up by exactly 1 on the next cycle
        if ($past(!full && wr_en)) begin
            ast_wr_ptr_wraccepted: assert(wr_pointer-1'd1 == $past(wr_pointer));
        end

        //when no accepted write, write pointer stays the same
        if ($past(!(!full && wr_en))) begin
            ast_wr_ptr_no_wraccepted: assert(wr_pointer == $past(wr_pointer));
        end

        //when accepted read (read enable high and not empty), read pointer goes up by exactly 1 on the next cycle
        if ($past(!empty && rd_en)) begin
            ast_rd_ptr_rdaccepted: assert(rd_pointer-1'd1 == $past(rd_pointer));
        end

        //when no accepted read, read pointer stays the same
        if ($past(!(!empty && rd_en))) begin
            ast_rd_ptr_no_rdaccepted: assert(rd_pointer == $past(rd_pointer));
        end

        //simultaneous accepted read and write leave the counter unchanged
        if ($past((!full && wr_en) && (!empty && rd_en))) begin
            ast_rd_and_wr_counter: assert(f_counter == $past(f_counter));
        end

        //without an accepted read, read data keeps its value on the next cycle
        if ($past(!(!empty && rd_en))) begin
            ast_no_rd_accepted: assert(rd_data == $past(rd_data));
        end
    end
end




//COVERS
always @(posedge clk) begin
    if (rst_n) begin
        //full is reached at some point
        cov_full_reached: cover(full==1'b1);

        //both read and write requested at the same time while full
        cov_rd_wr_when_full: cover(full==1'b1 && wr_en==1'b1 && rd_en==1'b1);

        //both read and write requested at the same time while empty
        cov_rd_wr_when_empty: cover(empty==1'b1 && wr_en==1'b1 && rd_en==1'b1);

        //write requested when fifo is full
        cov_wr_when_full: cover(full==1'b1 && wr_en==1'b1);

        //read requested when fifo is empty
        cov_rd_when_empty: cover(empty==1'b1 && rd_en==1'b1);
    end

    //pointer wraps (same as ... ##1 ...)
    if (f_past_valid && $past(rst_n) && rst_n) begin
        //write pointer wraps from DEPTH-1 back to 0
        cov_wr_ptr_wrap: cover($past(wr_pointer)==DEPTH-1 && wr_pointer=='0);

        //read pointer wraps from DEPTH-1 back to 0
        cov_rd_ptr_wrap: cover($past(rd_pointer)==DEPTH-1 && rd_pointer=='0);
    end
end

