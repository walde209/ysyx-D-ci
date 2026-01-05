
    module csr_addr_mux #(
    parameter IMM_WIDTH=12,
    parameter CSR_ADDR_WIDTH=2
) ( 
    input wen,
    input [IMM_WIDTH-1 : 0] imm,
    output reg [CSR_ADDR_WIDTH-1:0] waddr0,
    output reg [CSR_ADDR_WIDTH-1:0] waddr1,
    output reg [CSR_ADDR_WIDTH-1:0] raddr0,
    output reg wen0,
    output reg wen1
);
    always @(*) begin
        if(wen)begin
        case (imm)
            12'h000:begin          //ecall
                    raddr0=1;
                    wen0  =1;
                    waddr0=2;    
                    wen1  =1;
                    waddr1=3;    
            end
            12'h300:begin         //mstatus addr : 0
                    raddr0=0;     
                    wen0  =1;
                    waddr0=0;     
                    wen1  =0;
                    waddr1=0;    
            end
            12'h302:begin         //mret addr : 2
                    raddr0=2;     
                    wen0  =0;
                    waddr0=0;     
                    wen1  =0;
                    waddr1=0;   
            end
            12'h305:begin         //mtvec addr : 1
                    raddr0=1;     
                    wen0  =1;
                    waddr0=1;    
                    wen1  =0;
                    waddr1=0;    
            end
            12'h341:begin         //mepc addr : 2
                    raddr0=2;     
                    wen0  =1;
                    waddr0=2;     
                    wen1  =0;
                    waddr1=0;    
            end                  
            12'h342:begin         //mcause addr : 3
                    raddr0=3;     
                    wen0  =1;
                    waddr0=3;     
                    wen1  =0;
                    waddr1=0;    
            end      
            12'hB00:begin         //mcycle addr : 4
                    raddr0=4;     
                    wen0  =0;
                    waddr0=0;     
                    wen1  =0;
                    waddr1=0;    
            end
            12'hB80:begin         //mcycleh addr : 5
                    raddr0=5;     
                    wen0  =0;
                    waddr0=0;     
                    wen1  =0;
                    waddr1=0;    
            end
            12'hF12:begin         //marchid addr : 6
                    raddr0=6;     
                    wen0  =0;
                    waddr0=0;     
                    wen1  =0;
                    waddr1=0;    
            end
            12'hF11:begin         //mvendorid addr : 7
                    raddr0=7;     
                    wen0  =0;
                    waddr0=0;     
                    wen1  =0;
                    waddr1=0;    
            end
            default:begin 
                    raddr0 = 0;
                    wen0  =0;
                    waddr0=0;
                    wen1  =0;
                    waddr1=0;    
            end
        endcase
        end
        else begin 
                    raddr0 = 0;
                    wen0  =0;
                    waddr0=0;
                    wen1  =0;
                    waddr1=0;  
        end
    end
endmodule


module ysyx_24090015_CSR_RegFiles#(
    parameter DATAWIDTH = 32,
    parameter IMM_WIDTH=12,
    parameter CSR_ADDR_WIDTH=7
) (
    input clock,
    input reset,
    input wen,
	input [IMM_WIDTH-1 : 0]imm, 
    input [DATAWIDTH-1 : 0]wdata0,
    input [DATAWIDTH-1 : 0]wdata1,
    output [DATAWIDTH-1 : 0]rdata
);
wire [CSR_ADDR_WIDTH-1:0] csr_waddr0;
wire [CSR_ADDR_WIDTH-1:0] csr_waddr1;
wire [CSR_ADDR_WIDTH-1:0] csr_raddr0;
wire wen0,wen1;

    csr_addr_mux #(
        .IMM_WIDTH(IMM_WIDTH),          
        .CSR_ADDR_WIDTH(CSR_ADDR_WIDTH)       
    ) csr_addr_mux_instance (
        .wen(wen),
        .imm(imm),       
        .raddr0(csr_raddr0),
        .wen0(wen0),
        .waddr0(csr_waddr0),  
        .wen1(wen1),
        .waddr1(csr_waddr1)       
    );

reg [DATAWIDTH -1 : 0] CSRS [7:0];

always @(posedge clock) begin
    if(reset)begin
		CSRS[0] <= 32'h00000000;        //mstatus
        CSRS[1] <= 32'h00000000;        //mtvec
        CSRS[2] <= 32'h00000000;        //mepc
        CSRS[3] <= 32'h00000000;        //mcause
        CSRS[4] <= 32'h00000000;        //mcycle
        CSRS[5] <= 32'h00000000;        //mcycleh

        CSRS[6] <= 32'h16F959F;         //marchild
        CSRS[7] <= 32'd24090015;        //mvendorid

    end
    else begin
    if(csr_waddr0 <= 3 || csr_waddr1<= 3)begin
        if(wen0)begin
            CSRS[csr_waddr0] <= wdata0;
        end 
        if(wen1)begin
            CSRS[csr_waddr1] <= wdata1;
        end
    end
    CSRS[4] <= CSRS[4] + 5;

    if(CSRS[4] ==  32'hFFFFFFFF)begin
        CSRS[5] <= CSRS[5] + 1;
    end

    end

    
    
end
        
assign rdata = CSRS[csr_raddr0];

// export "DPI-C" function read_wire;

// function automatic int read_wire(input int sec);
// 	return CSRS[sec];
// endfunction

endmodule

// import "DPI-C" function void ebreak();
`ifdef VERILATOR
import "DPI-C" function void notify_ebreak();
`endif 
module ysyx_24090015_EXU#(
	parameter DATAWIDTH=32,
	parameter ADDRWIDTH=32
) (
    input clock,
	input reset,

	input [DATAWIDTH-1:0] inst_in,
	input lsu_wvalid,
	
    input [DATAWIDTH-1:0] imm,
	input [DATAWIDTH-1:0] src1,
    input [DATAWIDTH-1:0] src2,
    output reg [DATAWIDTH-1:0] rd_wdata,

	input [DATAWIDTH-1:0] pc,
    output reg [ADDRWIDTH-1:0]  dnpc,

	output reg pmem_work,
	output reg pmem_ls,
	input [DATAWIDTH-1:0] pmem_rdata,
	output reg [DATAWIDTH-1:0] pmem_addr,
	output reg [DATAWIDTH-1:0] pmem_wdata,
	output reg [1:0] pmem_size,
	output reg [3:0] pmem_wmask,
	// output reg [3:0] pmem_rmask,


	input [DATAWIDTH-1:0] 	csr_rdata,
	output reg [DATAWIDTH-1:0] csr_wdata0,
	output reg [DATAWIDTH-1:0] csr_wdata1

);
    localparam STORGE =0;
    localparam LOAD   =1;

	localparam UINT = 0;
	localparam INT  = 1;

	localparam DWORD = 4'b1111;
	localparam DHALF = 4'b0011;
	localparam DBYTE = 4'b0001;


	localparam UART  = 4'b0001;
	localparam SDRAM = 4'b1000;
	localparam FLASH = 4'b0011;

	// wire  wmask_ways =  pmem_addr[31:28]===SDRAM ?  1  : 0;
	wire  wmask_ways =  1;

    wire [ADDRWIDTH-1:0] snpc;
	assign snpc = pc+4;

	reg data_type;
	reg [3:0] pmem_rmask;

	reg [DATAWIDTH-1:0] exu_data, lsu_data;


	assign rd_wdata = lsu_wvalid && pmem_ls == LOAD ? lsu_data : exu_data; 

    always @(*) begin
					dnpc = snpc ;
					pmem_work = 0;
					pmem_size= 2'b0;

					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata = 0;
					exu_data = 0;
					data_type = 0;
					csr_wdata0 =0 ;
					csr_wdata1 =0 ;

			casez (inst_in)
					32'h00100073:begin
