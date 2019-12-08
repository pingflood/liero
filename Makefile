#
# Liero for the RetroFW
#
# by pingflood; 2019
#

TARGET = liero/liero.dge

CHAINPREFIX := /opt/mipsel-RetroFW-linux-uclibc
CROSS_COMPILE := $(CHAINPREFIX)/usr/bin/mipsel-linux-

CC  := $(CROSS_COMPILE)gcc
CXX := $(CROSS_COMPILE)g++

SYSROOT := $(shell $(CC) --print-sysroot)
SDL_CFLAGS := $(shell $(SYSROOT)/usr/bin/sdl-config --cflags)
SDL_LIBS := $(shell $(SYSROOT)/usr/bin/sdl-config --libs)

MACHINE := $(shell $(CXX) -dumpmachine)
CXXFLAGS := -ffunction-sections -ffast-math -fsingle-precision-constant
CXXFLAGS += $(SDL_CFLAGS)
LIBS := $(SDL_LIBS) -lSDL_mixer

OUTDIR		:= liero
DATADIR		:= data
OPKDIR		:= opk_data
RELEASEDIR	:= /tmp/liero-opk

ifneq ($(filter mipsel-gcw0-%,$(MACHINE)),)
CXXFLAGS += -mips32 -mtune=mips32 -mbranch-likely -G0
endif

CXXFLAGS += -Wextra -Wall
ifdef DEBUG
	CXXFLAGS += -ggdb3
	OUTDIR := $(OUTDIR)-debug
else
	CXXFLAGS += -O2 -fomit-frame-pointer
	LDFLAGS += -s
endif

CXXFLAGS += -DHOME_DIR -DPLATFORM_GCW0

BINDIR := $(OUTDIR)
OBJDIR := .

SRC := $(wildcard src/*.cpp)
OBJ := $(SRC:%.cpp=$(OBJDIR)/%.o)

.PHONY: all clean

all : $(SRC) $(TARGET)

$(TARGET): $(OBJ) | $(BINDIR)
	$(CXX) $(LDFLAGS) $(OBJ) $(LIBS) -o $@

$(OBJ): $(OBJDIR)/%.o: %.cpp | $(OBJDIR)
	$(CXX) $(CXXFLAGS) $(INCLUDE) -c $< -o $@

$(BINDIR) $(OBJDIR):
	mkdir -p $@

ipk: all
	@rm -rf /tmp/.liero-ipk/ && mkdir -p /tmp/.liero-ipk/root/home/retrofw/games/liero /tmp/.liero-ipk/root/home/retrofw/apps/gmenu2x/sections/games
	@cp -r liero/liero.elf liero/liero.png liero/data /tmp/.liero-ipk/root/home/retrofw/games/liero
	@cp liero/liero.lnk /tmp/.liero-ipk/root/home/retrofw/apps/gmenu2x/sections/games
	@sed "s/^Version:.*/Version: $$(date +%Y%m%d)/" liero/control > /tmp/.liero-ipk/control
	@cp liero/conffiles /tmp/.liero-ipk/
	@tar --owner=0 --group=0 -czvf /tmp/.liero-ipk/control.tar.gz -C /tmp/.liero-ipk/ control conffiles
	@tar --owner=0 --group=0 -czvf /tmp/.liero-ipk/data.tar.gz -C /tmp/.liero-ipk/root/ .
	@echo 2.0 > /tmp/.liero-ipk/debian-binary
	@ar r liero/liero.ipk /tmp/.liero-ipk/control.tar.gz /tmp/.liero-ipk/data.tar.gz /tmp/.liero-ipk/debian-binary

opk: all
	@mksquashfs \
	liero/default.retrofw.desktop \
	liero/liero.dge \
	liero/liero.png \
	liero/data \
	liero/liero.opk \
	-all-root -noappend -no-exports -no-xattrs

clean:
	rm -rf src/*.o $(TARGET)
	rm -rf $(RELEASEDIR)
