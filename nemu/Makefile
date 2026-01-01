Nvboard = flase
ifdef Nvboard
# CSRCS += $(SRC_AUTO_BIND)
# SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
# $(SRC_AUTO_BIND): $(NXDC_FILES)
# 	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@
# include $(NVBOARD_HOME)/scripts/nvboard.mk
# INC_PATH += -I$(NVBOARD_HOME)/usr/include/
# INC_PATH ?=
# CXXFLAGS += -DVL_DEBUG=1 -Og -ggdb3
endif

MODULE = ysyxSoCFull
SOC_HOME = $(abspath ./../ysyxSoC)
NVBOARD_HOME = $(abspath ./../nvboard)
BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
NXDC_FILES = constr/top.nxdc

CSRCS = $(shell find $(abspath ./csrc) -name "*.c")
# CSRCS += $(SRC_AUTO_BIND)
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
VSRCS += $(shell find $(abspath ./vsrc/*) -name "*.v") $(SOC_SOURCE)
SOC_SOURCE = $(shell find $(abspath $(SOC_HOME)/perip) -name "*.v") \
    $(SOC_HOME)/ready-to-run/D-stage/ysyxSoCFull.v

INC_PATH = -I$(NPC_HOME)/include/ #指定了头文件的搜索路径
INC_PATH += -I$(SOC_HOME)/perip/uart16550/rtl -I$(SOC_HOME)/perip/spi/rtl
# INC_PATH += -I$(NVBOARD_HOME)/usr/include/
# INC_PATH ?=

VERILATOR_FLAG =--prof-c --prof-cfuncs --prof-exec --autoflush --timescale "1ns/1ns" --no-timing
VERILATOR_FLAG += -MMD --build -cc -O3 --x-assign fast --x-initial fast --noassert

# CXXFLAGS += -DVL_DEBUG=1 -Og -ggdb3

#定义需要链接的库
LDFLAGS = -lreadline   # link the <readline> lib
LDFLAGS += -ldl #-fsanitize=address       # link the <dlfcn> lib
LDFLAGS += $(shell llvm-config-11 --libs)
CXXFLAGS += $(shell llvm-config-11 --cxxflags) -fPIE

# constraint file
# SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
# $(SRC_AUTO_BIND): $(NXDC_FILES)
# 	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# rule for NVBoard
# include $(NVBOARD_HOME)/scripts/nvboard.mk

# ifdef CONFIG_DIFFTEST
DIFF_REF_PATH = $(NEMU_HOME)
# DIFF_REF_SO = $(DIFF_REF_PATH)/build/riscv32-nemu-interpreter-so
# ARGS_DIFF = --diff=$(DIFF_REF_SO)

# .PHONY: $(DIFF_REF_SO)
# $(DIFF_REF_SO):
# 	$(MAKE) -s -C $(DIFF_REF_PATH) 

# endif

#用于打开GTKWave查看波形文件
waves: waveform.vcd
	@echo
	@echo "### WAVES ###"
	gtkwave waveform.vcd


waveform.vcd: ./build/obj_dir/V$(MODULE)
	@echo
	@echo "### SIMULATING ###"
	@./build/obj_dir/V$(MODULE) #+verilator+rand+reset+2


IMG ?=      #loaded by AM Makefile (npc.mk)
override ARGS ?= --log=./log/npc-log.txt
# override ARGS += $(ARGS_DIFF)
BINARY := ./build/obj_dir/V$(MODULE)
NEMU_EXEC := $(BINARY) $(ARGS) $(IMG)

run-env: $(BINARY) $(DIFF_REF_SO)
	mkdir -p ./log

run: run-env
	$(NEMU_EXEC)

gdb: run-env
	gdb -s $(BINARY) --args $(NEMU_EXEC)

build: $(BINARY)

#This builds our simulation executable from the testbench and the converted sources.
#We tell Make to change the working directory to build/obj_dir, 
#use the build file named Valu.mk and build the target named Valu
#----------------------------------------------------------------------------------
./build/obj_dir/V$(MODULE): .stamp.verilate
	@echo
	@echo "### BUILDING SIM ###"
	make -C build/obj_dir -f V$(MODULE).mk V$(MODULE)


verilate: .stamp.verilate

#This converts our .v source to C++ and generates build files 
#for building the simulation executable. 
#We use -Wall to enable all C++ errors, 
#--trace to enable waveform tracing, 
#-cc .v to convert our .v module to C++, 
#and --exe tb_alu.cpp to tell Verilator which file is our C++ testbench.
# -Wno-STMTDLY 避免弹出所有warning
# -Wno-MODDUP 避免“Duplicate declaration”报错
# --top-module $(MODULE) 确定底层模块，否则会将$(VSRCS)中的第一个文件前缀当成顶层模块
#----------------------------------------------------------------------------------
#加入nvboard要加入静态库 $(NVBOARD_ARCHIVE)
.stamp.verilate: $(VSRCS) $(CSRCS)
	@echo
	@echo "### VERILATING ###"
	verilator -Wno-STMTDLY -Wno-MODDUP --trace --top-module $(MODULE) -cc $(VSRCS) \
			  --exe $(CSRCS) $(VERILATOR_FLAG) \
			  $(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) $(INC_PATH) \
			  --Mdir $(OBJ_DIR) --exe -o $(abspath $(BINARY))
	@echo "INC_PATH = $(INC_PATH)"
	@echo "LIBS +=$(LIBS)" >> ./build/obj_dir/V$(MODULE).mk    # to link readline and dlfcn library
# @echo "CXXFLAGS +=$(CXXFLAGS)" >> ./obj_dir/V$(MODULE).mk 
	@touch .stamp.verilate

# INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INC_PATH) -DTOP_NAME="\"V$(MODULE)\""

#Note that there is an aditional make lint target, 
#which calls Verilator with --lint-only. 
#This is useful to quickly parse your Verilog/SystemVerilog source files 
#and check for problems. 
#This can be used to check over your sources even if you’re not using Verilator for simulating.
#----------------------------------------------------------------------------------
#用于进行lint检查，检查Verilog的语法问题
lint: $(MODULE).v
	#-lint-only- 告诉 Verilator 进行 lint 但不生成任何仿真输出
	verilator --lint-only $(MODULE).v

clean:
	rm -rf .stamp.*;
# 	rm -rf ./build/obj_dir
	rm -rf ./obj_dir
	rm -rf waveform.vcd
	rm -rf waveform.fst


.PHONY: default clean lint verilate build gdb run run-env waveform.vcd waves
