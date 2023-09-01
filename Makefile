#===============================================================================
# Config
#-------------------------------------------------------------------------------
VSIM                := iverilog
#VSIM                := verilator

TRACE_DIR           := logs

#TRACE_RF            := 1
TRACE_RF_FILE       := trace_rf.txt
#-----------------------------------------------------------------------------------#
# Format of TRACE_RF_FILE                                                           #
#-----------------------------------------------------------------------------------#
# count pc ir                             | count pc ir                             #
# zero  ra   sp   gp   tp   t0   t1   t2  |  x0   x1   x2   x3   x4   x5   x6   x7  #
#  s0   s1   a0   a1   a2   a3   a4   a5  |  x8   x9   x10  x11  x12  x13  x14  x15 #
#  a6   a7   s2   s3   s4   s5   s6   s7  |  x16  x17  x18  x19  x20  x21  x22  x23 #
#  s8   s9   s10  s11  t3   t4   t5   t6  |  x24  x25  x26  x27  x28  x29  x30  x31 #
#-----------------------------------------------------------------------------------#

DIFF_TRACE_RF       := 1

TRACE_VCD           := 1
TRACE_VCD_FILE      := dump.vcd

#TRACE_FST           := 1
TRACE_FST_FILE      := dump.fst

#===============================================================================
### riscv-tests/isa
ifdef ISA
MEMSIZE             := 8*1024
TIMEOUT             := 1000
TRACE_BEGIN         := 0
TRACE_END           := 1000
endif

### coremark
ifdef COREMARK
MEMSIZE             := 32*1024
TIMEOUT             := 2000000
TRACE_BEGIN         := 0
TRACE_END           := 1000000
endif

SIMRV               := simrv
SIMRV_TRACE_RF_FILE  = simrv_$(TRACE_RF_FILE)
SIMRV_TRACE_BEGIN   := 0
SIMRV_TRACE_END     := 1000000

