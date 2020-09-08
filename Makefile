###################################################################
# Project:                                                        #
# Description:      RTL Synthesis with Quartus - Makefile         #
#                                                                 #
# Template written by Abraham J. Ruiz R.                          #
#   https://github.com/m4j0rt0m/rtl-develop-template-syn-quartus  #
###################################################################

MKFILE_PATH           = $(abspath $(firstword $(MAKEFILE_LIST)))
TOP_DIR               = $(shell dirname $(MKFILE_PATH))

### directories ###
OUTPUT_DIR            = $(TOP_DIR)/build
SCRIPTS_DIR           = $(TOP_DIR)/scripts

### makefile includes ###
include $(SCRIPTS_DIR)/funct.mk
include $(SCRIPTS_DIR)/default.mk

### project configuration ###
PROJECT              ?=
TOP_MODULE           ?=
RTL_SYN_CLK_SRC      ?=

### sources wildcards ###
VERILOG_SRC          ?=
VERILOG_HEADERS      ?=
PACKAGE_SRC          ?=
MEM_SRC              ?=
RTL_PATHS            ?=
BUILD_DIR             = $(OUTPUT_DIR)/$(TOP_MODULE)

### synthesis device configuration ###
RTL_SYN_Q_TARGET     := $(or $(RTL_SYN_Q_TARGET),$(DEFAULT_RTL_SYN_Q_TARGET))
RTL_SYN_Q_DEVICE     := $(or $(RTL_SYN_Q_DEVICE),$(DEFAULT_RTL_SYN_Q_DEVICE))
RTL_SYN_Q_CLK_PERIOD := $(or $(RTL_SYN_Q_CLK_PERIOD),$(DEFAULT_RTL_SYN_Q_CLK_PERIOD))

### quartus synthesis cli ###
QUARTUS_SH            = quartus_sh

### rtl quartus synthesis objects ###
Q_PROJECT_FILES       = $(BUILD_DIR)/$(PROJECT).qpf $(BUILD_DIR)/$(PROJECT).qsf
Q_CREATE_PROJECT_TCL  = $(BUILD_DIR)/quartus_create_project_$(PROJECT).tcl
Q_PROJECT_SDC         = $(BUILD_DIR)/quartus_project_$(PROJECT).sdc
Q_VIRTUAL_PINS_TCL    = $(SCRIPTS_DIR)/virtual_pins_all_pins.tcl
Q_MAP_RPT             = $(BUILD_DIR)/$(PROJECT).map.rpt
Q_FIT_RPT             = $(BUILD_DIR)/$(PROJECT).fit.rpt
Q_ASM_RPT             = $(BUILD_DIR)/$(PROJECT).asm.rpt
Q_STA_RPT             = $(BUILD_DIR)/$(PROJECT).sta.rpt
RTL_OBJS              = $(VERILOG_SRC) $(PACKAGE_SRC) $(VERILOG_HEADERS) $(MEM_SRC)
RPT_OBJS              = $(Q_MAP_RPT) $(Q_FIT_RPT) $(Q_ASM_RPT) $(Q_STA_RPT)

#H# all                     : Run the synthesis
all: rtl-synth

#H# veritedium              : Run veritedium AUTO features
veritedium:
	@$(foreach SRC,$(VERILOG_SRC),$(call veritedium-command,$(SRC)))

#H# rtl-synth               : Run RTL synthesis with Quartus
rtl-synth: print-rtl-srcs $(RPT_OBJS)

#H# quartus-create-project  : Create the Quartus project
quartus-create-project: veritedium $(Q_PROJECT_FILES)
	@rm -rf $(Q_PROJECT_FILES);\
	mkdir -p $(BUILD_DIR);\
	cd $(BUILD_DIR);\
	$(QUARTUS_SH) -t $(Q_CREATE_PROJECT_TCL)

$(Q_PROJECT_FILES): $(Q_PROJECT_SDC) $(Q_CREATE_PROJECT_TCL)

