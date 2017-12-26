Each folder has the top module till that folder and a testbench till that module (if exists).
System consists of complete : FPGA1, FPGA2, DHCP, Switch
The System module is in itself a testbench connecting all four entities. The switch file is completed but not fully tested yet.

**The FPGA1, FPGA2 and DHCP folders are complete in itself with appropriate testbenches with testing through file unterface between each one of them among them.**
Output from first entity goes to a txt file(not created) and reads from another txt file. To transfer data from one entity to another one has to copy the contents of the output txt file of one to the inpit txt file of another the names for which are in the corresponding testbenches.
