CC     ?= cc
CFLAGS ?= -O2 -Wall -Wextra

# Shared headers (the node format lives in the repo-root include/). TTP_HOSTED
# selects node.h's libc-backed FILE* serialization (the OS build omits it).
CPPFLAGS ?= -I../../include -DTTP_HOSTED

BUILD ?= build

SRCS := $(wildcard *.c)
BIN  := $(BUILD)/ttpc
IMG  := $(BUILD)/ttpos.img

# Boot-flow disassembly to re-assemble (override to point elsewhere).
BOOT_FLOW ?= ../os/boot_flow.txt

all: $(BIN)

$(BUILD):
	mkdir -p $(BUILD)

$(BIN): $(SRCS) | $(BUILD)
	$(CC) $(CFLAGS) $(CPPFLAGS) $(SRCS) -o $@

# Re-assemble the boot-flow disassembly into a bootable disk image.
$(IMG): $(BIN) $(BOOT_FLOW) | $(BUILD)
	$(BIN) $(BOOT_FLOW) $@

img: $(IMG)

test: $(IMG)
	qemu-system-x86_64 -drive format=raw,file=$(IMG)

clean:
	rm -rf $(BUILD)

.PHONY: all img test clean
