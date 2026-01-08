`define ITRACE_OFF
`timescale 1ns/1ps
module tb;
  // -------------------------- 1. 时钟/复位（严格匹配CPU顶层） --------------------------
  reg         clock;  // 对应CPU的clock
  reg         reset;  // 对应CPU的reset

  initial begin
    clock  = 1'b0;
    forever #5 clock = ~clock;  // 100MHz时钟（周期10ns）
  end

  initial begin
    reset  = 1'b1;  // 高复位（若CPU是低复位，改为0，#20置1）
    #20    reset  = 1'b0;  // 20ns释放复位
  end

  // -------------------------- 2. 合并内存定义（8位宽，IFU/LSU共享） --------------------------
  localparam MEM_BASE     = 32'h30000000;  // 统一内存基址
  localparam MEM_SIZE_B   = 1024*1024*16;         
  reg [7:0]  mem [0:MEM_SIZE_B-1];         // 8位宽字节数组（物理内存本质）

  // 加载程序+初始化内存（合并为单个数组）
  initial begin
    static integer i;
    // 1. 清零整个内存（8位字节数组）
    for (i = 0; i < MEM_SIZE_B; i = i + 1) begin
      mem[i] = 8'h00;
    end

    // 2. 加载hex文件到内存（按字节加载，适配8位数组）
    // 注意：hex文件需为纯字节流格式（无地址标记，每行2位16进制），若仍为32位字，需拆分字节
    $readmemh("test.hex", mem);

    // // 3. 调试打印：验证内存加载（打印前4字节，对应1个32位指令）
    #1;
    // $display("[MEM] 0x30000000 = 0x%02x", mem[0]);
    // $display("[MEM] 0x30000001 = 0x%02x", mem[1]);
    // $display("[MEM] 0x30000002 = 0x%02x", mem[2]);
    // $display("[MEM] 0x30000003 = 0x%02x", mem[3]);
  end

  // -------------------------- 3. CPU顶层端口连接（严格匹配） --------------------------
  // CPU输出 → TB输入
  wire [31:0] io_ifu_addr;
  wire        io_ifu_reqValid;
  wire        io_lsu_reqValid;
  wire [31:0] io_lsu_addr;
  wire        io_lsu_wen;
  wire [31:0] io_lsu_wdata;
  wire [3:0]  io_lsu_wmask;
  wire [1:0]  io_lsu_size;

  // TB输出 → CPU输入
  reg         io_ifu_respValid;
  reg [31:0]  io_ifu_rdata;
  reg         io_lsu_respValid;
  reg [31:0]  io_lsu_rdata;
  
  // -------------------------- 4. IFU响应逻辑（32位取指，从8位内存拼接） --------------------------
  wire [31:0] addr_ifu;
  assign addr_ifu = io_ifu_addr - MEM_BASE;
  always @(posedge clock) begin
    if (reset) begin
      io_ifu_respValid <= 1'b0;
      io_ifu_rdata     <= 32'b0;
    end else begin
      io_ifu_respValid <= 1'b0;
      // 仅在CPU发起IFU请求时响应（io_ifu_reqValid有效）
      if (io_ifu_reqValid) begin
        // 检查地址是否在合法内存范围（字节编址）
        if ((io_ifu_addr >= MEM_BASE) && (io_ifu_addr < MEM_BASE + MEM_SIZE_B)) begin
          io_ifu_rdata[7:0]   <= mem[addr_ifu];
          io_ifu_rdata[15:8]  <= mem[addr_ifu + 1];
          io_ifu_rdata[23:16] <= mem[addr_ifu + 2];
          io_ifu_rdata[31:24] <= mem[addr_ifu + 3];
          io_ifu_respValid    <= 1'b1;
          // $display("[IFU][%0t] Req: addr=0x%08h → Rsp: data=0x%08h", 
          //          $time, io_ifu_addr, {mem[addr_ifu+3], mem[addr_ifu+2], mem[addr_ifu+1], mem[addr_ifu]});
        end else begin
          io_ifu_rdata     <= 32'hdeadbeef;      // 地址越界返回错误值
          io_ifu_respValid <= 1'b1;
          $display("[IFU][%0t] Req: addr=0x%08h → Out of range", $time, io_ifu_addr);
        end
      end
    end
  end

    // -------------------------- 5. LSU响应逻辑（适配8位内存，支持字节/半字/字操作） --------------------------
