`include "/work/shared/users/ugrad/smt259/research-sp25/mem-double-pumping/double-pump/double_pump_4.v"

module ram_4port #(
    parameter MEMORY_DEPTH = 1024,
    parameter ADDRESS_WIDTH = $clog2(MEMORY_DEPTH),
    parameter DATA_WIDTH = 32
)(
    input logic clk,
    //input logic clk2x,
    input logic reset,
    input logic [ADDRESS_WIDTH-1:0] port0_addr,
    output logic [DATA_WIDTH-1:0] port0_read_data,
    input logic [DATA_WIDTH-1:0] port0_write_data,
    input logic port0_en, 
    input logic port0_we,
    input logic [ADDRESS_WIDTH-1:0] port1_addr,
    output logic [DATA_WIDTH-1:0] port1_read_data,
    input logic [DATA_WIDTH-1:0] port1_write_data,
    input logic port1_en, 
    input logic port1_we,
    input logic [ADDRESS_WIDTH-1:0] port2_addr,
    output logic [DATA_WIDTH-1:0] port2_read_data,
    input logic [DATA_WIDTH-1:0] port2_write_data,
    input logic port2_en, 
    input logic port2_we,
    input logic [ADDRESS_WIDTH-1:0] port3_addr,
    output logic [DATA_WIDTH-1:0] port3_read_data,
    input logic [DATA_WIDTH-1:0] port3_write_data,
    input logic port3_en, 
    input logic port3_we,

    // extra signals for go-done interface, Calyx
    output logic port0_done,
    output logic port1_done,
    output logic port2_done,
    output logic port3_done
);

    logic clk2x;
    always @(posedge clk or negedge clk) begin
        if (reset)
            clk2x <= '0;
        else
            clk2x <= '1;
            #5
            clk2x <= '0;
    end

    localparam DPA_m = 1;
    localparam DPA_p = 1;
    localparam DPA_q = 1;
    localparam DPA_n = 1;
    localparam CorePreRegs = 1;
    localparam CorePostRegs = 1;
    localparam CoreLatency = CorePreRegs + CorePostRegs;

    logic [ADDRESS_WIDTH-1:0] dpa0_addr, dpa1_addr;
    logic [DATA_WIDTH-1:0] dpa0_read_data, dpa1_read_data;
    logic [DATA_WIDTH-1:0] dpa0_write_data, dpa1_write_data;
    logic dpa0_en, dpa1_en;
    logic dpa0_we, dpa1_we;

    // double pump adapter 0
    DoublePumpAdpt #(
        .ADDR_WIDTH(ADDRESS_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .REQ1X_NREGS(DPA_m),
        .REQ2X_NREGS(DPA_p),
        .RESP1X_NREGS(DPA_n),
        .RESP2X_NREGS(DPA_q),
        .CORE_RD_LATENCY(CoreLatency),
        .INITAL_PHASE(1)
    ) dpa0 (
        .clk1x(clk),
        .clk2x(clk2x),
        .reset1x(reset),
        .reset2x(reset),
        .addr(dpa0_addr),
        .data_rd(dpa0_read_data),
        .data_wr(dpa0_write_data),
        .en(dpa0_en),
        .we(dpa0_we),
        .addr_0(port0_addr),
        .data_wr_0(port0_write_data),
        .en_0(port0_en),
        .we_0(port0_we),
        .data_rd_0(port0_read_data),
        .addr_1(port1_addr),
        .data_wr_1(port1_write_data),
        .en_1(port1_en),
        .we_1(port1_we),
        .data_rd_1(port1_read_data)
    );

    // double pump adapter 1
    DoublePumpAdpt #(
        .ADDR_WIDTH(ADDRESS_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .REQ1X_NREGS(DPA_m),
        .REQ2X_NREGS(DPA_p),
        .RESP1X_NREGS(DPA_n),
        .RESP2X_NREGS(DPA_q),
        .CORE_RD_LATENCY(CoreLatency),
        .INITAL_PHASE(1)
    ) dpa1 (
        .clk1x(clk),
        .clk2x(clk2x),
        .reset1x(reset),
        .reset2x(reset),
        .addr(dpa1_addr),
        .data_rd(dpa1_read_data),
        .data_wr(dpa1_write_data),
        .en(dpa1_en),
        .we(dpa1_we),
        .addr_0(port2_addr),
        .data_wr_0(port2_write_data),
        .en_0(port2_en),
        .we_0(port2_we),
        .data_rd_0(port2_read_data),
        .addr_1(port3_addr),
        .data_wr_1(port3_write_data),
        .en_1(port3_en),
        .we_1(port3_we),
        .data_rd_1(port3_read_data)
    );

    // sram core in 2x clock domain
    logic [DATA_WIDTH-1:0] core_ram [0:2**ADDRESS_WIDTH-1];
    logic core_port0_en, core_port0_we;
    logic core_port1_en, core_port1_we;
    logic [ADDRESS_WIDTH-1:0] core_port0_addr, core_port1_addr;
    logic [DATA_WIDTH-1:0] core_port0_d, core_port0_q, core_port1_d, core_port1_q;
    logic [ADDRESS_WIDTH-1:0] core_port0_pre_regs_addr [0:CorePreRegs];
    logic [ADDRESS_WIDTH-1:0] core_port1_pre_regs_addr [0:CorePreRegs];
    logic [DATA_WIDTH-1:0] core_port0_pre_regs_d [0:CorePreRegs];
    logic [DATA_WIDTH-1:0] core_port1_pre_regs_d [0:CorePreRegs];
    logic core_port0_pre_regs_en [0:CorePreRegs];
    logic core_port1_pre_regs_en [0:CorePreRegs];
    logic core_port0_pre_regs_we [0:CorePreRegs];
    logic core_port1_pre_regs_we [0:CorePreRegs];
    logic [DATA_WIDTH-1:0] core_port0_post_regs [0:CorePostRegs];
    logic [DATA_WIDTH-1:0] core_port1_post_regs [0:CorePostRegs];

    genvar g;
    assign core_port0_pre_regs_addr[0] = dpa0_addr;
    assign core_port0_pre_regs_d[0] = dpa0_write_data;
    assign core_port0_pre_regs_en[0] = dpa0_en;
    assign core_port0_pre_regs_we[0] = dpa0_we;
    assign core_port1_pre_regs_addr[0] = dpa1_addr;
    assign core_port1_pre_regs_d[0] = dpa1_write_data;
    assign core_port1_pre_regs_en[0] = dpa1_en;
    assign core_port1_pre_regs_we[0] = dpa1_we;
    generate
        for (g = 0; g < CorePreRegs - 1; g = g + 1) begin : pre_regs
            always @(posedge clk2x) begin
                core_port0_pre_regs_addr[g+1] <= core_port0_pre_regs_addr[g];
                core_port0_pre_regs_d[g+1] <= core_port0_pre_regs_d[g];
                core_port0_pre_regs_en[g+1] <= core_port0_pre_regs_en[g];
                core_port0_pre_regs_we[g+1] <= core_port0_pre_regs_we[g];
                core_port1_pre_regs_addr[g+1] <= core_port1_pre_regs_addr[g];
                core_port1_pre_regs_d[g+1] <= core_port1_pre_regs_d[g];
                core_port1_pre_regs_en[g+1] <= core_port1_pre_regs_en[g];
                core_port1_pre_regs_we[g+1] <= core_port1_pre_regs_we[g];
            end
        end
    endgenerate

    always @(posedge clk2x) begin
        if (core_port0_pre_regs_en[CorePreRegs-1])
            if (core_port0_pre_regs_we[CorePreRegs-1])
                core_ram[core_port0_pre_regs_addr[CorePreRegs-1]] = core_port0_pre_regs_d[CorePreRegs-1];
    end

    always @(posedge clk2x) begin
        if (core_port1_pre_regs_en[CorePreRegs-1])
            if (core_port1_pre_regs_we[CorePreRegs-1])
                core_ram[core_port1_pre_regs_addr[CorePreRegs-1]] = core_port1_pre_regs_d[CorePreRegs-1];
    end

    always @(posedge clk2x) begin
        if (core_port0_pre_regs_en[CorePreRegs-1])
            core_port0_post_regs[0] <= core_ram[core_port0_pre_regs_addr[CorePreRegs-1]];
    end

    always @(posedge clk2x) begin
        if (core_port1_pre_regs_en[CorePreRegs-1])
            core_port1_post_regs[0] <= core_ram[core_port1_pre_regs_addr[CorePreRegs-1]];
    end

    generate
        for (g = 0; g < CorePostRegs - 1; g = g + 1) begin : post_regs
            always @(posedge clk2x) begin
                core_port0_post_regs[g+1] <= core_port0_post_regs[g];
                core_port1_post_regs[g+1] <= core_port1_post_regs[g];
            end
        end
    endgenerate

    assign dpa0_read_data = core_port0_post_regs[CorePostRegs-1];
    assign dpa1_read_data = core_port1_post_regs[CorePostRegs-1];


    // Done logic
    always_ff @(posedge clk) begin
        if (reset) begin
            port0_done <= '0;
            port1_done <= '0;
            port2_done <= '0;
            port3_done <= '0;
        end else begin
            if (port0_en)
                port0_done <= '1;
            else
                port0_done <= '0;

            if (port1_en)
                port1_done <= '1;
            else
                port1_done <= '0;

            if (port2_en)
                port2_done <= '1;
            else
                port2_done <= '0;

            if (port3_en)
                port3_done <= '1;
            else
                port3_done <= '0;
        end
    end
endmodule

