# Siaminer Makefile

BIN  = ${PWD}/../bin
HDL  = ${PWD}/../hdl
TV2V = ${BIN}/tv2v.py
WAVE ?= NONE
WFON ?= 0
FREQ ?= CLK20M

real_uartloop: hdl dv
	cd build;iverilog -D${WAVE} -D${FREQ} -DVECTORS=3 -s tb_uartloop -o tb_uartloop.vvp *.v

uartloop: hdl dv
	cd build;iverilog -D${WAVE} -DFAST_SIM -DVECTORS=3 -s tb_uartloop -o tb_uartloop.vvp *.v

dv:
	cp *.v ./build/.
	cp *.vh ./build/.
	-mkdir ./build/tests
	cp -rf ./tests/*.dat ./build/tests/.
	cd build;emacs --batch -l ${BIN}/verilog-mode.el tb_*.v -f verilog-batch-auto

hdl:
	-mkdir build
	cp ../hdl/*.v ./build/.
	cd build;emacs --batch -l ${BIN}/verilog-mode.el *.v -f verilog-batch-auto
	cd build;emacs --batch -l ${BIN}/verilog-mode.el uartloop.v -f verilog-batch-auto

sim_uartloop: uartloop
	export IVERILOG_DUMPER=fst;time vvp -l sim.log ./build/tb_uartloop.vvp +wfon=${WFON}

sim_real_uartloop: real_uartloop
	export IVERILOG_DUMPER=fst;time vvp -l sim.log ./build/tb_uartloop.vvp +wfon=${WFON}

see:
	fst2vcd waveform.fst | vcd2fsdb

clean:
	rm -rf build
