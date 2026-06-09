CC     ?= cc
CFLAGS ?= -O2 -Wall -Wextra

BUILD ?= build

SRCS := $(wildcard *.c)
BIN  := $(BUILD)/ttpc

all: $(BIN)

$(BUILD):
	mkdir -p $(BUILD)

$(BIN): $(SRCS) | $(BUILD)
	$(CC) $(CFLAGS) $(SRCS) -o $@

clean:
	rm -rf $(BUILD)