$(RPT_OBJS): $(RTL_OBJS)
	$(MAKE) quartus-create-project
	@cd $(BUILD_DIR);\
	$(QUARTUS_SH) --flow compile $(PROJECT)

$(Q_PROJECT_SDC):
	@mkdir -p $(BUILD_DIR);\
	echo "# Automatically created by the Makefile #" > $(Q_PROJECT_SDC);\
	for csrc in $(RTL_SYN_CLK_SRC);\
	do\
		echo "create_clock -name $${csrc} -period $(RTL_SYN_Q_CLK_PERIOD) [get_ports {$${csrc}}]" >> $(Q_PROJECT_SDC);\
	done;\
	echo "derive_clock_uncertainty" >> $(Q_PROJECT_SDC)

$(Q_CREATE_PROJECT_TCL):
	@mkdir -p $(BUILD_DIR);\
	echo "# Automatically created by the Makefile #" > $(Q_CREATE_PROJECT_TCL);\
	echo "set project_name $(PROJECT)" >> $(Q_CREATE_PROJECT_TCL);\
	echo "if [catch {project_open $(PROJECT)}] {project_new $(PROJECT)}" >> $(Q_CREATE_PROJECT_TCL);\
	echo "set_global_assignment -name FAMILY \"$(RTL_SYN_Q_TARGET)\"" >> $(Q_CREATE_PROJECT_TCL);\
	echo "set_global_assignment -name DEVICE \"$(RTL_SYN_Q_DEVICE)\"" >> $(Q_CREATE_PROJECT_TCL);\
	echo "set_global_assignment -name TOP_LEVEL_ENTITY $(TOP_MODULE)" >> $(Q_CREATE_PROJECT_TCL);\
	echo "set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 256" >> $(Q_CREATE_PROJECT_TCL);\
	for spath in $(RTL_PATHS);\
	do\
		echo "set_global_assignment -name SEARCH_PATH $${spath}" >> $(Q_CREATE_PROJECT_TCL);\
	done;\
	for vsrc in $(VERILOG_SRC);\
	do\
		echo "set_global_assignment -name SOURCE_FILE $${vsrc}" >> $(Q_CREATE_PROJECT_TCL);\
	done;\
	for vheader in $(VERILOG_HEADERS);\
	do\
		echo "set_global_assignment -name SOURCE_FILE $${vheader}" >> $(Q_CREATE_PROJECT_TCL);\
	done;\
	for psrc in $(PACKAGE_SRC);\
	do\
		echo "set_global_assignment -name SOURCE_FILE $${psrc}" >> $(Q_CREATE_PROJECT_TCL);\
	done;\
	for psrc in $(MEM_SRC);\
	do\
		echo "set_global_assignment -name SOURCE_FILE $${msrc}" >> $(Q_CREATE_PROJECT_TCL);\
	done;\
	echo "set_global_assignment -name SDC_FILE $(Q_PROJECT_SDC)" >> $(Q_CREATE_PROJECT_TCL);\
	cat "$(Q_VIRTUAL_PINS_TCL)" >> $(Q_CREATE_PROJECT_TCL);\
	echo "make_all_pins_virtual $(RTL_SYN_CLK_SRC)" >> $(Q_CREATE_PROJECT_TCL);\
	echo "project_close" >> $(Q_CREATE_PROJECT_TCL);\
	echo "qexit -success" >> $(Q_CREATE_PROJECT_TCL)

#H# print-rtl-srcs          : Print RTL sources
print-rtl-srcs:
	$(call print-srcs-command)

#H# clean                   : Clean build directory
clean:
	rm -rf build/*

#H# help                    : Display help
help: Makefile
	@echo -e "\nRTL Synthesis Help - Quartus\n"
	@sed -n 's/^#H#//p' $<
	@echo ""

.PHONY: all veritedium rtl-synth quartus-create-project print-rtl-srcs clean help
