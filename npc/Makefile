all:
	@echo "Write this Makefile by your self."
WORK_DIR  = $(shell pwd)
VSRCS = $(shell find ./vsrc -name "*.v" -or -name "*.sv")
VSRCS += $(shell find ../ysyxSoC/perip -name "*.v")
VSRCS += ../ysyxSoC/ready-to-run/D-stage/ysyxSoCFull.v
CSRCS = $(shell find ./csrc -name "*.c" -or -name "*.cc" -or -name "*.cpp")
INC_PATH += $(WORK_DIR)/csrc/include
INCFLAGS += $(addprefix -I, $(INC_PATH))

INC_PATH_VER += ../ysyxSoC/perip/uart16550/rtl ../ysyxSoC/perip/spi/rtl
INCFLAGS_VER += $(foreach v,$(INC_PATH_VER),-I$(v))

#CXXFLAGS += $(shell llvm-config --cxxflags) -fPIE
CXXFLAGS += $(INCFLAGS) #-DTRACE #I/usr/lib/llvm-14/include -std=c++14   -fno-exceptions -D_GNU_SOURCE -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS

TOP_NAME = ysyxSoCFull#-------------------top_name
EX_CMD := $(addprefix ./obj_dir/V, $(TOP_NAME))

LIBS += -lreadline $(shell llvm-config --libs)
#LIBS += $(shell llvm-config --libs)


LIB := $(foreach a,$(LIBS),-LDFLAGS $(a))
FLAGS := $(foreach b,$(CXXFLAGS),-CFLAGS $(b))
sim:
	
# 	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@echo $(VSRCS)
	verilator --trace --cc --exe --build --autoflush $(INCFLAGS_VER) --timescale "1ns/1ns" --no-timing --Wno-WIDTHEXPAND\
    --top-module $(TOP_NAME) \
    $(CSRCS) $(VSRCS) \
	$(LIB) $(FLAGS)
 
 IMG ?= /home/zjt/npc-test-ci/ysyx-workbench/am-kernels/tests/cpu-tests/build/dummy-minirv-npc.bin

run: sim
	$(EX_CMD) $(ARGS) $(IMG)
	#rm -rf obj_dir
	#rm waveform.vcd

IVL_TOP_MODULE ?= tb
IVL_SRC_VER = ysyx_25080202.v
IVL_SRC_TB = $(shell find ./testbench -name "*.v")
IVL_SRC  = $(IVL_SRC_VER) $(IVL_SRC_TB)
VVP_FILE   = sim.vvp
VCD_FILE   = wave.vcd
IVL_FLAGS  = -g2012 -Wall -Winfloop -DCOSIM_XCHECK  # -g2012启用Verilog 2012标准，-Wall开启警告
VVP_FLAGS  = -v -n  # -v显示详细仿真日志，-n启用四值仿真严格检查
IMG_HEX    = test.hex 
LOAD_ADDR ?= 0x00000000
OBJCOPY    = riscv64-linux-gnu-objcopy
sim-iverilog:
	@$(OBJCOPY) -I binary -O verilog --adjust-vma=$(LOAD_ADDR) $(IMG) $(IMG_HEX)
	@echo "========== 编译Verilog文件（启用四值仿真）=========="
	@echo $(IVL_SRC)
	iverilog $(IVL_FLAGS) -s $(IVL_TOP_MODULE) -o $(VVP_FILE) $(IVL_SRC)
	@echo "编译完成，生成文件：$(VVP_FILE)"
	@echo "========== 执行四值仿真 =========="
	vvp $(VVP_FLAGS) $(VVP_FILE)
# 	@echo "仿真完成，生成波形文件：$(VCD_FILE)"
# 	@echo "========== 打开波形文件 =========="
# 	gtkwave $(VCD_FILE) 
 
clean:
	rm -rf obj_dir
	rm -rf $(VVP_FILE) $(VCD_FILE) *.vcd *.vvp *.log 
 
include ../Makefile
