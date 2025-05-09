/**
 * A 4 port memory interface
 */

module seq_mem_4port
#(
  parameter WIDTH = 32,
  parameter SIZE = 16,
  parameter IDX_SIZE = 4
) (
  // Common signals
  input  wire logic                clk,
  input  wire logic                clk2x,
  input  wire logic                reset,
  input  wire logic [IDX_SIZE-1:0] port0_addr,
  input  wire logic [IDX_SIZE-1:0] port1_addr,
  input  wire logic [IDX_SIZE-1:0] port2_addr,
  input  wire logic [IDX_SIZE-1:0] port3_addr,

  // General content signals
  input  wire logic                port0_en,
  input  wire logic                port1_en,
  input  wire logic                port2_en,
  input  wire logic                port3_en,
  output      logic                port0_done,
  output      logic                port1_done,
  output      logic                port2_done,
  output      logic                port3_done,

  // Read signals
  output      logic [ WIDTH-1:0] port0_read_data,
  output      logic [ WIDTH-1:0] port1_read_data,
  output      logic [ WIDTH-1:0] port2_read_data,
  output      logic [ WIDTH-1:0] port3_read_data,

  // Write signals
  input  wire logic [ WIDTH-1:0] port0_write_data,
  input  wire logic [ WIDTH-1:0] port1_write_data,
  input  wire logic [ WIDTH-1:0] port2_write_data,
  input  wire logic [ WIDTH-1:0] port3_write_data,
  input  wire logic              port0_we,
  input  wire logic              port1_we,
  input  wire logic              port2_we,
  input  wire logic              port3_we
);

  // Internal memory
  logic [WIDTH-1:0] mem[SIZE-1:0];

  // Registers for general content signals
  logic  content_en[0:3];
  logic  done[0:3];
  assign content_en[0] = port0_en;
  assign content_en[1] = port1_en;
  assign content_en[2] = port2_en;
  assign content_en[3] = port3_en;
  assign port0_done    = done[0];
  assign port1_done    = done[1];
  assign port2_done    = done[2];
  assign port3_done    = done[3];

  // Registers for reading from memory
  logic [IDX_SIZE-1:0] addr[0:3];
  logic [WIDTH-1:0]    read_out[0:3];
  assign addr_buffer1[0] = port0_addr;
  assign addr_buffer1[1] = port1_addr;
  assign addr_buffer1[2] = port2_addr;
  assign addr_buffer1[3] = port3_addr;
  assign port0_read_data = read_out[0];
  assign port1_read_data = read_out[1];
  assign port2_read_data = read_out[2];
  assign port3_read_data = read_out[3];

  // Registers for writing to memory
  logic             write_en[0:3];
  logic [WIDTH-1:0] write_data[0:3];
  assign write_data[0] = port0_write_data;
  assign write_data[1] = port1_write_data;
  assign write_data[2] = port2_write_data;
  assign write_data[3] = port3_write_data;
  assign write_en[0]   = port0_we;
  assign write_en[1]   = port1_we;
  assign write_en[2]   = port2_we;
  assign write_en[3]   = port3_we;

  // Buffer registers for 5 cycle read/write latency
  logic [IDX_SIZE-1:0] addr_buffer1[0:3];
  logic [IDX_SIZE-1:0] addr_buffer2[0:3];
  logic [IDX_SIZE-1:0] addr_buffer3[0:3];
  logic [IDX_SIZE-1:0] addr_buffer4[0:3];
  logic [WIDTH-1:0]    read_buffer1[0:3];
  logic [WIDTH-1:0]    read_buffer2[0:3];
  logic [WIDTH-1:0]    read_buffer3[0:3];
  logic [WIDTH-1:0]    read_buffer4[0:3];
  logic                write_val1[0:3];
  logic                write_val2[0:3];
  logic                write_val3[0:3];
  logic                write_val4[0:3];
  logic [WIDTH-1:0]    write_buffer1[0:3];
  logic [WIDTH-1:0]    write_buffer2[0:3];
  logic [WIDTH-1:0]    write_buffer3[0:3];
  logic [WIDTH-1:0]    write_buffer4[0:3];


  // Address buffer logic
  always_ff @(posedge clk) begin
    for (int i = 0; i < 4; i=i+1) begin
      addr_buffer2[i] <= addr_buffer1[i];
      addr_buffer3[i] <= addr_buffer2[i];
      addr_buffer4[i] <= addr_buffer3[i];
      addr[i]         <= addr_buffer4[i];
    end
  end

  // Read logic
  always_ff @(posedge clk) begin
    for (int i = 0; i < 4; i=i+1) begin
      if (reset) begin
        // Set all buffer regs and read out to zero
        read_buffer1[i] <= '0;
        read_buffer2[i] <= '0;
        read_buffer3[i] <= '0;
        read_buffer4[i] <= '0;
        read_out[i]     <= '0;
      end else begin
        if (content_en[i] && !write_en[i]) begin
          // send read out data from memory
          read_buffer1[i] <= mem[addr_buffer1[i]];
        end else if (content_en[i] && write_en[i]) begin
          // clobber read output when a write is performed
          read_buffer1[i] <= 'x;
        end else begin
          // read out stays the same if nothing else
          read_buffer1[i] <= read_buffer1[i];
        end
        // send data through reg buffers regardless, unless reset is high
        read_buffer2[i] <= read_buffer1[i];
        read_buffer3[i] <= read_buffer2[i];
        read_buffer4[i] <= read_buffer3[i];
        read_out[i]     <= read_buffer4[i];
      end
    end
  end

  // Write logic
  always_ff @(posedge clk) begin
    for (int i = 0; i < 4; i=i+1) begin
      write_buffer1[i] <= write_data[i];
      write_buffer2[i] <= write_buffer1[i];
      write_buffer3[i] <= write_buffer2[i];
      write_buffer4[i] <= write_buffer3[i];
      // our write data is only valid when write_en and content_en are high, and reset is low
      write_val1[i]    <= !reset && content_en[i] && write_en[i];
      write_val2[i]    <= write_val1[i];
      write_val3[i]    <= write_val2[i];
      write_val4[i]    <= write_val3[i];
      if (write_val4[i])
        mem[addr[i]] <= write_buffer4[i];
    end
  end

  // Done signal logic
  always_ff @(posedge clk) begin
    for (int i = 0; i < 4; i=i+1) begin
      if (reset)
        done[i] <= '0;
      else if (content_en[i])
        done[i] <= '1;
      else
        done[i] <= '0;
    end
  end

  // Verilator
  // Check for out of bounds access
  `ifdef VERILATOR
    always_comb begin
      for (int i = 0; i < 4; i=i+1) begin
        if (content_en[i])
          if ({1'b0, addr[i]} >= SIZE[IDX_SIZE:0])
            $error(
              "seq_mem_4_port: Out of bounds access\n",
              "addr[%0d]: %0d\n", i, addr[i],
              "SIZE: %0d", SIZE
            );
      end
    end
  `endif

endmodule

