#!/usr/bin/env python
# Script to convert hex to MIF
# ChatGPT

import argparse
import math

parser = argparse.ArgumentParser(description="Usage: create_mif.py [options]")
parser.add_argument("-v", "--verbose", action="store_true", help="Run verbosely")
parser.add_argument("-d", "--depth", type=int, help="Memory depth")
parser.add_argument("-w", "--width", type=int, default=8, help="Memory width (bits)")
parser.add_argument("-o", "--offset", type=int, default=0, help="First byte to use of the binary input file (default = 0)")
parser.add_argument("-i", "--increment", type=int, default=1, help="How many bytes to the next byte (default = 1)")
parser.add_argument("filename", type=str, help="Input binary file")
args = parser.parse_args()

start_offset = args.offset
increment = args.increment

with open(args.filename, "rb") as f:
    f.seek(start_offset)
    bytes = list(f.read())[start_offset::increment]

depth = args.depth or len(bytes)
width = args.width

bytes_per_word = (width + 7) // 8
nr_addr_bits = math.ceil(math.log2(depth))

if args.verbose:
    print(f"output format : {format}")
    print(f"depth         : {depth}")
    print(f"width         : {width}")
    print(f"bytes per word: {bytes_per_word}")
    print(f"start offset  : {start_offset}")
    print(f"increment     : {increment}")

print("-- Created by create_mif.py")
print(f"DEPTH         = {depth};")
print(f"WIDTH         = {width};")
print("ADDRESS_RADIX = UNS;")
print("DATA_RADIX    = HEX;")
print("CONTENT")
print("BEGIN")

# extra silly thanks chatgpt
addr_fmt_string = f"{{0:#08}}"
addr_fmt_string_1 = f"{{1:#08}}"
data_fmt_string = f"{{1:0{bytes_per_word*2}X}}"
data_fmt_string_2 = f"{{2:0{bytes_per_word*2}X}}"

fmt_string = f"{addr_fmt_string}: {data_fmt_string};"

words = [bytes[i:i+bytes_per_word] for i in range(0, len(bytes), bytes_per_word)]
for addr, w in enumerate(words):
    value = 0
    w.reverse()
    for b in w:        
        value = value * 256 + b
    print(fmt_string.format(addr, value))

if len(words) < depth:
    print(f"[{addr_fmt_string}..{addr_fmt_string_1}]: {data_fmt_string_2};".format(len(words), depth-1, 0))

print("END;")
print()
