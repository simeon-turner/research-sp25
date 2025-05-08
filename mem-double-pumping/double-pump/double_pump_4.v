`timescale 1ns/1ps

module DoublePumpAdpt #(
    ADDR_WIDTH = 32,
    DATA_WIDTH = 32,
    REQ1X_NREGS = 0,
    REQ2X_NREGS = 0,
    RESP1X_NREGS = 0,
    RESP2X_NREGS = 0,
    CORE_RD_LATENCY = 1,
    INITAL_PHASE = 1'b0
) (
    clk2x, reset2x,
    addr, data_wr, data_rd, en, we,
    clk1x, reset1x,
    addr_0, data_wr_0, data_rd_0, en_0, we_0,
    addr_1, data_wr_1, data_rd_1, en_1, we_1
);

// for the core BRAM running at 2x clock
input wire clk2x, reset2x;
output wire [ADDR_WIDTH-1:0] addr;
output wire [DATA_WIDTH-1:0] data_wr;
input wire [DATA_WIDTH-1:0] data_rd;
output wire en, we;

// for the interfaces running at 1x clock
input wire clk1x, reset1x;
input wire [ADDR_WIDTH-1:0] addr_0, addr_1;
input wire [DATA_WIDTH-1:0] data_wr_0, data_wr_1;
output wire [DATA_WIDTH-1:0] data_rd_0, data_rd_1;
input wire en_0, we_0, en_1, we_1;

// phase T-flip-flop
reg phase;
always @(posedge clk2x) begin
    if (reset2x) phase <= INITAL_PHASE;
    else phase <= ~phase;
end

// request pipeline (interface to Mux CDC)
genvar m;
reg [ADDR_WIDTH-1:0] addr_0_req1x_pipe [0:REQ1X_NREGS];
reg [DATA_WIDTH-1:0] data_wr_0_req1x_pipe [0:REQ1X_NREGS];
reg en_0_req1x_pipe [0:REQ1X_NREGS];
reg we_0_req1x_pipe [0:REQ1X_NREGS];
reg [ADDR_WIDTH-1:0] addr_1_req1x_pipe [0:REQ1X_NREGS];
reg [DATA_WIDTH-1:0] data_wr_1_req1x_pipe [0:REQ1X_NREGS];
reg en_1_req1x_pipe [0:REQ1X_NREGS];
reg we_1_req1x_pipe [0:REQ1X_NREGS];

// request pipeline (Mux CDC to core)
genvar p;
reg [ADDR_WIDTH-1:0] addr_req2x_pipe [0:REQ2X_NREGS];
reg [DATA_WIDTH-1:0] data_wr_req2x_pipe [0:REQ2X_NREGS];
reg en_req2x_pipe [0:REQ2X_NREGS];
reg we_req2x_pipe [0:REQ2X_NREGS];

// start point
always @(*) begin
    addr_0_req1x_pipe[0] = addr_0;
    data_wr_0_req1x_pipe[0] = data_wr_0;
    en_0_req1x_pipe[0] = en_0;
    we_0_req1x_pipe[0] = we_0;
    addr_1_req1x_pipe[0] = addr_1;
    data_wr_1_req1x_pipe[0] = data_wr_1;
    en_1_req1x_pipe[0] = en_1;
    we_1_req1x_pipe[0] = we_1;
end

// pipe REQ1x
generate
    for (m = 0; m < REQ1X_NREGS; m = m + 1) begin : req1x_pipe
        always @(posedge clk1x) begin
            addr_0_req1x_pipe[m+1] <= addr_0_req1x_pipe[m];
            data_wr_0_req1x_pipe[m+1] <= data_wr_0_req1x_pipe[m];
            en_0_req1x_pipe[m+1] <= en_0_req1x_pipe[m];
            we_0_req1x_pipe[m+1] <= we_0_req1x_pipe[m];
            addr_1_req1x_pipe[m+1] <= addr_1_req1x_pipe[m];
            data_wr_1_req1x_pipe[m+1] <= data_wr_1_req1x_pipe[m];
            en_1_req1x_pipe[m+1] <= en_1_req1x_pipe[m];
            we_1_req1x_pipe[m+1] <= we_1_req1x_pipe[m];
        end
    end
endgenerate

// Mux CDC
always @(*) begin
    if (phase) begin
        addr_req2x_pipe[0] = addr_1_req1x_pipe[REQ1X_NREGS];
        data_wr_req2x_pipe[0] = data_wr_1_req1x_pipe[REQ1X_NREGS];
        en_req2x_pipe[0] = en_1_req1x_pipe[REQ1X_NREGS];
        we_req2x_pipe[0] = we_1_req1x_pipe[REQ1X_NREGS];
    end else begin
        addr_req2x_pipe[0] = addr_0_req1x_pipe[REQ1X_NREGS];
        data_wr_req2x_pipe[0] = data_wr_0_req1x_pipe[REQ1X_NREGS];
        en_req2x_pipe[0] = en_0_req1x_pipe[REQ1X_NREGS];
        we_req2x_pipe[0] = we_0_req1x_pipe[REQ1X_NREGS];
    end
end

// pipe REQ2X
generate
    for (p = 0; p < REQ2X_NREGS; p = p + 1) begin : req2x_pipe
        always @(posedge clk2x) begin
            addr_req2x_pipe[p+1] <= addr_req2x_pipe[p];
            data_wr_req2x_pipe[p+1] <= data_wr_req2x_pipe[p];
            en_req2x_pipe[p+1] <= en_req2x_pipe[p];
            we_req2x_pipe[p+1] <= we_req2x_pipe[p];
        end
    end
endgenerate

// connect request pipeline to core
assign addr = addr_req2x_pipe[REQ2X_NREGS];
assign data_wr = data_wr_req2x_pipe[REQ2X_NREGS];
assign en = en_req2x_pipe[REQ2X_NREGS];
assign we = we_req2x_pipe[REQ2X_NREGS];

// response pipeline (core to Demux CDC)
genvar q;
reg [DATA_WIDTH-1:0] data_rd_resp2x_pipe [0:RESP2X_NREGS];
// response pipeline (Demux CDC to interface)
genvar n;
reg [DATA_WIDTH-1:0] data_rd_0_resp1x_pipe [0:RESP1X_NREGS];
reg [DATA_WIDTH-1:0] data_rd_1_resp1x_pipe [0:RESP1X_NREGS];

// start point
always @(*) begin
    data_rd_resp2x_pipe[0] = data_rd;
end

// pipe
generate
    for (q = 0; q < RESP2X_NREGS; q = q + 1) begin : resp2x_pipe
        always @(posedge clk2x) begin
            data_rd_resp2x_pipe[q+1] <= data_rd_resp2x_pipe[q];
        end
    end
endgenerate

// Demux CDC
reg [DATA_WIDTH-1:0] dcdc_intermediate_0, dcdc_intermediate_1;
generate
    if ( (REQ2X_NREGS + CORE_RD_LATENCY + RESP2X_NREGS) % 2 == 0 ) begin // even case
        // port 0
        always @(posedge clk2x) begin
            dcdc_intermediate_0 <= data_rd_resp2x_pipe[RESP2X_NREGS];
        end
        always @(posedge clk1x) begin
            data_rd_0_resp1x_pipe[0] <= dcdc_intermediate_0;
        end
        // port 1
        always @(*) begin
            dcdc_intermediate_1 = data_rd_resp2x_pipe[RESP2X_NREGS];
        end
        always @(posedge clk1x) begin
            data_rd_1_resp1x_pipe[0] <= dcdc_intermediate_1;
        end
    end else begin // odd case
        // port 0
        always @(*) begin
            dcdc_intermediate_0 = data_rd_resp2x_pipe[RESP2X_NREGS];
        end
        always @(posedge clk1x) begin
            data_rd_0_resp1x_pipe[0] <= dcdc_intermediate_0;
        end
        // port 1
        always @(posedge clk2x) begin
            dcdc_intermediate_1 <= data_rd_resp2x_pipe[RESP2X_NREGS];
        end
        always @(*) begin
            if (phase) begin
                data_rd_1_resp1x_pipe[0] = dcdc_intermediate_1;
            end
            else begin
                data_rd_1_resp1x_pipe[0] = data_rd_resp2x_pipe[RESP2X_NREGS];
            end
        end
    end
endgenerate

// pipe
generate
    for (n = 0; n < RESP1X_NREGS; n = n + 1) begin : resp1x_pipe
        always @(posedge clk1x) begin
            data_rd_0_resp1x_pipe[n+1] <= data_rd_0_resp1x_pipe[n];
            data_rd_1_resp1x_pipe[n+1] <= data_rd_1_resp1x_pipe[n];
        end
    end
endgenerate

// connect response pipeline to interface
assign data_rd_0 = data_rd_0_resp1x_pipe[RESP1X_NREGS];
assign data_rd_1 = data_rd_1_resp1x_pipe[RESP1X_NREGS];

endmodule

