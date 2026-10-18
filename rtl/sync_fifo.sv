module sync_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16 //must be a power of 2
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
logic[$clog2(DEPTH):0] wr_pointer;
logic[$clog2(DEPTH):0] rd_pointer;

logic write_accepted;
logic read_accepted;

assign empty = (wr_pointer == rd_pointer);
assign full = (wr_pointer[$clog2(DEPTH)-1:0] == rd_pointer[$clog2(DEPTH)-1:0]) && (wr_pointer[$clog2(DEPTH)] != rd_pointer[$clog2(DEPTH)]);

assign write_accepted = (wr_en && ~full);
assign read_accepted = (rd_en && ~empty);

always_ff @(posedge clk) begin
    if (~rst_n) begin
        wr_pointer <= '0;
        rd_pointer <= '0;
        rd_data <= '0;
    end
    else begin
        if (write_accepted) begin
            fifo_mem[wr_pointer[$clog2(DEPTH)-1:0]] <= wr_data;
            wr_pointer <= wr_pointer + 1;
        end

        if (read_accepted) begin
            rd_data <= fifo_mem[rd_pointer[$clog2(DEPTH)-1:0]];
            rd_pointer <= rd_pointer + 1;
        end
    end
end

endmodule
