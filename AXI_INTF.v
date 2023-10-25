module AXI_INTF #(
  parameter             ID_NUM='d4,
  parameter             ADDR_W='d12,        //12位，4KB，一个寄存器32位，共1024个寄存器
  parameter             DATA_W='d32         //每个寄存器大小为12位
) (
  input                 ACLK_i,
  input                 ARESETn_i,
  input [ID_NUM-1:0]    AWID_i,
  input [ADDR_W-1:0]    AWADDR_i,
  input [7:0]           AWLEN_i,
  input [2:0]           AWSIZE_i,
  input [1:0]           AWBURST_i,
  input                 AWVALID_i,
  output                AWREADY_o,
  input [DATA_W-1:0]    WDATA_i,
  input [DATA_w/8-1:0]  WSTRB_i,
  input                 WVALID_i,
  output                WREADY_o,
  output[ID_NUM-1:0]    BID_o,
  output                BVALID_o,
  input                 BREADY_o,
  input                 ARID_i,
  input [ADDR_W-1:0]    ARADDR_i,
  input [7:0]           ARLEN_i,
  input [2:0]           ARSIZE_i,
  input [1:0]           ARBURST_i,
  input                 ARVALID_i,
  output                ARREADY_o,
  output[ID_NUM-1:0]    RID_o,
  output[DATA_W-1:0]    RDATA_o,
  output                RLAST_o,
  output                RVALID_o,
  input                 RREADY_i,
  output                fifo_wvld,
  input                 fifo_wrdy,
  output[ID_NUM+ADDR_W+DATA_W-1:0]    fifo_wpayload
);

localparam FIXED = 2'b00;
localparam INCR = 2'b01;
localparam WRAP = 2'b10;

// aw channel busy flag
reg aw_busy;
// aw channel register
reg [ID_NUM-1:0] awid_i_r;
reg [ADDR_W-1:0] awaddr_i_r;
reg [7:0] awlen_i_r;
reg [2:0] awsize_i_r;
reg [1:0] awburst_i_r;
// aw channel transaction structure
wire [ADDR_W-1:0] aw_Start_Address;
wire [7:0] aw_Number_Bytes;
wire [$clog2(DATA_w/8):0] aw_Data_Bus_Bytes;
wire [ADDR_W-1:0] aw_Aligned_Address;
wire [8:0] aw_Burst_Length;
wire [ADDR_W-1:0] aw_Wrap_Boundary;
wire [ADDR_W-1:0] aw_Lower_Byte_Lane;
wire [ADDR_W-1:0] aw_Upper_Byte_Lane;

reg [ADDR_W-1:0] Address_N;

wire aw_cross_boundary;
wire aw_cross_boundary_after;

reg [8:0] w_Number_cnt;

always@(posedge ACLK_i or negedge ARESETn_i) begin
  if(~ARESETn_i)
    aw_busy <=  0;
  else if(AWVALID_i & AWREADY_o)
    aw_busy <=  1;
end

// output ready
assign AWREADY_o = ~aw_busy;
assign WREADY_o = 
assign ARREADY_o = 

// output valid
assign BVALID_o = (AWVALID_i & AWREADY_o & WVALID_i & WREADY_o & WLAST_i) ? 1 : 0;
assign RVALID_o = (ARVALID_i & ARREADY_i) ? 1 : 0;
always@(posedge ACLK_i or negedge ARESETn_i) begin
  if(~ARESETn_i)
    {BVALID_o, RVALID_o} <= 0;
end

// aw channel register
always@(posedge ACLK_i or negedge ARESETn_i) begin
  if(~ARESETn_i)
    {awid_i_r, awaddr_i_r, awlen_i_r, awsize_i_r, awburst_i_r} <= 0;
  else
    {awid_i_r, awaddr_i_r, awlen_i_r, awsize_i_r, awburst_i_r} <= {AWID_i, AWADDR_i, AWLEN_i, AWSIZE_i, AWBURST_i};
end

// aw channel transaction structure
assign aw_Start_Address = awaddr_i_r;
assign aw_Burst_Length = awlen_i_r + 1;
assign aw_Number_Bytes = 1 << awsize_i_r;  // 2 ^ awsize_i_r
assign aw_Aligned_Address = $floor(aw_Start_Address/aw_Number_Bytes)$ * aw_Number_Bytes;
assign aw_Wrap_Boundary = $floor(aw_Start_Address/(aw_Number_Bytes*aw_Burst_Length))$ * (aw_Number_Bytes * aw_Burst_Length);

// aw channel address calculation
assign aw_cross_boundary = (Address_N == (aw_Wrap_Boundary + (aw_Number_Bytes*aw_Burst_Length))) ? 1 : 0;
assign aw_cross_boundary_after = (Address_N > (aw_Wrap_Boundary + (aw_Number_Bytes*aw_Burst_Length))) ? 1 : 0;
always@* begin
  case(awburst_i_r)
    FIXED:Address_N = aw_Start_Address;
    INCR:begin
      if(w_Number_cnt <= 1)
        Address_N = aw_Start_Address;
      else
        Address_N <= aw_Aligned_Address + (w_Number_cnt-1) * aw_Number_Bytes;
    end
    WRAP:begin
      if(w_Number_cnt <= 1)
        Address_N = aw_Start_Address;
      else
        Address_N <= aw_Aligned_Address + (w_Number_cnt-1) * aw_Number_Bytes; 

      if(aw_cross_boundary)
        Address_N <= aw_Wrap_Boundary;
      else if(aw_cross_boundary_after)
        Address_N <= aw_Start_Address + (w_Number_cnt-1)*aw_Number_Bytes -(aw_Number_Bytes*aw_Burst_Length);
    end
  endcase
end

// w channel data number count
always@(posedge ACLK_i or negedge ARESETn_i) begin
  if(~ARESETn_i)
    w_Number_cnt <= 0;
  else if(w_Number_cnt == awlen_i_r+1)
    w_Number_cnt <= 0;
  else if(WVALID_i & WREADY_o)
    w_Number_cnt <= w_Number_cnt + 1;
  else
    w_Number_cnt <= w_Number_cnt;
end

endmodule