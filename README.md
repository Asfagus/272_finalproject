272_finalproject

In this project, I created a Network Switch based on the specification given, and connected it to four permutation engine devices that I have created in a previous project. The switch takes in data via an interface using modports for input and output, and gives it to four boxes instantiated in the switch. 
A box is a module that connects the individual signals of respective interface to the peripherals inside.
Inside each box are four 1600-bit memories, a Network on Chip (NOC) Bus, and a permutation module. 
The switch also returns the data back from these four boxes to the testbench. 
For doing the return path, arbitration is required.
For this design, a Priority Arbiter is implemented, but other arbitration can be easily implemented based on requirement.
Each box is also attached to a fifo in the switch to store any data while the other box has the bus.

Thus, the Switch succesfully creates a communication channel for the permutation engine.