`ifdef VERILATOR
        notify_ebreak();
`endif 

					end
					32'b???????_?????_?????_000_?????_00100_11: begin //addi II
					pmem_size= 0;
                    pmem_work = 0 ;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

					exu_data = src1 + imm;
        			dnpc = snpc;
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
                    end
                    32'b???????_?????_?????_111_?????_00100_11: begin //andi II
					pmem_size= 0;
                    pmem_work = 0 ;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

					exu_data = src1 & imm;
        			dnpc = snpc;
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
                    end
                    32'b0000000_?????_?????_101_?????_00100_11: begin  //stli II
					pmem_size= 0;
                    pmem_work = 0 ;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

					exu_data = src1 >> imm[4:0];
        			dnpc = snpc;
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
                    end
                    32'b0000000_?????_?????_001_?????_00100_11: begin //strlli II
					pmem_size= 0;
                    pmem_work = 0 ;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;


					exu_data = src1 << imm[4:0];
        			dnpc = snpc;
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
                    end
			        32'b???????_?????_?????_011_?????_00100_11: begin //sltiu II
					pmem_size= 0;
                    pmem_work = 0 ;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

					exu_data = (src1 < imm);
        			dnpc = snpc;
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
					end
					32'b0100000_?????_?????_101_?????_00100_11: begin //srai II
					pmem_size= 0;
                    pmem_work = 0 ;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

					exu_data = (src1[31]==1'b1) ? ((32'hffffffff<<(31-imm[4:0]) | src1>>imm[4:0])) : src1>>imm[4:0];
        			dnpc = snpc;
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
					end
					32'b???????_?????_?????_100_?????_00100_11: begin //xori II
                    pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

					exu_data = src1 ^ imm;
        			dnpc = snpc;
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
					end
					32'b???????_?????_?????_110_?????_00100_11: begin //ori II
                    pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

					exu_data = src1 | imm;
        			dnpc = snpc;
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
					end
					32'b???????_?????_?????_000_?????_11001_11: begin //jalr IJ
                    pmem_work = 0 ;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

					dnpc =src1+imm;
					exu_data = pc+4;
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
					end

					32'b???????_?????_?????_???_?????_00101_11: begin //auipc U
					pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

					exu_data  = pc + imm;				
        			dnpc      = snpc;
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
					end
					32'b???????_?????_?????_???_?????_01101_11: begin //lui U
                    pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

					exu_data = imm;
        			dnpc = snpc;
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
					end
					32'b???????_?????_?????_???_?????_11011_11: begin //jal J				
                    pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

					exu_data=snpc;
					dnpc = pc+imm;
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
				    end

					32'b???????_?????_?????_001_?????_11000_11: begin //bne B
					pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;


					if(src1!=src2)dnpc=pc+imm;
					else dnpc = snpc;
					exu_data = 0;	
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
					end
					32'b???????_?????_?????_000_?????_11000_11: begin //beq B
					pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;


					if(src1==src2)dnpc=pc+imm;
					else dnpc = snpc;
					exu_data = 0;	
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
					end
                    32'b???????_?????_?????_101_?????_11000_11: begin //bge B
                    pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

                    if(((src1[31]==0&&src2[31]==0)&&(src1>=src2))||((src1[31]==1&&src2[31]==1)&&(src1>=src2))||(src1[31]==0&&src2[31]==1))dnpc = pc + imm;
					else dnpc = snpc;
					exu_data = 0;	
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
                    end
                    32'b???????_?????_?????_111_?????_11000_11: begin //bgeu B
                    pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

                    if(src1>=src2)dnpc = pc + imm;
					else dnpc = snpc;
					exu_data = 0;	
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
                    end
                    32'b???????_?????_?????_100_?????_11000_11: begin //blt B
                    pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

                    if(((src1[31]==0&&src2[31]==0)&&(src1<src2))||((src1[31]==1&&src2[31]==1)&&(src1<src2))||(src1[31]==1&&src2[31]==0))dnpc = pc + imm;
					else dnpc = snpc;
					exu_data = 0;	
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
                    end
                    32'b???????_?????_?????_110_?????_11000_11: begin //bltu B
                    pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

                    if(src1<src2)dnpc = pc + imm;
					else dnpc = snpc;
					exu_data = 0;	
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
                    end
					32'b0100000_?????_?????_000_?????_01100_11: begin //sub R
					pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

					exu_data = src1 - src2;
        			dnpc = snpc;
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
					end
					32'b0000000_?????_?????_000_?????_01100_11: begin //add R
					pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

                    exu_data = src1 + src2;
        			dnpc = snpc;
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
					end
                    32'b0000000_?????_?????_110_?????_01100_11: begin //or R
                    pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

                    exu_data = src1 |src2;
        			dnpc = snpc;
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
                    end
					32'b0000000_?????_?????_111_?????_01100_11: begin //and R
                    pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

                    exu_data = src1 & src2;
        			dnpc = snpc;
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
                    end
					32'b0000000_?????_?????_100_?????_01100_11: begin //xor R
                    pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

                    exu_data = src1 ^ src2;
        			dnpc = snpc;
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
                    end
					32'b0000000_?????_?????_001_?????_01100_11: begin //sll R
                    pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

					exu_data = src1[31:0]<<src2[4:0];
        			dnpc = snpc;
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
					end
					32'b0000000_?????_?????_101_?????_01100_11: begin //srl R
                    pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

					exu_data = src1[31:0]>>src2[4:0];
        			dnpc = snpc;
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;
					end
					32'b0100000_?????_?????_101_?????_01100_11: begin //sra R
                    pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

					exu_data = (src1[31]==1'b1) ? ((32'hffffffff<<(31-src2[4:0]) | src1>>src2[4:0])) : src1>>src2[4:0];
        			dnpc = snpc;
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;

					end
					32'b0000000_?????_?????_011_?????_01100_11: begin //sltu R
                    pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

                    exu_data = (src1<src2);
        			dnpc = snpc;
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					data_type = INT;

                    end
					32'b0000000_?????_?????_010_?????_01100_11: begin //slt R
                    pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

					data_type = INT;
                    exu_data=(((src1[31]==0&&src2[31]==0)&&(src1<src2))||((src1[31]==1&&src2[31]==1)&&(src1<src2))||(src1[31]==1&&src2[31]==0));
					csr_wdata0 = 0;
					csr_wdata1 = 0;
        			dnpc = snpc;

                    end
					32'b???????_?????_?????_011_?????_1110_011: begin //csrrc I 
                    pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

					data_type = INT;
					exu_data  = csr_rdata; 
					csr_wdata0 = csr_rdata &~ src1;
					csr_wdata1 = 0;
        			dnpc = snpc;

										end
					32'b???????_?????_?????_010_?????_1110_011: begin //csrrs I 
                    pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;

					data_type = INT;
					exu_data  = csr_rdata; 
					csr_wdata0 = csr_rdata | src1;
					csr_wdata1 = 0;
        			dnpc = snpc;

										end
					32'b???????_?????_?????_001_?????_1110_011: begin //csrrw I 
                    pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata =0;


					data_type = INT;
					exu_data  = csr_rdata; 
					csr_wdata0 = src1;
        			dnpc = snpc;
					csr_wdata1 = 0;



										end
					32'b0011000_00010_00000_000_00000_11100_11: begin //mret
                    pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					
					data_type = INT;
					csr_wdata0 = 0;
					csr_wdata1 = 0;
					dnpc = csr_rdata;

					exu_data = 0;
					pmem_wdata =0;
										end				
				 	32'b0000000_00000_00000_000_00000_11100_11: begin //ecall
                    pmem_work = 0 ;
					pmem_size= 0;
					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;

					data_type = INT;
					csr_wdata0 = pc;
					csr_wdata1 = src1;
					dnpc = csr_rdata;

					exu_data = 0;
					pmem_wdata =0;
										end
										32'b???????_?????_?????_010_?????_00000_11: begin //lw IS					
											pmem_work = 1;
											pmem_size= 2'b10;

											pmem_ls   = LOAD;
											pmem_addr = src1+imm;
											pmem_wmask = DWORD;
											pmem_rmask = DWORD;
											exu_data = pmem_rdata;
											data_type = INT;

											dnpc = snpc;
											csr_wdata0 =0 ;
											csr_wdata1 =0 ;
											pmem_wdata =0;
						
						
										end
										32'b???????_?????_?????_001_?????_00000_11: begin //lh IS					
											pmem_work = 1;
											pmem_size= 2'b01;

											pmem_ls   = LOAD;
											pmem_addr = src1+imm;
											pmem_wmask = DWORD;
											pmem_rmask = wmask_ways==0 ? DHALF  : DHALF << (pmem_addr[1:0]);
											data_type = INT;
						
											dnpc = snpc;
											exu_data = 0;
											csr_wdata0 =0 ;
											csr_wdata1 =0 ;
											pmem_wdata =0;
										end
										32'b???????_?????_?????_101_?????_00000_11: begin //lhu IS					
											pmem_work = 1;
											pmem_size= 2'b01;

											pmem_ls   = LOAD;
											pmem_addr = src1+imm;
											pmem_wmask = DWORD;
											pmem_rmask = wmask_ways==0 ? DHALF : DHALF << (pmem_addr[1:0]);
											data_type = UINT;
						
											dnpc = snpc;
											exu_data = 0;
											csr_wdata0 =0 ;
											csr_wdata1 =0 ;
											pmem_wdata =0;
						
										end
										32'b???????_?????_?????_000_?????_00000_11: begin //lb IS
											pmem_work = 1;
											pmem_size= 2'b0;

											pmem_ls   = LOAD;
											pmem_addr = src1+imm;
											pmem_wmask = DWORD;
											pmem_rmask = wmask_ways==0 ? DBYTE : DBYTE<< (pmem_addr[1:0]);
											data_type = INT;
						
											dnpc = snpc;
											exu_data = 0;
											csr_wdata0 =0 ;
											csr_wdata1 =0 ;
											pmem_wdata =0;
										end
										32'b???????_?????_?????_100_?????_00000_11: begin //lbu IS
											pmem_work = 1;
											pmem_size= 2'b0;

											pmem_ls   = LOAD;
											pmem_addr = src1+imm;
											pmem_wmask = DWORD;
											pmem_rmask = wmask_ways==0 ? DBYTE : DBYTE << (pmem_addr[1:0]);
											data_type = UINT;
						
											dnpc = snpc;
											exu_data = 0;
											csr_wdata0 =0 ;
											csr_wdata1 =0 ;
											pmem_wdata =0;
										end
										32'b???????_?????_?????_010_?????_01000_11: begin //sw S
											pmem_work = 1;
											pmem_size= 2'b10;

											pmem_ls   = STORGE;
											pmem_addr = src1+imm;
											pmem_wmask = DWORD  ;
											pmem_wdata = src2;
						
											dnpc = snpc;
											pmem_rmask = 0;
											exu_data = 0;
											data_type = 0;
											csr_wdata0 =0 ;
											csr_wdata1 =0 ;
										end
										32'b???????_?????_?????_000_?????_01000_11: begin //sb S
											pmem_work = 1;
											pmem_size= 2'b0;

											pmem_ls   = STORGE;
											pmem_addr = (src1+imm) ;
											pmem_wmask = wmask_ways==0 ? DBYTE : DBYTE<< (pmem_addr[1:0]);
											pmem_wdata = src2[7:0]<< (pmem_addr[1:0]*8);
											
											dnpc = snpc;
											pmem_rmask = 0;
											exu_data = 0;
											data_type = 0;
											csr_wdata0 =0 ;
											csr_wdata1 =0 ;
										end
										32'b???????_?????_?????_001_?????_01000_11: begin //sh S
											dnpc = snpc;
											pmem_work = 1;
											pmem_size= 2'b01;

											pmem_ls   = STORGE;
											pmem_addr = (src1+imm);
											pmem_wmask = wmask_ways==0 ? DHALF  : DHALF<< (pmem_addr[1:0]);
											pmem_wdata = src2[15:0] << (pmem_addr[1:0]*8);
											
											pmem_rmask = 0;
											exu_data = 0;
											data_type = 0;
											csr_wdata0 =0 ;
											csr_wdata1 =0 ;
											
						
										end			
				default begin 
					dnpc = snpc ;
					pmem_work = 0;
					pmem_size= 2'b0;

					pmem_ls   = 0;
					pmem_addr = 0;
					pmem_wmask = 0;
					pmem_rmask = 0;
					pmem_wdata = 0;
					exu_data = 0;
					data_type = 0;
					csr_wdata0 =0 ;
					csr_wdata1 =0 ;

			end
        
		endcase     



	end

	always @(*) begin
			if(reset)begin
				lsu_data = 0;
			end
			else begin
				case (pmem_rmask)
					DBYTE: begin
						if(data_type == INT) lsu_data = {{24{pmem_rdata[7]}},pmem_rdata[7:0]};
						else lsu_data = {{24'b0},pmem_rdata[7:0]};
					end
					4'b0010 : begin
						if(data_type == INT) lsu_data = {{24{pmem_rdata[15]}},pmem_rdata[15:8]};
						else lsu_data = {{24'b0},pmem_rdata[15:8]};
					end
					4'b0100 : begin
						if(data_type == INT) lsu_data = {{24{pmem_rdata[23]}},pmem_rdata[23:16]};
						else lsu_data = {{24'b0},pmem_rdata[23:16]};
					end
					4'b1000 : begin
						if(data_type == INT) lsu_data = {{24{pmem_rdata[31]}},pmem_rdata[31:24]};
						else lsu_data = {{24'b0},pmem_rdata[31:24]};
					end
					DHALF:begin
						if(data_type == INT) lsu_data = {{16{pmem_rdata[15]}},pmem_rdata[15:0]};
						else lsu_data = {{16'b0},pmem_rdata[15:0]};
					end
					4'b0110:begin
						if(data_type == INT) lsu_data = {{16{pmem_rdata[23]}},pmem_rdata[23:8]};
						else lsu_data = {{16'b0},pmem_rdata[23:8]};	
					end
					4'b1100:begin
						if(data_type == INT) lsu_data = {{16{pmem_rdata[31]}},pmem_rdata[31:16]};
						else lsu_data = {{16'b0},pmem_rdata[31:16]};	
					end
					DWORD: lsu_data = pmem_rdata;
					default : lsu_data = 0;
				endcase
			end
	end
endmodule


module ysyx_24090015_IFU#(
    parameter DATAWIDTH=32,
    parameter ADDRWIDTH=32
    ) (
    input clock,
    input reset,
    input [ADDRWIDTH-1:0] dnpc,
    output reg[ADDRWIDTH-1:0] pc,
    output [DATAWIDTH-1 : 0]inst,

    output reg       ifu_reqValid,
    output reg [31:0] ifu_raddr,
    input  [31:0] ifu_rdata,
    input         ifu_respValid,

    input lsu_work,
    input lsu_respValid
    );


    localparam BASEADDR = 32'h30000000;

    localparam IDLE = 0;
    localparam FETCH = 1;
    localparam LS = 2;


    always @(posedge clock) begin 
        if(reset)begin
            pc <= BASEADDR;
        end
		else 
        if(ifu_respValid)begin
            pc <= dnpc;
        end
	end
    // assign inst  = 0;
    // assign inst  = (ifu_reqValid && ifu_respValid) ? ifu_rdata : 0;
    assign inst  = ifu_rdata;


    
    reg [1:0] ifu_state;
    always @(posedge clock ) begin
        if(reset)begin
            ifu_state <= IDLE;
            ifu_raddr <= pc;
            ifu_reqValid <= 0;
        end 
        else begin
            case (ifu_state)
                IDLE :begin
                  ifu_reqValid <= 1;
                  ifu_raddr    <= pc;

                  ifu_state    <= FETCH;
                end
                FETCH : begin
                  ifu_reqValid <= 0;

                  if(ifu_respValid)begin
                    if(lsu_work)begin
                        ifu_state <= LS;
                    end 
                    else begin
                        ifu_state <= IDLE;    
                    end
                  end
                end 
                LS : begin
                    if(lsu_respValid)begin
                        ifu_reqValid <= 1;
                        ifu_raddr    <= pc;
                        ifu_state    <= FETCH;
                    end
                end
            endcase

          end
    end
endmodule

module ysyx_24090015_RegisterFile #(
  parameter ADDR_WIDTH = 4, 
  parameter DATA_WIDTH = 32
  ) (
  input clock,
  input reset,
  input [DATA_WIDTH-1:0] wdata,
  input [ADDR_WIDTH-1:0] waddr,
  input wen,
	input ren1,
	input ren2,
  input [ADDR_WIDTH-1:0] raddr1,
  input [ADDR_WIDTH-1:0] raddr2,
	output [DATA_WIDTH-1:0] rdata1,
  output [DATA_WIDTH-1:0] rdata2
);
 reg [DATA_WIDTH-1 : 0] rf [2**ADDR_WIDTH-1:0];

/*
 // 添加DPI-C导出函数
export "DPI-C" context function read_gpr;
          
              // 函数返回寄存器组的地址
function automatic int read_gpr(input int idx);
  return rf[idx];  // 返回寄存器数组的地址
endfunction
 */

 		// export "DPI-C" function read_wire;

		// function automatic int read_wire(input int sec);
		// 	return rf[sec];
		// endfunction
    
 integer i;
  always @(posedge clock) begin
	if(reset)begin
		for(i=0;i<2**ADDR_WIDTH;i=i+1)begin
			rf[i] <= 0;
		end
	end
    else if (wen && (waddr!=0)) rf[waddr] <= wdata;
  end

assign rdata1=({32{ren1}})&(rf[raddr1]);
assign rdata2=({32{ren2}}&rf[raddr2]);
endmodule


module ysyx_24090015_LSU #(
    parameter DATAWIDTH =32,
    parameter ADDRWIDTH =32
) (
  input clock,
  input reset,

  input LSU_work,
  input ls,        
  input [ADDRWIDTH-1 : 0] addr,
  input [DATAWIDTH-1 : 0] sdata,
  output [DATAWIDTH-1 : 0] ldata,
  input [3:0] storge_mask,
  output wvalid,


    output reg       lsu_reqValid,
    // output        lsu_reqValid,
    output [DATAWIDTH -1 :0] lsu_addr,
    output        lsu_wen,
    output [DATAWIDTH -1 :0] lsu_wdata,
    output [ 3:0] lsu_wmask,
    input         lsu_respValid,
    input  [DATAWIDTH -1 :0] lsu_rdata
);


    localparam STORGE =0;
    localparam LOAD   =1;

    localparam IDLE = 0;
    localparam WAIT = 1;
    localparam FINISH = 2;
assign wvalid = lsu_respValid;
assign ldata = lsu_rdata;
// assign lsu_reqValid = lsu_respValid ? 0 : LSU_work;
    reg [1: 0] lsu_state;

    always @(posedge clock) begin
      if(reset)begin
        lsu_state <= IDLE;
      end
      else begin
        case (lsu_state)
          IDLE : begin
            if(LSU_work)begin
              lsu_state  <= WAIT;
              // lsu_reqValid = 1;
            end
          end
          WAIT : begin
            if(lsu_respValid)begin
              lsu_state <= FINISH;
              // lsu_reqValid = 0;
            end
          end 
          FINISH : begin
            lsu_state <= IDLE;
          end
        endcase
      end
    end

    always @(*) begin
      if(reset)begin
          lsu_reqValid = 0;
          // lsu_addr = 0;
          // lsu_wdata = 0;
          // lsu_wmask = 0;

        end else begin
          case (lsu_state)
            IDLE : begin
                  lsu_reqValid = LSU_work;

            end
            WAIT : begin
              lsu_reqValid = 0;
              // if(lsu_respValid)begin
              //   // lsu_state <= IDLE;
              //   lsu_reqValid = 0;
              // end
            end 
            default : lsu_reqValid = 0;
          endcase
        end
  end


assign  lsu_addr = addr;
assign  lsu_wdata = (ls == STORGE) ? sdata : 0 ;
assign  lsu_wmask = (ls == STORGE) ? storge_mask : 0 ;
assign  lsu_wen = (ls == STORGE);
endmodule


module ysyx_24090015_IDU#(
	parameter WIDTH=32
	) (
    input clock,
    input [WIDTH-1:0] inst_in,
    output reg [WIDTH-1:0] imm,

    output reg  ren1, 
	output reg  ren2, 
	output reg  wen,
	output reg  pwen,
	output reg  valid,
	output reg csr_wen,


	output reg [4:0] rd,
	output reg  [4:0] rs1,
	output reg  [4:0] rs2
);

localparam   R = 1;
localparam  II = 2;
localparam  IJ = 3;
localparam  IS = 4;
localparam  IC = 5;
localparam  S  = 6;
localparam  B  = 7;
localparam  U  = 8;
localparam  J  = 9;


    wire [3:0] inst_type;
    ysyx_24090015_TYPE#(
        .WIDTH(32)
    ) t0(
        .clock(clock),
        .inst(inst_in),
        .inst_type(inst_type)
    );

    wire [WIDTH-1:0] temp_immI , temp_immU,temp_immJ,temp_immS,temp_immB;
    ysyx_24090015_immI#(
        .WIDTH(32)
    ) i0(
        .inst(inst_in),
        .immI(temp_immI)
    );

		ysyx_24090015_immU#(
		.WIDTH(32)	
		) i1(
			.inst_in(inst_in),
			.immU(temp_immU)
		);


		ysyx_24090015_immJ#(
		.WIDTH(32)	
		) i2 (
			.inst_in(inst_in),
			.immJ(temp_immJ)
		);

        ysyx_24090015_immS#(
		.WIDTH(32)	
		) i3 (
			.inst_in(inst_in),
			.immS(temp_immS)
		);

		ysyx_24090015_immB#(
		.WIDTH(32)	
		) i4 (
			.inst_in(inst_in),
			.immB(temp_immB)
		);

		always @(*)begin
							rs1=5;
							rs2=0;
							ren1=0;
							ren2=0;
							valid=0;
							rd=0;
							wen=0;
							pwen=0;
							imm=0;	
							csr_wen = 0;

				case(inst_type)
					II : begin 
							rs1=inst_in[19:15];
							rs2=0;
							ren1=1;
							ren2=0;
							valid=0;
							rd=inst_in[11:7];
							wen=1;
							pwen=0;
							imm=temp_immI;
							csr_wen = 0;

				end
					IJ : begin 
							rs1=inst_in[19:15];
							rs2=0;
							ren1=1;
							ren2=0;
							valid=0;
							rd=inst_in[11:7];
							wen=1;
							pwen=0;
							imm=temp_immI;
							csr_wen = 0;

				end
				IS : begin 
							rs1=inst_in[19:15];
							rs2=0;
							ren1=1;
							ren2=0;
							valid=1;
							rd=inst_in[11:7];
							wen=1;
							pwen=0;
							imm=temp_immI;
							csr_wen = 0;

				end
					IC: begin 
							rs1=inst_in[14:12]==0 ? 15:inst_in[19:15];
							rs2=0;
							ren1=1;
							ren2=0;
							valid=0;
							rd=inst_in[11:7];
							wen=1;
							pwen=0;
							imm=temp_immI;
							csr_wen = 1;


				end
					U : begin 
							rs1=0;
							rs2=0;
							ren1=0;
							ren2=0;
							valid=0;
							rd=inst_in[11:7];
							wen=1;
							pwen=0;
							imm=temp_immU;
							csr_wen = 0;

				end
					J : begin 
							rs1=0;
							rs2=0;
							ren1=0;
							ren2=0;
							valid=0;
							rd=inst_in[11:7];
							wen=1;
							pwen=0;
							imm=temp_immJ;
							csr_wen = 0;

				end
					S : begin 
							rs1=inst_in[19:15];
							rs2=inst_in[24:20];
							ren1=1;
							ren2=1;
							valid=1;
							rd=0;
							wen=0;
							pwen=1;
							imm=temp_immS;							
							csr_wen = 0;
							
				end
				    B : begin 
							rs1=inst_in[19:15];
							rs2=inst_in[24:20];
							ren1=1;
							ren2=1;
							valid=0;
							rd=0;
							wen=0;
							pwen=0;
							imm=temp_immB;							
							csr_wen = 0;
							
				end
				    R : begin 
							rs1=inst_in[19:15];
							rs2=inst_in[24:20];
							ren1=1;
							ren2=1;
							valid=0;
							rd=inst_in[11:7];
							wen=1;
							pwen=0;
							imm=0;							
							csr_wen = 0;
							
				end
                default : begin
							rs1=5;
							rs2=0;
							ren1=0;
							ren2=0;
							valid=0;
							rd=0;
							wen=0;
							pwen=0;
							imm=0;	
							csr_wen = 0;

                end
				
				endcase

		end
		
endmodule


module ysyx_24090015_SEXT#(
    parameter DATA_WIDTH=32,
    parameter WIDTH=32
) (
    input [DATA_WIDTH-1:0] in,
    output [WIDTH-1:0] out
);
    assign out = {{(WIDTH-DATA_WIDTH){in[DATA_WIDTH-1]}}, in};
endmodule 

module ysyx_24090015_immI#(
	parameter WIDTH=32) (
    input [WIDTH-1:0] inst,
    output [WIDTH-1:0] immI
);

    wire [11:0] init;				
    assign init = inst[WIDTH-1:WIDTH-12];
		
    ysyx_24090015_SEXT#(
        .DATA_WIDTH(12),
        .WIDTH(32)
    ) s0(
        .in(init),
        .out(immI)
    );
endmodule

module ysyx_24090015_immU#(
	parameter WIDTH=32) (
	input [WIDTH-1 :0] inst_in,
	output [WIDTH-1: 0] immU
);
	assign immU = {inst_in[31:12],12'b0};

endmodule


module ysyx_24090015_immJ#(
	parameter WIDTH=32) (

input [WIDTH-1 : 0] inst_in,
output [WIDTH-1 : 0] immJ

);

	wire [20 : 0] init;
	assign init={{inst_in[31],{inst_in[19:12],{inst_in[20],inst_in[30:21]}}},1'b0};
	ysyx_24090015_SEXT#(
		.DATA_WIDTH(21),
		.WIDTH(32)		
	) s1(
			.in(init),
			.out(immJ)
		);

	endmodule
	
