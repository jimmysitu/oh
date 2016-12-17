# Siaminer Makefile

BIN  = ${PWD}/../bin
HDL  = ${PWD}/../hdl
TV2V = ${BIN}/tv2v.py
WAVE ?= NONE

miner: hdl dv
	cd build;iverilog -D${WAVE} -DFAST_SIM -DVECTORS=2 -s tb_siaminer -o tb_siaminer.vvp *.v

core: hdl dv
	cd build;iverilog -D${WAVE} -DVECTORS=2 -s tb_siacore -o tb_siacore.vvp *.v

dv:
	cp *.v ./build/.
	cp *.vh ./build/.
	-mkdir ./build/tests
	cp -rf ./tests/*.dat ./build/tests/.
	cd build;emacs --batch -l ${BIN}/verilog-mode.el tb_*.v -f verilog-batch-auto

hdl:
	-mkdir build
	${TV2V} -i ${HDL}/load.tv -o ./build/load.v
	${TV2V} -i ${HDL}/siacore.tv -o ./build/siacore.v
	cp ../hdl/*.v ./build/.
	cd build;emacs --batch -l ${BIN}/verilog-mode.el *.v -f verilog-batch-auto

sim_core: core
	./build/tb_siacore.vvp

sim_miner: miner
	./build/tb_siaminer.vvp

clean:
	rm -rf build
