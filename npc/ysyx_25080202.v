/* verilator lint_off DECLFILENAME */
module ysyx_25080202(
    input clock,
    input reset,
    
    output io_ifu_reqValid,
    output [31:0]io_ifu_addr,
    input io_ifu_respValid,
    input [31:0]io_ifu_rdata,
    output io_lsu_reqValid,
    output [31:0]io_lsu_addr,
    output [1:0]io_lsu_size,
    output io_lsu_wen,
    output [31:0]io_lsu_wdata,
    output [3:0]io_lsu_wmask,
    input io_lsu_respValid,
    input [31:0]io_lsu_rdata
);

    /* verilator lint_off WIDTHTRUNC */
    `ifdef VERILATOR
    // import "DPI-C" function byte unsigned pmem_read_ram(input int unsigned raddr);
    // import "DPI-C" function int pmem_read_rom(input int raddr);
    // export "DPI-C" function trap;
    // function int trap();
    //     return is_ebreak?1:0;
    // endfunction
    import "DPI-C" function void notify_ebreak();
always @(posedge clock) begin
    if (is_ebreak && $time > 0) begin
        notify_ebreak();
    end
end
    
    // export "DPI-C" function get_pc;
    // function int get_pc();
    //     get_pc = pc_data_out;
    // endfunction
    `endif
    wire [31:0]pc_data_in;
    wire [31:0]pc_data_out;
    wire [31:0]decode;
    wire [31:0]snpc;
    wire [31:0]dnpc;
    wire [31:0]dnpc1;
    wire [3:0]raddr1;
    wire [3:0]raddr2;
    wire [31:0]src1;
    wire [31:0]src2;
    wire [3:0]waddr;
    wire [31:0]wdata;
    wire [5:0]fetch;
    wire [31:0]mtvec;
    wire [31:0]mepc;
    wire [31:0]csr_rdata;
    wire [11:0]csr_rkey;
    wire [2:0]csr_mask;
    // wire [31:0]r1;
    wire [31:0]mcycle;
    wire [31:0]mcycleh;
    wire [31:0]lsu_addr;
    wire [31:0]lsu_rdata;
    wire lsu_ren;
    wire lsu_wen;
    wire [31:0]lsu_wdata;
    wire [31:0]lsu_wmask;
    wire lsu_rready;
    wire is_isa_raise_intr;
    wire is_cpu_wen;
    wire is_mret;
    wire csr_wen;
    wire is_jalr;
    wire gpr_wen;
    wire is_ebreak;
    wire [31:0]wbu_wdata;
    wire rready;
    wire [1:0]addr_off;
    assign is_jalr = (fetch == 6'b011111||fetch == 6'b100000||
    fetch == 6'b100001||fetch == 6'b100010||fetch == 6'b100100||
    fetch == 6'b100011||fetch == 6'b000001||fetch == 6'b000010||
    fetch == 6'b100111||fetch == 6'b101000)?1:0;
    assign raddr1 = decode[18:15];
    assign raddr2 = decode[23:20];
    assign csr_rkey[11:0] = decode[31:20];
    assign wbu_wdata = lsu_ren?lsu_rdata:wdata;
    wire pc_valid;
    assign pc_valid = (lsu_ren||lsu_wen)?lsu_rready:rready;
    assign io_ifu_addr = pc_data_out;
    assign io_lsu_addr = lsu_addr;
    assign io_lsu_wen = lsu_wen;
    assign io_lsu_wdata = lsu_wdata<<(8*lsu_addr[1:0]);
    assign io_lsu_wmask = lsu_wmask<<lsu_addr[1:0];
    assign addr_off = lsu_addr[1:0];
    assign dnpc = is_isa_raise_intr?mtvec:(is_mret?mepc:dnpc1);       
    ysyx_25070194_new_IFU ysyx_25070194_my_ifu(
        .clock(clock),
        .reset(reset),
        .rvalid(io_ifu_respValid),
        .rready(rready),
        .arready(io_ifu_reqValid),
        .rdata(decode),
        .io_ifu_rdata(io_ifu_rdata),
        .is_cpu_wen(is_cpu_wen),
        .lsu_rready(lsu_rready),
        .lsu_ren(lsu_ren),
        .lsu_wen(lsu_wen)
    );
    ysyx_25070194_mux_32_2 ysyx_25070194_dnpc_mux(
        .data1(dnpc1),
        .data2(mtvec),
        .sel(is_isa_raise_intr),
        .out(dnpc)
    );
    ysyx_25070194_mux_32_2 ysyx_25070194_pc_mux(
        .data1(snpc),
        .data2(dnpc),
        .sel(is_jalr),
        .out(pc_data_in)
    );
    ysyx_25070194_register ysyx_25070194_pc(
        .clock(clock),
        .reset(reset),
        .en(pc_valid),
        .q(pc_data_out),
        .p(pc_data_in)
    );
    ysyx_25070194_alu ysyx_25070194_decoder(
        .decode(decode),
        // .r1(r1),
        .is_cpu_wen(is_cpu_wen),
        .pc(pc_data_out),
        .src1(src1),
        .src2(src2),
        .data_out1(wdata),
        .data_out2(dnpc1),
        .waddr(waddr),
        .csr_rdata(csr_rdata),
        .dnpc(snpc),
        .fetch(fetch),
        .is_ebreak(is_ebreak),
        .is_isa_raise_intr(is_isa_raise_intr),
        .is_mret(is_mret),
        .gpr_wen(gpr_wen),
        .csr_wen(csr_wen),
        .lsu_addr(lsu_addr),
        .lsu_ren(lsu_ren),
        .lsu_wdata(lsu_wdata),
        .lsu_wen(lsu_wen),
        .lsu_wmask(lsu_wmask)
    );
    ysyx_25070194_LSU ysyx_25070194_my_lsu(
        .clock(clock),
        .reset(reset),
        .lsu_rdata(lsu_rdata),
        .lsu_wen(lsu_wen),
        .lsu_ren(lsu_ren),
        .fetch(fetch),
        .lsu_rready(lsu_rready),
        .size(io_lsu_size),
        .io_lsu_rdata(io_lsu_rdata),
        .io_lsu_respValid(io_lsu_respValid),
        .io_lsu_reqValid(io_lsu_reqValid),
        .addr_off(addr_off)
    );
    ysyx_25070194_csr_mux ysyx_25070194_my_csr_mux(
        .key(csr_rkey),
        .mask(csr_mask)
    );
    ysyx_25070194_RegisterFile #(.ADDR_WIDTH(4),.DATA_WIDTH(32)) ysyx_25070194_gpr(
        .reset(reset),
        .clock(clock),
        .wen(gpr_wen),
        .wdata(wbu_wdata),
        .waddr(waddr),
        .raddr1(raddr1),
        .raddr2(raddr2),
        .rdata1(src1),
        .rdata2(src2)
        // .r1(r1)
    );
    ysyx_25070194_csr ysyx_25070194_my_csr(
        .reset(reset),
        .wen(csr_wen),
        .clock(clock),
        .is_isa_raise_intr(is_isa_raise_intr),
        .NO(4'hb),
        .epc(pc_data_out),
        .wdata(dnpc1),
        .waddr(csr_mask),
        .raddr(csr_mask),
        .rdata(csr_rdata),
        .mtvec(mtvec),
        .mepc(mepc),
        .mcycle(mcycle),
        .mcycleh(mcycleh)
    );
    ysyx_25070194_mcycle ysyx_25070194_my_mcycle(
        .clock(clock),
        .reset(reset),
        .p(mcycle+1),
        .q(mcycle)
    );
    ysyx_25070194_mcycleh ysyx_25070194_my_mcycleh(
        .clock(clock),
        .reset(reset),
        .low(mcycle),
        .p(mcycleh+1),
        .q(mcycleh)
    );
endmodule
module ysyx_25070194_new_IFU(
    input clock,
    input reset,
    input rvalid,
    input lsu_rready,
    inout lsu_ren,
    input lsu_wen,
    input [31:0]io_ifu_rdata,
    output reg arready,
    output rready,
    output reg is_cpu_wen,
    output [31:0]rdata
);
    // import "DPI-C" function int pmem_read_rom(input int raddr);
    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        WAIT  = 2'b01
    } state_t;
    reg is_re_arready;
    reg is_first_arready;
    reg [1:0]    curr_state, next_state;                   
    reg [31:0]   rdata_temp;           
    always @(*) begin
        is_cpu_wen = 0;
        // next_state = curr_state;
        case (curr_state)
            IDLE: begin
                if(rvalid) begin
                    next_state = WAIT;
                end
                else    next_state = IDLE;
            end

            WAIT: begin
                if(~(lsu_ren||lsu_wen)||lsu_rready)begin
                    is_cpu_wen = 1;
                    next_state = IDLE;
                end
                else begin
                    is_cpu_wen = 0;
                    next_state = WAIT;
                end
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    assign rready  = (curr_state == WAIT||reset == 1);
    assign rdata   = (curr_state == WAIT) ? rdata_temp : 32'd0;

    always @(posedge clock) begin
        if (reset) begin
            rdata_temp <= 0;
            is_first_arready <= 0;
            curr_state <= IDLE;
            is_re_arready <= 0;
            arready <= 0;
        end
        else begin
            arready <= (curr_state == WAIT && is_re_arready 
            && ~(lsu_ren||lsu_wen) ||~is_first_arready||lsu_rready );
            is_first_arready <= 1;
            is_re_arready <= 1;
            curr_state <= next_state;
            if (curr_state == IDLE && rvalid) begin
            rdata_temp <= io_ifu_rdata; 
            end
            else if(curr_state == IDLE) begin
                is_re_arready <= 0;
            end
        end 
    end
