#For each application you want to build, add a new line such as:
#myApp: source1.o source2.o source3.o
#ALSO, add myApp to the APPS= line
# Be sure to include lib141.o if you wish to use the SendByte, itoa, or other
# functions in lib141.c

lab8-test: lab8-test.o

APPS=lab8-test

##############################################
## You Should Not Need to Modify Below Here ##
##############################################
#
# Change Log:
#	1/18/2012 - Adrian Caulfield - Initial Implementation
#	1/25/2012 - Trevor Bunker - Added the iterative fib program
#
#


.DEFAULT_GOAL := all
all: memhs dis

#setup tool names for xcompile
TARGET=mipsel-unknown-linux-gnu-
CC=$(TARGET)gcc
LD=$(TARGET)ld
AS=$(TARGET)as
OBJDUMP=$(TARGET)objdump

#compile flags
CCOPTS=-mno-embedded-data -fno-pic -fno-delayed-branch
CCFLAGS=-fno-builtin -nodefaultlibs -nostdlib -c -mips1 -mno-abicalls -static -O0

define APP_macro
$1:
	@if [ "`$(OBJDUMP) -t $$^ | grep __start | wc -l`" == "0" ]; then \
	  $(MAKE) --no-print-directory boot.o; \
	  $(LD) -mips1 -T mips.linkscript -n --omagic --nmagic --entry __start -o $$@ boot.o $$^; \
	else \
	  $(LD) -mips1 -T mips.linkscript -n --omagic --nmagic --entry __start -o $$@ $$^; \
	fi
.PHONY: $1.memhs
$1.memhs: $1.inst_rom.memh $1.data_ram0.memh $1.data_ram1.memh $1.data_ram2.memh $1.data_ram3.memh

endef

$(foreach A,$(APPS),$(eval $(call APP_macro,$(A))))

%.o: %.c
	$(CC) $(CCOPTS) $(CCFLAGS) -c -o $@ $<

%.o: %.s
	$(AS) -g -g2 -o $@ $<

dis: $(addsuffix .dis,$(APPS))

memhs: $(addsuffix .memhs,$(APPS))

.PHONY: %.dis
%.dis: %
	$(OBJDUMP) -D $^ > $@


%.spim.s: %.s
	cat $< | grep -Pv "\.file|mdebug.abi32|\.previous|\.type|\.set|\.globl" > $@


.PHONY: clean
clean:
	-@rm $(APPS) *.memh *.dis *.o *.spim.s 

#temp files for generating memh files
%.inst_rom.dump: %
	$(OBJDUMP) -s -j IROM $< --prefix-addresses | grep -Pv "Contents of section|elf32-tradlittlemips" > $@
	
%.data_ram.dump: %
	$(OBJDUMP) -s -j RAM $< --prefix-addresses | grep -Pv "Contents of section|elf32-tradlittlemips" > $@

#create the instruction rom memh file
%.inst_rom.memh: %.inst_rom.dump
	cat $< | awk '{ if (substr($$1,1,3) == "400") { printf("@%.8x %s\n%s\n%s\n%s\n",strtonum("0x" substr($$1,4))/4,$$2,$$3,$$4,$$5) }}' > $@

#create the data rom memh files - we have to split this into four files
%.data_ram0.memh: %.data_ram.dump
	cat $< | awk '{ if (substr($$1,1,4) == "1000") { printf("@%.8x %s\n%s\n%s\n%s\n",strtonum("0x" substr($$1,4))/4,substr($$2,1,2),substr($$3,1,2),substr($$4,1,2),substr($$5,1,2)) }}' > $@

%.data_ram1.memh: %.data_ram.dump
	cat $< | awk '{ if (substr($$1,1,4) == "1000") { printf("@%.8x %s\n%s\n%s\n%s\n",strtonum("0x" substr($$1,4))/4,substr($$2,3,2),substr($$3,3,2),substr($$4,3,2),substr($$5,3,2)) }}' > $@

%.data_ram2.memh: %.data_ram.dump
	cat $< | awk '{ if (substr($$1,1,4) == "1000") { printf("@%.8x %s\n%s\n%s\n%s\n",strtonum("0x" substr($$1,4))/4,substr($$2,5,2),substr($$3,5,2),substr($$4,5,2),substr($$5,5,2)) }}' > $@

%.data_ram3.memh: %.data_ram.dump
	cat $< | awk '{ if (substr($$1,1,4) == "1000") { printf("@%.8x %s\n%s\n%s\n%s\n",strtonum("0x" substr($$1,4))/4,substr($$2,7,2),substr($$3,7,2),substr($$4,7,2),substr($$5,7,2)) }}' > $@



