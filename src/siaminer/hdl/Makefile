# Generate all RTL files

all:
	mkdir build
	../bin/tv2v.py -i load.tv -o build/load.v
	../bin/tv2v.py -i siacore.tv -o build/siacore.v
	cp *.v build/.
	cd build;emacs --batch -l ../bin/verilog-mode.el siacore.v -f verilog-batch-auto
	cd build;emacs --batch -l ../bin/verilog-mode.el load.v -f verilog-batch-auto
	cd build;emacs --batch -l ../bin/verilog-mode.el mix.v -f verilog-batch-auto
	cd build;emacs --batch -l ../bin/verilog-mode.el compare.v -f verilog-batch-auto

clean:
	rm -rf build
