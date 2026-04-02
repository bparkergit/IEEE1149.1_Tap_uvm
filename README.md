# IEEE1149.1_Tap_uvm BISR/MBIST verification
UVM environment for verification of BISR controlled through ijtag featuring variable length dr chain with control for open/closed segment access.

![OIP](https://github.com/user-attachments/assets/a4343a7a-46e6-44cc-9dd0-ca15a100779c)


### Coverpoints

- `wr_ir` 
- `wr_dr`    
- `rd_dr`  
- `instr`
- `addr`
- `rd_data`
- `sib_bisr X sib_mbist`
    
Functional coverage:
88.88%

## Structure
- `rtl/`       : DUT (chip_top.sv)
- `tb/`        : UVM components (interface, package, top, tests)
- `sim/`       : Scripts/Makefile for running simulations

## Status
- [X] DUT complete
- [X] Basic UVM env
- [X] Coverage & scoreboard
- [ ] BISR repair

Tools: Questa/EDA Playground