endmodule
module ysyx_25070194_mux_32_2(
    input [31:0]data1,
    input [31:0]data2,
    input sel,
    output reg [31:0]out
);
    always@(*)begin
        case(sel)
            0:out=data1;
            1:out=data2;
        endcase
    end
endmodule
module ysyx_25070194_register #(DATA_WIDTH = 32)(
    input clock,
    input reset,
    input en,
    input [DATA_WIDTH-1:0]p,
    output reg [DATA_WIDTH-1:0]q
);
    always@(posedge clock) begin
        if(reset) q<=32'h30000000;
        else if(en)  q<=p;
    end
endmodule
module ysyx_25070194_alu(
    input [31:0]pc,
    input [31:0]src1,
    input [31:0]src2,
    input [31:0]decode,
    // input [31:0]r1,
    input is_cpu_wen,
    input [31:0]csr_rdata,
    output reg[31:0]data_out1,
    output reg[31:0]data_out2,
    output reg[3:0]waddr,
    output reg[5:0]fetch,
    output reg gpr_wen,
    output reg csr_wen,
    output reg[31:0]dnpc,
    output reg is_ebreak,
    output reg is_isa_raise_intr,
    output reg is_mret,
    output reg lsu_ren,
    output reg lsu_wen,
    output reg [31:0]lsu_addr,
    output reg [31:0]lsu_wdata,
    output reg [31:0]lsu_wmask
);
//`define CONFIG_FTRACE 1
    /* verilator lint_off WIDTHTRUNC */
    `ifdef VERILATOR
    // import "DPI-C" function void call_function(input int unsigned pc,input int unsigned dnpc);
    // import "DPI-C" function void ret_function(input int unsigned pc,input int unsigned dnpc);
    `endif
    reg [11:0]imm_i;
    reg [19:0]imm_u;
    reg [11:0]imm_s;
    reg [20:0]imm_j;
    reg [12:0]imm_b;
    wire signed [31:0] src1_signed = src1;
    wire signed [31:0] src2_signed = src2;
    reg [31:0]imm_i_un;
    always@(*)begin
        is_ebreak = 0;
        is_mret = 0;
        is_isa_raise_intr = 0;
        dnpc = pc+4;
        waddr = decode[10:7];
        data_out1 = 0;
        data_out2 = 0;
        fetch = 0;
        lsu_addr = 0;
        lsu_wdata = 0;
        lsu_wmask = 0;
        imm_i[11:0] = decode[31:20];
        imm_u[19:0] = decode[31:12];
        imm_s[11:0] = {decode[31:25],decode[11:7]};
        imm_j[20:0] = {decode[31],decode[19:12],decode[20],decode[30:21],1'b0};
        imm_b[12:0] = {decode[31],decode[7],decode[30:25],decode[11:8],1'b0};
        lsu_ren = 0;
        lsu_wen = 0;
        
        casez(decode)

//-------------------------------------minirv----------------------------------------------------

            32'bzzzzzzzzzzzzzzzzz000zzzzz0010011:begin//addi
                fetch = 6'b000000;
                data_out1 = src1+{{20{imm_i[11]}},imm_i};
            end
            32'bzzzzzzzzzzzzzzzzz000zzzzz1100111:begin//jalr
                fetch = 6'b000001;
                data_out2 = (src1+{{20{imm_i[11]}},imm_i})&~32'h1;
                data_out1 = pc+4;
                `ifdef CONFIG_FTRACE
                if(waddr == 1) begin
                    call_function(pc,data_out2);
                end
                else if(waddr == 0) begin
                    ret_function(pc,data_out2);
                end
                `endif 
            end
            32'bzzzzzzzzzzzzzzzzzzzzzzzzz1101111:begin//jal,j
                fetch = 6'b000010;
                data_out1 = pc+4;
                data_out2 = pc+{{11{imm_j[20]}},imm_j};
                `ifdef CONFIG_FTRACE
                if(waddr == 1) begin
                    call_function(pc,data_out2);
                end
                `endif 
            end
            32'b0000000zzzzzzzzzz000zzzzz0110011:begin//add
                fetch = 6'b000011;
                data_out1 = src1+src2;
            end
            32'bzzzzzzzzzzzzzzzzzzzzzzzzz0110111:begin//lui
                fetch = 6'b000100;
                data_out1 = imm_u<<12;
            end

//--------------------------------------memory-------------------------------------------------

            32'bzzzzzzzzzzzzzzzzz010zzzzz0000011:begin//lw
                lsu_ren = 1;
                fetch = 6'b000101;
                lsu_addr = src1+{{20{imm_i[11]}},imm_i};
                lsu_wmask = {{28{1'b0}},4'b1111};
            end
            32'bzzzzzzzzzzzzzzzzz100zzzzz0000011:begin//lbu
                lsu_ren = 1;
                fetch = 6'b000110;
                lsu_addr = src1+{{20{imm_i[11]}},imm_i};
                lsu_wmask = {{28{1'b0}},4'b0001};
            end
            32'bzzzzzzzzzzzzzzzzz101zzzzz0000011:begin//lhu,i
                lsu_ren = 1;
                fetch = 6'b000111;
                lsu_addr = src1+{{20{imm_i[11]}},imm_i};
                lsu_wmask = {{28{1'b0}},4'b0011};
            end
            32'bzzzzzzzzzzzzzzzzz001zzzzz0000011:begin//lh,i
                lsu_ren = 1;
                fetch = 6'b001000;
                lsu_addr = src1+{{20{imm_i[11]}},imm_i};
                lsu_wmask = {{28{1'b0}},4'b0011};
            end
            32'bzzzzzzzzzzzzzzzzz000zzzzz0000011:begin//lb,i
                lsu_ren = 1;
                fetch = 6'b001001;
                lsu_addr = src1+{{20{imm_i[11]}},imm_i};
                lsu_wmask = {{28{1'b0}},4'b0001};
            end
            32'bzzzzzzzzzzzzzzzzz010zzzzz0100011:begin//sw
                lsu_wen = 1;
                fetch = 6'b001010;
                lsu_addr = src1+{{20{imm_s[11]}},imm_s};
                lsu_wdata = src2;
                lsu_wmask = {{28{1'b0}},4'b1111};
            end
            32'bzzzzzzzzzzzzzzzzz000zzzzz0100011:begin//sb
                lsu_wen = 1;
                fetch = 6'b001011;
                lsu_addr = src1+{{20{imm_s[11]}},imm_s};
                lsu_wdata = {{24{1'b0}},src2[7:0]};
                lsu_wmask = {{28{1'b0}},4'b0001};
            end
            32'bzzzzzzzzzzzzzzzzz001zzzzz0100011:begin//sh
                lsu_wen = 1;
                fetch = 6'b001100;
                lsu_addr = src1+{{20{imm_s[11]}},imm_s};
                lsu_wdata = {{16{1'b0}},src2[15:0]};
                lsu_wmask = {{28{1'b0}},4'b0011};
            end

//--------------------------------------other-------------------------------------------------------

            32'b0100000zzzzzzzzzz000zzzzz0110011:begin//sub,r
                fetch = 6'b001101;
                data_out1 = src1-src2;
            end
            32'bzzzzzzzzzzzzzzzzzzzzzzzzz0010111:begin//auipc,u
                fetch = 6'b001110;
                data_out1 = pc+({{12{imm_u[19]}},imm_u}<<12);
            end
            32'b0000000zzzzzzzzzz111zzzzz0110011:begin//and,r
                fetch = 6'b001111;
                data_out1 = src1&src2;
            end
            32'bzzzzzzzzzzzzzzzzz111zzzzz0010011:begin//andi,i
                fetch = 6'b010000;
                data_out1 = src1&{{20{imm_i[11]}},imm_i};
            end
            32'b0000000zzzzzzzzzz110zzzzz0110011:begin//or,r
                fetch = 6'b010001;
                data_out1 = src1|src2;
            end
            32'b0000000zzzzzzzzzz100zzzzz0110011:begin//xor,r
                fetch = 6'b010010;
                data_out1 = src1^src2;
            end
            32'bzzzzzzzzzzzzzzzzz100zzzzz0010011:begin//xori,i
                fetch = 6'b010011;
                data_out1 = src1^{{20{imm_i[11]}},imm_i};
            end
            32'bzzzzzzzzzzzzzzzzz110zzzzz0010011:begin//ori,i
                fetch = 6'b010100;
                data_out1 = src1|{{20{imm_i[11]}},imm_i};
            end

//-----------------------------------logical move-----------------------------------------------

            32'b0000000zzzzzzzzzz001zzzzz0110011:begin//sll,r
                fetch = 6'b010101;
                data_out1 = src1<<src2[4:0];
            end
            32'b0000000zzzzzzzzzz101zzzzz0110011:begin//srl,r
                fetch = 6'b010110;
                data_out1 = src1>>src2[4:0];
            end
            32'b0100000zzzzzzzzzz101zzzzz0110011:begin//sra,r
                fetch = 6'b010111;
                data_out1 = src1_signed>>>src2[4:0];
            end
            32'b0100000zzzzzzzzzz101zzzzz0010011:begin//srai,i
                fetch = 6'b011000;
                data_out1 = src1_signed>>>{{27{1'b0}}, decode[24:20]};
            end
            32'b0000000zzzzzzzzzz101zzzzz0010011:begin//srli,i
                fetch = 6'b011001;
                data_out1 = src1>>{{27{1'b0}}, decode[24:20]};
            end
            32'b0000000zzzzzzzzzz001zzzzz0010011:begin//slli,i
                fetch = 6'b011010;
                data_out1 = src1<<{{27{1'b0}}, decode[24:20]};
            end
            32'bzzzzzzzzzzzzzzzzz010zzzzz0010011:begin//slti,i,视为补码
                fetch = 6'b011011;
                data_out1 = src1_signed<{{20{imm_i[11]}},imm_i}?1:0;
            end
            32'b0000000zzzzzzzzzz010zzzzz0110011:begin//slt,r,视为补码
                fetch = 6'b011100;
                data_out1 = src1_signed<src2_signed?1:0;
            end
            32'b0000000zzzzzzzzzz011zzzzz0110011:begin//sltu,r,视为无符号数
                fetch = 6'b011101;
                data_out1 = src1<src2?1:0;
            end
            32'bzzzzzzzzzzzzzzzzz011zzzzz0010011:begin//sltiu,i,视为无符号数
                fetch = 6'b011110;
                imm_i_un = {{20{imm_i[11]}},imm_i};
                data_out1 = src1<imm_i_un?1:0;
            end

//----------------------------------b跳转相关-------------------------------------------------

            32'bzzzzzzzzzzzzzzzzz001zzzzz1100011:begin//bne,b
                fetch = 6'b011111;
                if(src1!=src2)begin  
                    data_out2 = pc+{{19{imm_b[12]}},imm_b};
                end
                else begin
                    data_out2 = dnpc;
                end
            end
            32'bzzzzzzzzzzzzzzzzz000zzzzz1100011:begin//beq,b
                fetch = 6'b100000;
                if(src1==src2)begin
                  data_out2 = pc+{{19{imm_b[12]}},imm_b};
                end
                else begin
                    data_out2 = dnpc;
                end
            end
            32'bzzzzzzzzzzzzzzzzz100zzzzz1100011:begin//blt,b,视为补码
                fetch = 6'b100001;
                if(src1_signed<src2_signed)begin
                    data_out2 = pc+{{19{imm_b[12]}},imm_b};
                end
                else begin
                    data_out2 = dnpc;
                end
            end
            32'bzzzzzzzzzzzzzzzzz101zzzzz1100011:begin//bge,b,视为补码
                fetch = 6'b100010;
                if(src1_signed>=src2_signed)begin
                    data_out2 = pc+{{19{imm_b[12]}},imm_b};
                end
                else begin
                    data_out2 = dnpc;
                end
            end
            32'bzzzzzzzzzzzzzzzzz110zzzzz1100011:begin//bltu,b,视为无符号数
                fetch = 6'b100011;
                if(src1<src2)begin
                    data_out2 = pc+{{19{imm_b[12]}},imm_b};
                end
                else begin
                    data_out2 = dnpc;
                end
            end
            32'bzzzzzzzzzzzzzzzzz111zzzzz1100011:begin//bgeu,b,视为无符号数
                fetch = 6'b100100;
                if(src1>=src2)begin
                    data_out2 = pc+{{19{imm_b[12]}},imm_b};
                end
                else begin
                    data_out2 = dnpc;
                end
            end
//----------------------------------m异常中断-------------------------------------------------
            32'bzzzzzzzzzzzzzzzzz001zzzzz1110011:begin//csrrw
                fetch = 6'b100101;
                data_out1 = csr_rdata;
                data_out2 = src1;
            end
            32'bzzzzzzzzzzzzzzzzz010zzzzz1110011:begin//csrrs
                fetch = 6'b100110;
                data_out1 = csr_rdata;
                data_out2 = csr_rdata|src1;
            end
            32'b00000000000000000000000001110011:begin//ecall
                fetch = 6'b100111;
                is_isa_raise_intr = 1;
            end
            32'b00110000001000000000000001110011:begin//mret
                fetch = 6'b101000;
                is_mret = 1;
            end
            32'b00000000000100000000000001110011:is_ebreak = 1;
            default: begin
                data_out1 = 0;
                data_out2 = 0;
                fetch = 0;
                lsu_addr = 0;
                lsu_wdata = 0;
                lsu_wmask = 0;
            end
        endcase
        if(fetch==6'b001010||fetch==6'b001011||fetch==6'b001100||fetch == 6'b011111||
        fetch == 6'b100011||fetch == 6'b100000||fetch == 6'b100001||fetch == 6'b100010||
        fetch == 6'b100100||fetch == 6'b100111||fetch == 6'b101000||is_cpu_wen == 0)  gpr_wen = 0;
        else    gpr_wen = 1;
        if((fetch == 6'b100101||fetch == 6'b100110)&&is_cpu_wen == 1) begin
            csr_wen = 1;
        end
        else begin
            csr_wen = 0;
        end
    end
endmodule
module ysyx_25070194_LSU(
    input clock,
    input reset,
    input lsu_wen,
    input [5:0]fetch,
    input [31:0]io_lsu_rdata,
    input [1:0]addr_off,
    input io_lsu_respValid,
    input lsu_ren,
    output reg lsu_rready,
    output reg [31:0]lsu_rdata,
    output reg [1:0]size,
    output reg io_lsu_reqValid
);
`ifdef VERILATOR
    // import "DPI-C" function byte unsigned pmem_read_ram(input int unsigned raddr);
    // import "DPI-C" function int pmem_write(
    // input int unsigned waddr, input int unsigned wdata, input int wmask);
`endif
    reg is_first_lsu_rready;
    reg is_been_alloc;
    reg [1:0]en_flash;
    wire [15:0]io_lsu_rdata1;
    assign io_lsu_rdata1 = io_lsu_rdata>>(addr_off*8);
    always @(posedge clock) begin
        en_flash <= {en_flash[0],(lsu_ren||lsu_wen)};
        is_been_alloc <= ~en_flash[1]&&en_flash[0];
        case(fetch)
            6'b000101:size <= 2'b10;
            6'b000110:size <= 2'b00;
            6'b000111:size <= 2'b01;
            6'b001000:size <= 2'b01;
            6'b001001:size <= 2'b00;
            6'b001010:size <= 2'b10;
            6'b001011:size <= 2'b00;
            6'b001100:size <= 2'b01;
            default:size <= 2'b00;
        endcase
        if (reset) begin
            lsu_rready <= 1'b0;
            lsu_rdata  <= 32'b0;
            is_first_lsu_rready <= 1;
            io_lsu_reqValid <= 0;
            is_been_alloc <= 0;
        end
        else begin
            if(io_lsu_reqValid) begin
                is_first_lsu_rready <= 0;
            end
            lsu_rready <= 0;
            io_lsu_reqValid <= ((lsu_ren||lsu_wen)&&is_been_alloc)||(is_first_lsu_rready&&(lsu_ren||lsu_wen));
            if(io_lsu_respValid) begin
                case(fetch)
                    6'b000101:begin
                        lsu_rdata <= (!lsu_wen) ? io_lsu_rdata : 32'b0;
                        lsu_rready <= 1;
                    end
                    6'b000110:begin
                        lsu_rdata <= (!lsu_wen) ? {{24{1'b0}},io_lsu_rdata1[7:0]} : 32'b0;
                        lsu_rready <= 1;
                    end
                    6'b000111:begin
                        lsu_rdata <= (!lsu_wen) ? {{16{1'b0}},io_lsu_rdata1[15:0]} : 32'b0;
                        lsu_rready <= 1;
                    end
                    6'b001000:begin
                        lsu_rdata <= (!lsu_wen) ? {{16{io_lsu_rdata1[15]}},io_lsu_rdata1[15:0]} : 32'b0;
                        lsu_rready <= 1;
                    end
                    6'b001001:begin
                        lsu_rdata <= (!lsu_wen) ? {{24{io_lsu_rdata1[7]}},io_lsu_rdata1[7:0]} : 32'b0;
                        lsu_rready <= 1;
                    end
                    default:begin
                        lsu_rdata <= 32'b0;
                        lsu_rready <= 0;
                    end
                endcase
            end
            if (lsu_wen&&io_lsu_respValid) begin
                lsu_rready <= 1;
            end
        end
    end
endmodule
module ysyx_25070194_csr_mux(
    input [11:0]key,
    output reg [2:0]mask
);
    always@(*)begin
        case(key)
            12'h342:mask=3'b000;//mcause
            12'h300:mask=3'b001;//mstatus
            12'h341:mask=3'b010;//mepc
            12'h305:mask=3'b011;//mtvec
            12'hb00:mask=3'b100;//mcycle
            12'hb80:mask=3'b101;//mcycleh
            12'hf11:mask=3'b110;//mvendorid
            12'hf12:mask=3'b111;//marchid
            default:mask=3'b000;
        endcase
    end
endmodule
module ysyx_25070194_RegisterFile #(ADDR_WIDTH = 5, DATA_WIDTH = 32) (
  input clock,
  input reset,
  input [DATA_WIDTH-1:0] wdata,
  input [ADDR_WIDTH-1:0] waddr,
  input [ADDR_WIDTH-1:0] raddr1,
  input [ADDR_WIDTH-1:0] raddr2,
  input wen,
  output [DATA_WIDTH-1:0] rdata1,
  output [DATA_WIDTH-1:0] rdata2
//   output reg [DATA_WIDTH-1:0] r1
);
  reg [DATA_WIDTH-1:0] rf [2**ADDR_WIDTH-1:0];
  `ifdef VERILATOR
//   export "DPI-C" function get_reg;
//   function int get_reg(input int num);
//     if(num>5'b11111)  begin 
//       get_reg = 32'h11451419;
//     end
//     else  begin 
//       get_reg = rf[num];
//     end
//   endfunction
  `endif 
  always @(posedge clock) begin
    if(reset) begin
        rf[0] <= 32'b0;
        rf[1] <= 32'b0;
        rf[2] <= 32'b0;
        rf[3] <= 32'b0;
        rf[4] <= 32'b0;
        rf[5] <= 32'b0;
        rf[6] <= 32'b0;
        rf[7] <= 32'b0;
        rf[8] <= 32'b0;
        rf[9] <= 32'b0;
        rf[10] <= 32'b0;
        rf[11] <= 32'b0;
        rf[12] <= 32'b0;
        rf[13] <= 32'b0;
        rf[14] <= 32'b0;
        rf[15] <= 32'b0;
    end
    else if (wen&&waddr!=0) rf[waddr] <= wdata;
  end
  assign rdata1 = (raddr1==0)?0:rf[raddr1];
  assign rdata2 = (raddr2==0)?0:rf[raddr2];
//   assign r1 = rf[1];
endmodule            
module ysyx_25070194_csr(
    input reset,
    input clock,
    input wen,
    input [31:0]epc,
    input [3:0]NO,
    input is_isa_raise_intr,
    input [2:0]raddr,
    input [2:0]waddr,
    input [31:0]mcycle,
    input [31:0]mcycleh,
    input [31:0]wdata,
    output [31:0]rdata,
    output [31:0]mtvec,
    output [31:0]mepc
);
    reg [31:0] csr [6:0];
    assign rdata = (raddr == 3'd4) ? mcycle : (raddr == 3'd5) ? mcycleh : 
                   (raddr == 3'd6) ? 32'h79737978: (raddr == 3'd7) ? 32'h17e8a72: csr[raddr];
    assign mtvec = csr[3];
    assign mepc = csr[2];
    always@(posedge clock)begin
        if(reset)begin
            csr[0] <= 0;
            csr[1] <= 0;
            csr[2] <= 0;
            csr[3] <= 0;
            csr[4] <= 0;
            csr[5] <= 0;
            csr[6] <= 0;
        end
        else if(wen)begin
            csr[waddr] <= wdata;
        end
        else if(is_isa_raise_intr)begin
            csr[0] <= {{28{1'b0}}, NO};
            csr[2] <= epc;
        end
    end
endmodule
module ysyx_25070194_mcycle(
    input clock,
    input reset,
    input [31:0]p,
    output reg [31:0]q
);
    always@(posedge clock)begin
        if(reset)begin
            q<=0;
        end
        else begin
            q<=p;
        end
    end
endmodule
module ysyx_25070194_mcycleh(
    input reset,
    input clock,
    input [31:0]low,
    input [31:0]p,
    output reg [31:0]q
);
    always@(posedge clock)begin
        if(reset) q <= 0;
        else if(low==32'hffffffff)begin
            q <= p;
        end
    end
endmodule 
/* verilator lint_on DECLFILENAME */