#===============================================================================
# Sources
#-------------------------------------------------------------------------------
src_dir             := src
srcs                += $(wildcard $(src_dir)/*.v)
srcs                += $(wildcard $(src_dir)/rvcore/*.v)
srcs                += $(wildcard $(src_dir)/ram/*.v)
inc_dir             += $(src_dir)
inc_dir             += $(src_dir)/rvcore
inc_dir             += $(src_dir)/ram

sim_src_dir         := sim
sim_srcs            += $(wildcard $(sim_src_dir)/*.v)
cxx_sim_srcs        += $(wildcard $(sim_src_dir)/*.cpp)

prog_dir            := prog
isa_dir             := $(prog_dir)/riscv-tests
coremark_dir        := $(prog_dir)/coremark

#===============================================================================
# Common to Verilator and Icarus Verilog
#-------------------------------------------------------------------------------
TOP_MODULE          := top
CLK                 := clk

#-------------------------------------------------------------------------------
VLFLAGS             += $(addprefix -I,$(inc_dir))

#-------------------------------------------------------------------------------
VLFLAGS             += -DMEMFILE=\"$(MEMFILE)\"
VLFLAGS             += -DMEMSIZE=\($(MEMSIZE)\)

VLFLAGS             += -DNO_IP

#-------------------------------------------------------------------------------
ifdef TIMEOUT
VLFLAGS             += -DTIMEOUT=$(TIMEOUT)
endif

ifdef TRACE_RF
TRACE_DIR           ?= logs
TRACE_RF_FILE       ?= trace_rf.txt
TRACE_BEGIN         ?= 0
TRACE_END           ?= 1000000
VLFLAGS             += -DTRACE_RF=1
VLFLAGS             += -DTRACE_RF_FILE=\"$(TRACE_DIR)/$(TRACE_RF_FILE)\"
VLFLAGS             += -DTRACE_BEGIN=$(TRACE_BEGIN)
VLFLAGS             += -DTRACE_END=$(TRACE_END)
endif

ifdef TRACE_VCD
TRACE_VCD_FILE      ?= dump.vcd
VLFLAGS             += -DTRACE_VCD=1
VLFLAGS             += -DTRACE_VCD_FILE=\"$(TRACE_VCD_FILE)\"
endif

ifdef TRACE_FST
TRACE_FST_FILE      ?= dump.fst
VLFLAGS             += -DTRACE_FST=1
VLFLAGS             += -DTRACE_FST_FILE=\"$(TRACE_FST_FILE)\"
endif

#===============================================================================
# Verilator
#-------------------------------------------------------------------------------
VERILATOR           := verilator
VL_TOPNAME          := Vtop

#-------------------------------------------------------------------------------
VERILATOR_FLAGS     += --cc
VERILATOR_FLAGS     += --exe
VERILATOR_FLAGS     += --build

VERILATOR_FLAGS     += --top-module $(TOP_MODULE)
VERILATOR_FLAGS     += --clk $(CLK)
VERILATOR_FLAGS     += --prefix $(VL_TOPNAME)
VERILATOR_FLAGS     += --x-assign unique
VERILATOR_FLAGS     += --Wno-WIDTH

ifdef TRACE_VCD
VERILATOR_FLAGS     += --trace
endif

ifdef TRACE_FST
VERILATOR_FLAGS     += --trace-fst
endif

VERILATOR_FLAGS     += $(VLFLAGS)

VERILATOR_INPUT     += $(cxx_sim_srcs) $(sim_srcs) $(srcs)

#===============================================================================
# Icarus Verilog
#-------------------------------------------------------------------------------
IVERILOG            := iverilog

IVERILOG_FLAGS      += -s $(TOP_MODULE)
IVERILOG_FLAGS      += -Wall
IVERILOG_FLAGS      += $(VLFLAGS)

IVERILOG_INPUT      += $(sim_srcs) $(srcs)

ifdef TRACE_FST
VVP_FLAGS           += -fst
endif

#===============================================================================
# Build rules
#-------------------------------------------------------------------------------
.PHONY: default build run clean distclean
default: ;

build:
ifeq ($(VSIM), verilator)
	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_INPUT)
endif
ifeq ($(VSIM), iverilog)
	$(IVERILOG) $(IVERILOG_FLAGS) $(IVERILOG_INPUT)
endif

run:
ifeq ($(VSIM), verilator)
	obj_dir/$(VL_TOPNAME)
endif
ifeq ($(VSIM), iverilog)
	vvp a.out $(VVP_FLAGS)
endif

clean:
	rm -f a.out
	rm -rf obj_dir
	rm -rf logs
	rm -f *.vcd *.fst

distclean: clean
	make clean -C prog/riscv-tests --no-print-directory
	make clean -C prog/coremark --no-print-directory

rsltclean:
	@rm -f $(rslt_file)

#===============================================================================
# result
#-------------------------------------------------------------------------------
rslt_file           :=
output              :=

### $(eval $(call result_template, PROGRAM, program, program-list, program_dir))
define result_template
.PHONY: $2 $3
ifdef RSLT
$2: rslt_file := $2_rslt.txt
$2: output    := | tee -a $$(rslt_file)
endif
$2: rsltclean $3
$3: $$(TRACE_DIR)
ifndef DIFF_TRACE_RF
$3:
	@echo $$@ $(VSIM)                                                      $$(output)
	@echo ---------------------------------------------------------------- $$(output)
	@$$(MAKE) build $1=1 MEMFILE="$4/$$@.32.hex" > /dev/null
	@$$(MAKE) run --no-print-directory                                     $$(output)
	@echo                                                                  $$(output)
	@echo                                                                  $$(output)

else # DIFF_TRACE_RF
$3:
	@echo $$@ simrv                                                        $$(output)
	@echo ---------------------------------------------------------------- $$(output)
	@$(SIMRV) -a -m $4/$$@.bin -t $$(SIMRV_TRACE_BEGIN) $$(SIMRV_TRACE_END)
	@mv trace.txt $$(TRACE_DIR)/$$@_$$(SIMRV_TRACE_RF_FILE)
	@echo                                                                  $$(output)
	@echo                                                                  $$(output)

	@echo $$@ $(VSIM)                                                      $$(output)
	@echo ---------------------------------------------------------------- $$(output)
	@$$(MAKE) build $1=1 MEMFILE="$4/$$@.32.hex" TRACE_RF=1 TRACE_RF_FILE=$$@_$$(TRACE_RF_FILE) > /dev/null
	@$$(MAKE) run --no-print-directory                                     $$(output)
	@echo                                                                  $$(output)
	@echo                                                                  $$(output)

	@diff $$(TRACE_DIR)/$$@_$$(SIMRV_TRACE_RF_FILE) $$(TRACE_DIR)/$$@_$$(TRACE_RF_FILE) > $$(TRACE_DIR)/diff.txt
endif # DIFF_TRACE
endef # result_template

$(TRACE_DIR):
	@mkdir -p $(TRACE_DIR)

#===============================================================================
# riscv-tests/isa
#-------------------------------------------------------------------------------
rv32ui_sc_tests := \
	simple \
	add addi sub and andi or ori xor xori \
	sll slli srl srli sra srai slt slti sltiu sltu \
	beq bge bgeu blt bltu bne jal jalr \
	sb sh sw lb lbu lh lhu lw \
	auipc lui

rv32ui_p_tests := $(addprefix rv32ui-p-, $(rv32ui_sc_tests))

.PHONY: $(rv32ui_sc_tests)
$(rv32ui_sc_tests): %: rv32ui-p-%

.PHONY: isa
isa: rv32ui_tests

$(eval $(call result_template,ISA,rv32ui_tests,$(rv32ui_p_tests),$(isa_dir)))

#===============================================================================
# coremark
#-------------------------------------------------------------------------------
cmark               := coremark
$(eval $(call result_template,COREMARK,cmark,$(cmark),$(coremark_dir)))
