#Generated by Edalize
ifndef MODEL_TECH
$(error Environment variable MODEL_TECH was not found. It should be set to <modelsim install path>/bin)
endif

CC ?= gcc
CFLAGS   := -fPIC -fno-stack-protector -g -std=c99
CXXFLAGS := -fPIC -fno-stack-protector -g

LD ?= ld
LDFLAGS := -shared -E

#Try to determine if ModelSim is 32- or 64-bit.
#To manually override, set the environment MTI_VCO_MODE to 32 or 64
ifeq ($(findstring 64, $(shell $(MODEL_TECH)/../vco)),)
CFLAGS   += -m32
CXXFLAGS += -m32
LDFLAGS  += -melf_i386
endif

RM ?= rm
INCS := -I$(MODEL_TECH)/../include

VSIM ?= $(MODEL_TECH)/vsim

TOPLEVEL      := ucsbece154b_top_tb
VPI_MODULES   :=
PARAMETERS    ?=
PLUSARGS      ?=
VSIM_OPTIONS  ?= -voptargs=+acc=lprn
EXTRA_OPTIONS ?= $(VSIM_OPTIONS) $(addprefix -g,$(PARAMETERS)) $(addprefix +,$(PLUSARGS))
RTL           := text.dat ucsbece154b_alu.v ucsbece154b_controller.v ucsbece154b_datapath.v ucsbece154_dmem.v ucsbece154_imem.v ucsbece154b_riscv_pipe.v ucsbece154b_rf.v ucsbece154b_top.v ucsbece154b_top_tb.v ucsbece154b_defines.vh

all: clean run $(VPI_MODULES) $(RTL)

run: work $(VPI_MODULES) $(RTL)
	$(VSIM) -do "run -all; quit -code [expr [coverage attribute -name TESTSTATUS -concise] >= 2 ? [coverage attribute -name TESTSTATUS -concise] : 0]; exit" -c $(addprefix -pli ,$(VPI_MODULES)) $(EXTRA_OPTIONS) $(TOPLEVEL)

run-gui: work $(VPI_MODULES) $(RTL)
	$(VSIM) -gui $(addprefix -pli ,$(VPI_MODULES)) $(EXTRA_OPTIONS) $(TOPLEVEL)

work: $(RTL)
	$(VSIM) -c -do "do sim.tcl; exit"

clean:
	rm -rf work transcript dump.fst vsim.wlf
