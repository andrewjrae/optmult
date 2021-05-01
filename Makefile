##
# Optimized Xilinx Softlogic Multiplier
#
# @file
# @version 0.1
#

ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
BUILD_DIR = $(ROOT_DIR)/test_dir
TEST_NAME = mult_tb

M ?= 8
N ?= 8
U ?= 0
END ?= 0

DEFINES = -GM_W=$(M) -GN_W=$(N)

ifeq ($(U), 1)
	DEFINES += -D_UNSIGNED
endif

ifneq ($(END), 0)
	DEFINES += -DEND=$(END)
endif

run: compile
	cd $(BUILD_DIR) && ./V$(TEST_NAME)

compile:
	mkdir -p $(BUILD_DIR)
	verilator -sv -Wno-fatal \
		$(DEFINES) \
		--cc $(TEST_NAME).v \
		--exe $(TEST_NAME).cpp  \
		--Mdir $(BUILD_DIR)
	make -C $(BUILD_DIR) -f V$(TEST_NAME).mk V$(TEST_NAME)

clean:
	rm -rf $(BUILD_DIR)

# end
