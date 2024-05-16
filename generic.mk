BUILD_DIR=build
BSC_FLAGS=--aggressive-conditions --show-schedule -p +:hw/core:hw/mem:hw/network:hw/top:hw/util -vdir $(BUILD_DIR) -bdir $(BUILD_DIR) -simdir $(BUILD_DIR) -info-dir $(BUILD_DIR) -o 

BSV_FILES=$(shell find hw -name "*.bsv" -type f)

$(BUILD_DIR)/$(BINARY_NAME): $(BSV_FILES)
	mkdir -p $(BUILD_DIR)
	bsc $(BSC_FLAGS) $@ -sim -g mk$(BINARY_NAME) -u ./hw/top/$(BINARY_NAME).bsv
	bsc $(BSC_FLAGS) $@ -sim -e mk$(BINARY_NAME)

$(BUILD_DIR)/$(BINARY_NAME).v:
	mkdir -p $(BUILD_DIR)
	bsc -remove-dollar $(BSC_FLAGS) $(BINARY_NAME) -verilog -g mk$(BINARY_NAME)Sized -u ./hw/top/$(BINARY_NAME).bsv