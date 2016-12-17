#!/usr/bin/python3

from mako.template import Template
from optparse import OptionParser


if __name__ == "__main__":

    parser = OptionParser()
    parser.add_option("-i", "--input",
            dest="tvFileName",
            help="Verilog template file")
    parser.add_option("-o", "--output",
            dest="vFileName",
            help="Verilog output file")

    (opts, args) = parser.parse_args()

    try:
        opts.tvFileName
    except:
        print("tvFileName error")

    try:
        opts.vFileName
    except:
        print("vFileName error")

    tv = Template(filename=opts.tvFileName)
    v = open(opts.vFileName, 'w')

    print(tv.render(), file=v)

