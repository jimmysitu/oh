
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

BIN  = ${PWD}/../bin
HDL  = ${PWD}/../hdl
TV2V = ${BIN}/tv2v.py

.PHONY: all hdl clean


all: $(M_DEPS) hdl
	source /cad/Xilinx/Vivado/2015.2/settings64.sh; \
		export PATH=$$PATH:/cad/Xilinx/Vivado/2015.2/bin;\
		./build.sh

hdl:
	-mkdir build
	cp ${HDL}/*.v ./build/.
	cd build;emacs --batch -l ${BIN}/verilog-mode.el *.v -f verilog-batch-auto
	cd build;emacs --batch -l ${BIN}/verilog-mode.el uartloop.v -f verilog-batch-auto

clean:
	rm -rf build
	rm -rf $(M_FLIST)
