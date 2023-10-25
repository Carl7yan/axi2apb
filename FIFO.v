module FIFO #(
  parameter FIFO_DEPTH = 16,
  parameter DATA_WIDTH = 32,
  parameter PTR_WIDTH = (FIFO_DEPTH>1) ? $clog2(FIFO_DEPTH) : 1,
  parameter CNT_WIDTH = $clog2(FIFO_DEPTH + 1)
) (
  input clk,
  input rst_n,
  input src_vld,
  output reg src_rdy,
  input [DATA_WIDTH-1:0] src_data,
  output reg dst_vld,
  input dst_rdy,
  output [DATA_WIDTH-1:0] dst_data,
  output reg [CNT_WIDTH] cnt
)

wire wen;
wire ren;
assign wen = src_rdy & src_vld;
assign ren = dst_rdy & dst_vld;

wire [CNT_WIDTH-1:0] cnt_nxt;
always @* begin
  case({wen,ren})
    2'b10: cnt_nxt      = cnt + 1;
    2'b01: cnt_nxt      = cnt - 1;
    default: cnt_nxt    = cnt;
  endcase
end

wire src_dly_nxt;
wire dst_vld_nxt;
assign src_rdy_nxt = (cnt_nxt != FIFO_DEPTH);
assign dst_vld_nxt = (cnt_nxt != 0);

reg  [ADDR_WIDTH-1:0] wptr;
reg  [ADDR_WIDTH-1:0] wptr_nxt;
reg  [ADDR_WIDTH-1:0] rptr;
reg  [ADDR_WIDTH-1:0] rptr_nxt;

assign wptr_nxt = wen ?
                        ((wptr==FIFO_DEPTH-1) ? 0 : (wptr+1))
                      : 
                        wptr;
assign rptr_nxt = ren ?
                        ((rptr==FIFO_DEPTH-1) ? 0 : (rptr+1))
                      :
                        rptr;

reg  [DATA_WIDTH-1:0] fifo_mem [FIFO_DEPTH-1:0];
always@(posedge clk or negedge rst_n) begin
  if(rst_n==0)
    for(i = 0; i < FIFO_DEPTH; i=i+1)
      fifo_mem[i] <= 0;
  else if(wen)
    fifo_mem[wptr] <= src_data;
end
assign dst_data = fifo_mem[rptr];

always @(posedge clk or negedge rst_n)
begin:DFF_PROC
  if (rst_n == 1'b0)
    {wptr, rptr, src_rdy, dst_vld, cnt} <= 0;
  else
    {wptr, rptr, src_rdy, dst_vld, cnt} <= {wptr_nxt, rptr_nxt, src_rdy_nxt, dst_vld_nxt, cnt_nxt};
end

endmodule