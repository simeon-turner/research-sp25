# Research Repo for Zhang CSL SP25

To run any testbench, use the following: fud2 <file_name> --to dat --through verilator -s sim.data=test.data

To run a testbench and output a vcd waves file, use the following: fud2 <file_name>.futil --to vcd --through verilator -s sim.data=test.data > <output_file>.vcd