
M_DEPS := run.tcl

M_VIVADO := vivado -mode batch -source

M_FLIST := *.cache
M_FLIST += *.data
M_FLIST += *.xpr
M_FLIST += *.log
M_FLIST += *.jou
M_FLIST +=  xgui
M_FLIST += *.runs
M_FLIST += *.srcs
M_FLIST += *.sdk
M_FLIST += *.hw
M_FLIST += *.sim
M_FLIST += .Xil
M_FLIST += parallella.bit.bin
M_FLIST += system_wrapper.bit.bin

.PHONY: all clean

all: $(M_DEPS)
	./build.sh

clean:
	rm -rf $(M_FLIST)
