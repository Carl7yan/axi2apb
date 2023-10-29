module APB_SLAVE #(
  parameter             ADDR_W='d12,
  parameter             DATA_W='d32
) (
  input                 PCLK_i_i,
  input                 PRESETn_i,

  // apb interface inputs
  input                 PSEL_i,
  input                 PENABLE_i,
  input                 PWRITE_i,
  input    [ADDR_W-1:0] PADDR_i,
  input    [DATA_W-1:0] PWDATA_i,
  input  [DATA_W/8-1:0] PSTRB_i,
  input           [2:0] PPROT_i, // apb4, not used now

  // apb interface outputs
  output   [DATA_W-1:0] PRDATA_o,
  output                PREADY_o,
  output reg            PSLVERR_o
);

wire apb_ren;
wire apb_wen;

// apb4 slave intf
assign apb_ren = PSEL_i & PENABLE_i & (~PWRITE_i) & (PREADY_o);
assign apb_wen = PSEL_i & PENABLE_i & PWRITE_i & (PREADY_o);
assign PREADY_o = 1;
assign PSLVERR_o = 0;

// APB_MEM instantiation
APB_MEM #(
  .ADDR_W(ADDR_W),
  .DATA_W(DATA_W)
) u_APB_MEM (
  .PCLK_i(PCLK_i),
  .PRESETn_i(PRESETn_i),
  .strb(PSTRB_i),
  .addr(PADDR_i),
  .ren(apb_ren),
  .wen(apb_wen),
  .wdata(PWDATA_i),
  .rdata(PRDATA_o)
  );
endmodule


module APB_MEM #(
  parameter             ADDR_W='d12,
  parameter             DATA_W='d32
) (
  // global signals
  input                 PCLK_i_i,
  input                 PRESETn_i,
  // mem ports
  input    [ADDR_W-1:0] addr,
  input                 ren,
  input                 wen,
  input    [DATA_W-1:0] wdata,
  input  [DATA_W/8-1:0] strb,
  output reg [DATA_W-1:0] rdata
  );

// mem
localparam MEM_DEPTH = 2**(ADDR_W-2);
reg [DATA_W-1:0] mem [MEM_DEPTH-1:0] ;

integer i;
// sequential write logic
always @(posedge PCLK_i or negedge PRESETn_i) begin
  if (~PRESETn_i) begin
    for (i = 0; i < MEM_DEPTH; i = i + 1) begin
      mem [i] <= {DATA_W{1'b0}};
    end
  end else if (wen) begin
    for (i = 0; i < DATA_W/8; i = i + 1) begin
      if (strb[i] == 1'b1)
        mem [ addr[ADDR_W-1:2] ] [i*8+:8]    <= wdata [i*8+:8];
    end
  end
end

// combinational read logic
always @* begin
  if (ren) begin
    rdata = mem [ addr[ADDR_W-1:2] ];
  end else if (~ren) begin
    rdata = {DATA_W{1'b0}};
  end else begin
    rdata = {DATA_W{1'bx}};
  end
end

endmodule