module sync_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)
(
    input logic clk,
    input logic rst_n,
    input logic wr_en,
    input logic[WIDTH-1:0] wr_data,
    input logic rd_en,

    output logic[WIDTH-1:0] rd_data,
    output logic empty,
    output logic full
);

logic[WIDTH-1:0] fifo_mem [0:DEPTH-1];

//pointers
logic[$clog2(DEPTH)-1:0] wr_pointer;
logic[$clog2(DEPTH)-1:0] rd_pointer;

logic[$clog2(DEPTH):0] counter;

logic write_accepted;
logic read_accepted;

assign empty = (counter == 0);   
assign full = (counter == DEPTH);

assign write_accepted = (wr_en && ~full);
assign read_accepted = (rd_en && ~empty);


always_ff @(posedge clk) begin
    if (~rst_n) begin
        counter <= '0;
        wr_pointer <= '0;
        rd_pointer <= '0;
        rd_data <= '0;
    end
    else begin
        if (write_accepted) begin
            fifo_mem[wr_pointer] <= wr_data;

            if (wr_pointer == (DEPTH-1)) begin
                wr_pointer <= '0;
            end
            else begin
                wr_pointer <= wr_pointer + 1;
            end
        end

        if (read_accepted) begin
            rd_data <= fifo_mem[rd_pointer];

            if (rd_pointer == (DEPTH-1)) begin
                rd_pointer <= '0;
            end
            else begin
                rd_pointer <= rd_pointer + 1;
            end
        end

        if (write_accepted && ~read_accepted) begin
            counter <= counter + 1;
        end
        else if (read_accepted && ~write_accepted) begin
            counter <= counter - 1;
        end
        else begin
            counter <= counter; //this is redundant just to better see how the counter works
        end
    end
end


endmodule