wire [31:0] addr_lsu;
assign addr_lsu = {io_lsu_addr[31:2],2'b0} - MEM_BASE;  // 内存访问仍用>>2，串口访问会跳过此逻辑
// 定义串口地址（匹配C代码中的SERIAL_PORT）
localparam SERIAL_PORT = 32'h10000000;

always @(posedge clock) begin
  if (reset) begin
    io_lsu_respValid <= 1'b0;
    io_lsu_rdata     <= 32'b0;
  end else begin
    // 仅在CPU发起LSU请求时响应（io_lsu_reqValid有效）
    if (io_lsu_reqValid) begin
      // 处理串口相关地址
      if (io_lsu_addr == SERIAL_PORT && io_lsu_wen) begin
        // 模拟串口输出字符
        $write("%c", io_lsu_wdata[7:0]);
        // $display("uart out");
        io_lsu_respValid <= 1'b1;  // 串口写操作响应
      end
      // 新增：串口状态寄存器（SERIAL_PORT+5）
      else if (io_lsu_addr == SERIAL_PORT + 32'd5 && !io_lsu_wen) begin
        io_lsu_rdata <= 32'h20202020;   // 返回状态：发送空闲
        io_lsu_respValid <= 1'b1;
        // $display("[UART][%0t] 读取状态寄存器: 0x%08h", $time, 32'h00000020);
      end
      // 其他串口寄存器（简单响应）
      else if (((io_lsu_addr == SERIAL_PORT+32'd3 && io_lsu_wen) || 
               (io_lsu_addr == SERIAL_PORT+32'd1 && io_lsu_wen))) begin
        io_lsu_respValid <= 1'b1;
      end
      // 原有逻辑：普通内存访问（保留>>2的地址计算）
      else if ((io_lsu_addr >= MEM_BASE) && (io_lsu_addr < MEM_BASE + MEM_SIZE_B)) begin
        // 写操作（sb/sh/sw）：按wmask逐字节写入8位内存
        if (io_lsu_wen) begin
          if (io_lsu_wmask[0]) mem[addr_lsu]     <= io_lsu_wdata[7:0];
          if (io_lsu_wmask[1]) mem[addr_lsu + 1] <= io_lsu_wdata[15:8];
          if (io_lsu_wmask[2]) mem[addr_lsu + 2] <= io_lsu_wdata[23:16];
          if (io_lsu_wmask[3]) mem[addr_lsu + 3] <= io_lsu_wdata[31:24];
          // $display("[LSU][%0t] Write: addr=0x%08h wdata=0x%08h wmask=0x%1h size=%02b pc:0x%08h " ,
                  //  $time, io_lsu_addr, io_lsu_wdata, io_lsu_wmask, io_lsu_size , addr_lsu, io_ifu_addr);
          io_lsu_respValid <= 1'b1;  // 写操作响应
        end
        // 读操作（lb/lh/lw/lbu/lhu）：从8位内存拼接数据
        else begin
          // 默认拼接32位（CPU内部LSU根据size做截断/符号扩展）
          io_lsu_rdata[7:0]   <= mem[addr_lsu];
          io_lsu_rdata[15:8]  <= mem[addr_lsu + 1];
          io_lsu_rdata[23:16] <= mem[addr_lsu + 2];
          io_lsu_rdata[31:24] <= mem[addr_lsu + 3];
          io_lsu_respValid    <= 1'b1;
          // $display("[LSU][%0t] Read: addr=0x%08h rdata=0x%08h size=%02b pc:0x%08h ", 
                  //  $time, io_lsu_addr, {mem[addr_lsu+3], mem[addr_lsu+2], mem[addr_lsu+1], mem[addr_lsu]}, io_lsu_size, io_ifu_addr);
        end
      end else begin
          io_lsu_rdata     <= 32'hdeadbeef;  // 地址越界
          io_lsu_respValid <= 1'b1;
          $display("[LSU][%0t] Req: addr=0x%08h → Out of range pc:0x%08h" , $time, io_lsu_addr ,io_ifu_addr);
      end
    end else begin
          io_lsu_respValid <= 1'b0;
    end
  end
end

  // -------------------------- 6. 例化CPU顶层（100%匹配端口） --------------------------
  ysyx_25080202 u_cpu_top (
    .clock          (clock),
    .reset          (reset),
    // IFU接口
    .io_ifu_respValid(io_ifu_respValid),
    .io_ifu_rdata   (io_ifu_rdata),
    .io_ifu_addr    (io_ifu_addr),
    .io_ifu_reqValid(io_ifu_reqValid),
    // LSU接口
    .io_lsu_rdata   (io_lsu_rdata),
    .io_lsu_respValid(io_lsu_respValid),
    .io_lsu_reqValid(io_lsu_reqValid),
    .io_lsu_addr    (io_lsu_addr),
    .io_lsu_wen     (io_lsu_wen),
    .io_lsu_wdata   (io_lsu_wdata),
    .io_lsu_wmask   (io_lsu_wmask),
    .io_lsu_size    (io_lsu_size)
  );
  always @(posedge clock) begin
    if (!reset) begin  
      if (io_ifu_respValid && (io_ifu_rdata == 32'h00100073)) begin
        $display("[TB][%0t] 检测到ebreak指令(0x00100073)，结束仿真", $time);
        #20 $finish;
      end
    end
  end


  // -------------------------- 7. 波形导出（调试用） --------------------------
  initial begin
    // $dumpfile("wave.vcd");
    // $dumpvars(0, tb);                // 导出TB所有信号
    // $dumpvars(1, u_cpu_top);         // 导出CPU顶层所有信号
  end

endmodule