module ysyx_24090015_immS#(
	parameter WIDTH=32) (

input [WIDTH-1 : 0] inst_in,
output [WIDTH-1 : 0] immS

);

	wire [11 : 0] init;
	assign init={inst_in[31:25],inst_in[11:7]};
	
	ysyx_24090015_SEXT#(
		.DATA_WIDTH(12),
		.WIDTH(32)		
	) s1(
			.in(init),
			.out(immS)
		);

	endmodule
	

	module ysyx_24090015_immB#(
		parameter WIDTH=32) (

input [WIDTH-1 : 0] inst_in,
output [WIDTH-1 : 0] immB

);

	wire [12 : 0] init;
	assign init={inst_in[31],{inst_in[7],{inst_in[30:25],{inst_in[11:8],1'b0}}}};
	
	ysyx_24090015_SEXT#(
		.DATA_WIDTH(13),
		.WIDTH(32)		
	) s1(
			.in(init),
			.out(immB)
		);

	endmodule

	

module ysyx_24090015_TYPE#(
	parameter WIDTH=32) (
    input clock,
    input [WIDTH-1:0] inst,
    output reg [3:0] inst_type
);

localparam   R = 1;
localparam  II = 2;
localparam  IJ = 3;
localparam  IS = 4;
localparam  IC = 5;
localparam  S  = 6;
localparam  B  = 7;
localparam  U  = 8;
localparam  J  = 9;
    always @(*) begin 
        case (inst[6:0])
						7'b0010111: inst_type = U;
                        7'b0110111: inst_type = U;
						7'b1101111: inst_type = J;
                        7'b1100111: inst_type = IJ;//jalr
						7'b1100011: inst_type = B;
						7'b0000011: inst_type = IS;//lb,lh,lw,lbu,lhu
						7'b0100011: inst_type = S;						
						7'b0010011: inst_type = II; // I=2
						7'b0110011: inst_type = R ;
						//7'b0001111: inst_type = IC;
						7'b1110011: inst_type = IC;
						
            default: inst_type = 0;
        endcase
    end
endmodule

 


`timescale 1ns/1ns

module ysyx_25080202#(
  parameter DATAWIDTH=32,
  parameter ADDRWIDTH=32
  ) (
    input clock,
    input reset,


    output         io_ifu_reqValid ,
    output [31:0]  io_ifu_addr     ,
    input          io_ifu_respValid,
    input  [31:0]  io_ifu_rdata    ,
    output         io_lsu_reqValid ,
    output [31:0]  io_lsu_addr     ,
    output [1:0]   io_lsu_size     ,
    output         io_lsu_wen      ,
    output [31:0]  io_lsu_wdata    ,
    output [3:0]   io_lsu_wmask    ,
    input          io_lsu_respValid,
    input  [31:0]  io_lsu_rdata    
);

// assign io_lsu_size = io_lsu_wen ? (io_lsu_wmask[3] ? 2'b10 : (io_lsu_wmask==4'b0011 ? 2'b01 : 2'b00)) : (pmem_rmask[3] ? 2'b10 : (pmem_rmask==4'b0011 ? 2'b01 : 2'b00));

/*
import "DPI-C" context function void read_regs(input string scope);
always@(*) begin 
read_regs($sformatf("%m.reg0"));
end
*/
wire [DATAWIDTH-1 : 0]inst;
reg [31:0]ebreak_ret;


wire [ADDRWIDTH-1:0] pc;
wire [ADDRWIDTH-1:0] dnpc;


wire pmem_work;
wire pmem_ls;
wire [3:0] pmem_wmask;
wire [7:0] pmem_rmask;
wire [DATAWIDTH-1:0]pmem_addr;
wire [DATAWIDTH-1:0]pmem_wdata;
wire [DATAWIDTH-1:0]pmem_rdata;
wire lsu_wvalid;


ysyx_24090015_IFU #(
    .DATAWIDTH(DATAWIDTH),
    .ADDRWIDTH(ADDRWIDTH)
) ifu0(
    .clock(clock),
    .reset(reset),
    .dnpc(dnpc),
    .pc(pc),
    .inst(inst),

    .ifu_reqValid(io_ifu_reqValid),
    .ifu_raddr(io_ifu_addr),
    .ifu_rdata(io_ifu_rdata),
    .ifu_respValid(io_ifu_respValid),

    .lsu_work(pmem_work),
    .lsu_respValid(io_lsu_respValid)
);





ysyx_24090015_LSU #(
    .DATAWIDTH(DATAWIDTH),
    .ADDRWIDTH(ADDRWIDTH)
) lsu0(
    .clock(clock),
    .reset(reset),
    .LSU_work(pmem_work && io_ifu_respValid),
    .ls(pmem_ls),
    .addr(pmem_addr),
    .sdata(pmem_wdata),
    .ldata(pmem_rdata),
    .storge_mask(pmem_wmask),
    .wvalid(lsu_wvalid),


    .lsu_reqValid(io_lsu_reqValid),
    .lsu_addr(io_lsu_addr),
    .lsu_wen(io_lsu_wen),
    .lsu_wdata(io_lsu_wdata),
    .lsu_wmask(io_lsu_wmask),
    .lsu_respValid(io_lsu_respValid),
    .lsu_rdata(io_lsu_rdata)
);

// ysyx_24090015_SRAM sram0(
//     .clock(clock),
//     .reset(reset),
//     .ifu_reqValid(ifu_reqValid),
//     .ifu_respValid(ifu_respValid),
//     .io_ifu_addr(io_ifu_addr),
//     .ifu_rdata(ifu_rdata),
//     .lsu_reqValid(lsu_reqValid),
//     .lsu_wen(lsu_wen),
//     .lsu_addr(lsu_addr),
//     .lsu_wdata(lsu_wdata),
//     .lsu_wmask(lsu_wmask),
//     .lsu_respValid(lsu_respValid),
//     .lsu_rdata(lsu_rdata)
// );

    // 信号声明
    // wire [DATAWIDTH-1:0] inst;

    wire [DATAWIDTH-1:0] imm;
    wire [DATAWIDTH-1:0] rd_wdata;
    wire [DATAWIDTH-1:0] src1;
    wire [DATAWIDTH-1:0] src2;

    wire [4:0] rd;
    wire [4:0] rs1;
    wire [4:0] rs2;
   
    wire wen;
    wire ren1;
    wire ren2;
    wire pwen;



    wire [DATAWIDTH-1:0]csr_rdata;
    wire [DATAWIDTH-1:0]csr_wdata0;
    wire [DATAWIDTH-1:0]csr_wdata1;
    wire  csr_wen;

// assign ren1=ebreak(inst);
// assign hit_good_or_bad=src1;



    // IDU实例化
    ysyx_24090015_IDU #(
        .WIDTH(32)
    ) idu0(    
        .clock(clock),
        .inst_in(inst),

        .imm(imm),
        .ren1(ren1),
				.rs1(rs1),
        .ren2(ren2),
				.rs2(rs2),
				.valid(valid),
				.pwen(pwen),
        .wen(wen),
        .csr_wen(csr_wen),
				.rd(rd)

    );

    // EXU实例化
    ysyx_24090015_EXU#(
        .DATAWIDTH(DATAWIDTH)
    ) exu0(
        .clock(clock),
        .reset(reset),

        .inst_in(inst),
        .lsu_wvalid(lsu_wvalid),
        .imm(imm),

        .src1(src1),
        .src2(src2),
        .rd_wdata(rd_wdata),

		.pc(io_ifu_addr),
        .dnpc(dnpc),

        .pmem_work(pmem_work),
        .pmem_ls(pmem_ls),
        .pmem_rdata(pmem_rdata),
        .pmem_addr(pmem_addr),
        .pmem_wdata(pmem_wdata),
		.pmem_wmask(pmem_wmask),
        // .pmem_rmask(pmem_rmask),
        .pmem_size(io_lsu_size),

        .csr_rdata(csr_rdata),
        .csr_wdata0(csr_wdata0),
        .csr_wdata1(csr_wdata1)

    );

    // 寄存器堆实例化
    ysyx_24090015_RegisterFile #(
        .ADDR_WIDTH(4),
        .DATA_WIDTH(DATAWIDTH)
    ) reg0(
        .clock(clock),
		.reset(reset),
        .wdata(rd_wdata),
        .waddr(rd[3:0]),
        .wen(wen && ((io_ifu_respValid && !io_lsu_reqValid) || (io_lsu_respValid && pmem_ls == 1))) ,
        .ren1(ren1),
        .ren2(ren2),
        .raddr1(rs1[3:0]),
        .raddr2(rs2[3:0]),
        .rdata1(src1),
       .rdata2(src2)
    );

    //特殊状态寄存器组例化
    ysyx_24090015_CSR_RegFiles #(
        .DATAWIDTH(DATAWIDTH),       // 指定数据宽度为 32 位
        .IMM_WIDTH(12),       // 指定立即数宽度为 12 位
        .CSR_ADDR_WIDTH(7)    // 指定 CSR 地址宽度为 2 位
    ) csr_regfiles_instance (
        .clock(clock),            // 连接时钟信号
        .reset(reset),
        .wen(csr_wen),
        .imm(imm[11:0]),      // 连接 imm 输入
        .wdata0(csr_wdata0),  // 连接 wdata 输入
        .wdata1(csr_wdata1),  // 连接 wdata 输入
        .rdata(csr_rdata)  // 连接 rdata 输出
    );
/*
		export "DPI-C" function read_wire;

		function automatic int read_wire(input int sec);
			if(sec==1)return wen_control;
			else if (sec==2)return rd;
			else if (sec==3)return rd_wdata;
			else return 0;
		endfunction
	*/	

		
	// ysyx_24090015_pmem #(
	// .WIDTH(WIDTH)
	// ) pmem0(
	// 	//.clock(clock),
	// 	.valid(valid_control),
	// 	.wen(pwen_control),
	// 	.wmask(wmask),
	// 	.raddr(pmem_raddr),
	// 	.waddr(pmem_waddr),
	// 	.wdata(pmem_wdata),
	// 	.rdata(pmem_rdata)
	// 	);



// reg ren1_control,ren2_control,pwen_control,valid_control,wen_control;


  //   ysyx_24090015_control_unit control_unit0(
	// 	.clock(clock),

  //   .ren1(ren1),
	// 	.ren2(ren2),
	// 	.pwen(pwen),
	// 	.wen(wen),
	// 	.valid(valid),

	// 	.ren1_out(ren1_control),
	// 	.ren2_out(ren2_control),
	// 	.pwen_out(pwen_control),
	// 	.wen_out(wen_control),
	// 	.valid_out(valid_control)
	// );
endmodule



// `timescale 1ns/1ns

// module ysyx_24090015#(
//   parameter DATAWIDTH=32,
//   parameter ADDRWIDTH=32
//   ) (
//     input clock,
//     input reset,


//     output         io_ifu_reqValid ,
//     output [31:0]  io_ifu_addr     ,
//     input          io_ifu_respValid,
//     input  [31:0]  io_ifu_rdata    ,
//     output         io_lsu_reqValid ,
//     output [31:0]  io_lsu_addr     ,
//     output [1:0]   io_lsu_size     ,
//     output         io_lsu_wen      ,
//     output [31:0]  io_lsu_wdata    ,
//     output [3:0]   io_lsu_wmask    ,
//     input          io_lsu_respValid,
//     input  [31:0]  io_lsu_rdata    
// );

// // assign io_lsu_size = io_lsu_wen ? (io_lsu_wmask[3] ? 2'b10 : (io_lsu_wmask==4'b0011 ? 2'b01 : 2'b00)) : (pmem_rmask[3] ? 2'b10 : (pmem_rmask==4'b0011 ? 2'b01 : 2'b00));

// /*
// import "DPI-C" context function void read_regs(input string scope);
// always@(*) begin 
// read_regs($sformatf("%m.reg0"));
// end
// */
// wire [DATAWIDTH-1 : 0]inst;
// reg [31:0]ebreak_ret;


// // wire [ADDRWIDTH-1:0] pc;
// wire [ADDRWIDTH-1:0] dnpc;


// wire pmem_work;
// wire pmem_ls;
// wire [7:0] pmem_wmask;
// wire [7:0] pmem_rmask;
// wire [DATAWIDTH-1:0]pmem_addr;
// wire [DATAWIDTH-1:0]pmem_wdata;
// wire [DATAWIDTH-1:0]pmem_rdata;
// wire lsu_wvalid;


// ysyx_24090015_IFU #(
//     .DATAWIDTH(DATAWIDTH),
//     .ADDRWIDTH(DATAWIDTH)
// ) ifu0(
//     .clock(clock),
//     .reset(reset),
//     .dnpc(dnpc),
//     .pc(pc),
//     .inst(inst),

//     .ifu_reqValid(io_ifu_reqValid),
//     .ifu_raddr(io_ifu_addr),
//     .ifu_rdata(io_ifu_rdata),
//     .ifu_respValid(io_ifu_respValid),

//     .lsu_work(pmem_work),
//     .lsu_respValid(io_lsu_respValid)
// );





// ysyx_24090015_LSU #(
//     .DATAWIDTH(DATAWIDTH),
//     .ADDRWIDTH(DATAWIDTH)
// ) lsu0(
//     .clock(clock),
//     .reset(reset),
//     .LSU_work(pmem_work && io_ifu_respValid),
//     .ls(pmem_ls),
//     .addr(pmem_addr),
//     .sdata(pmem_wdata),
//     .ldata(pmem_rdata),
//     .storge_mask(pmem_wmask),
//     .wvalid(lsu_wvalid),


//     .lsu_reqValid(io_lsu_reqValid),
//     .lsu_addr(io_lsu_addr),
//     .lsu_wen(io_lsu_wen),
//     .lsu_wdata(io_lsu_wdata),
//     .lsu_wmask(io_lsu_wmask),
//     .lsu_respValid(io_lsu_respValid),
//     .lsu_rdata(io_lsu_rdata)
// );

// // ysyx_24090015_SRAM sram0(
// //     .clock(clock),
// //     .reset(reset),
// //     .ifu_reqValid(ifu_reqValid),
// //     .ifu_respValid(ifu_respValid),
// //     .io_ifu_addr(io_ifu_addr),
// //     .ifu_rdata(ifu_rdata),
// //     .lsu_reqValid(lsu_reqValid),
// //     .lsu_wen(lsu_wen),
// //     .lsu_addr(lsu_addr),
// //     .lsu_wdata(lsu_wdata),
// //     .lsu_wmask(lsu_wmask),
// //     .lsu_respValid(lsu_respValid),
// //     .lsu_rdata(lsu_rdata)
// // );

//     // 信号声明
//     // wire [DATAWIDTH-1:0] inst;

//     wire [DATAWIDTH-1:0] imm;
//     wire [DATAWIDTH-1:0] rd_wdata;
//     wire [DATAWIDTH-1:0] src1;
//     wire [DATAWIDTH-1:0] src2;

//     wire [4:0] rd;
//     wire [4:0] rs1;
//     wire [4:0] rs2;
   
//     wire wen;
//     wire ren1;
//     wire ren2;
//     wire pwen;



//     wire [DATAWIDTH-1:0]csr_rdata;
//     wire [DATAWIDTH-1:0]csr_wdata0;
//     wire [DATAWIDTH-1:0]csr_wdata1;
//     wire  csr_wen;

// // assign ren1=ebreak(inst);
// // assign hit_good_or_bad=src1;



//     // IDU实例化
//     ysyx_24090015_IDU #(
//         .WIDTH(32)
//     ) idu0(    
//         .clock(clock),
//         .inst_in(inst),

//         .imm(imm),
//         .ren1(ren1),
// 				.rs1(rs1),
//         .ren2(ren2),
// 				.rs2(rs2),
// 				.valid(valid),
// 				.pwen(pwen),
//         .wen(wen),
//         .csr_wen(csr_wen),
// 				.rd(rd)

//     );

//     // EXU实例化
//     ysyx_24090015_EXU#(
//         .DATAWIDTH(DATAWIDTH)
//     ) exu0(
//         .clock(clock),
//         .reset(reset),

//         .inst_in(inst),
//         .lsu_wvalid(lsu_wvalid),
//         .imm(imm),

//         .src1(src1),
//         .src2(src2),
//         .rd_wdata(rd_wdata),

// 		.pc(io_ifu_addr),
//         .dnpc(dnpc),

//         .pmem_work(pmem_work),
//         .pmem_ls(pmem_ls),
//         .pmem_rdata(pmem_rdata),
//         .pmem_addr(pmem_addr),
//         .pmem_wdata(pmem_wdata),
// 		.pmem_wmask(pmem_wmask),
//         // .pmem_rmask(pmem_rmask),
//         .pmem_size(io_lsu_size),

//         .csr_rdata(csr_rdata),
//         .csr_wdata0(csr_wdata0),
//         .csr_wdata1(csr_wdata1)

//     );

//     // 寄存器堆实例化
//     ysyx_24090015_RegisterFile #(
//         .ADDR_WIDTH(4),
//         .DATA_WIDTH(DATAWIDTH)
//     ) reg0(
//         .clock(clock),
//         .wdata(rd_wdata),
//         .waddr(rd),
//         .wen(wen && ((io_ifu_respValid && !io_lsu_reqValid) || (io_lsu_respValid && pmem_ls == 1))) ,
//         .ren1(ren1),
//         .ren2(ren2),
//         .raddr1(rs1),
//         .raddr2(rs2),
//         .rdata1(src1),
//        .rdata2(src2)
//     );

//     //特殊状态寄存器组例化
//     ysyx_24090015_CSR_RegFiles #(
//         .DATAWIDTH(DATAWIDTH),       // 指定数据宽度为 32 位
//         .IMM_WIDTH(12),       // 指定立即数宽度为 12 位
//         .CSR_ADDR_WIDTH(7)    // 指定 CSR 地址宽度为 2 位
//     ) csr_regfiles_instance (
//         .clock(clock),            // 连接时钟信号
//         .reset(reset),
//         .wen(csr_wen),
//         .imm(imm[11:0]),      // 连接 imm 输入
//         .wdata0(csr_wdata0),  // 连接 wdata 输入
//         .wdata1(csr_wdata1),  // 连接 wdata 输入
//         .rdata(csr_rdata)  // 连接 rdata 输出
//     );
// /*
// 		export "DPI-C" function read_wire;

// 		function automatic int read_wire(input int sec);
// 			if(sec==1)return wen_control;
// 			else if (sec==2)return rd;
// 			else if (sec==3)return rd_wdata;
// 			else return 0;
// 		endfunction
// 	*/	

		
// 	// ysyx_24090015_pmem #(
// 	// .WIDTH(WIDTH)
// 	// ) pmem0(
// 	// 	//.clock(clock),
// 	// 	.valid(valid_control),
// 	// 	.wen(pwen_control),
// 	// 	.wmask(wmask),
// 	// 	.raddr(pmem_raddr),
// 	// 	.waddr(pmem_waddr),
// 	// 	.wdata(pmem_wdata),
// 	// 	.rdata(pmem_rdata)
// 	// 	);



// // reg ren1_control,ren2_control,pwen_control,valid_control,wen_control;


//   //   ysyx_24090015_control_unit control_unit0(
// 	// 	.clock(clock),

//   //   .ren1(ren1),
// 	// 	.ren2(ren2),
// 	// 	.pwen(pwen),
// 	// 	.wen(wen),
// 	// 	.valid(valid),

// 	// 	.ren1_out(ren1_control),
// 	// 	.ren2_out(ren2_control),
// 	// 	.pwen_out(pwen_control),
// 	// 	.wen_out(wen_control),
// 	// 	.valid_out(valid_control)
// 	// );
// endmodule
