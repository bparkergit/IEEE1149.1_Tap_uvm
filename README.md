# IEEE1149.1_Tap_uvm BISR/MBIST verification
UVM environment for verification of BISR controller through ijtag.

![OIP](https://github.com/user-attachments/assets/a4343a7a-46e6-44cc-9dd0-ca15a100779c)


### Coverpoints

- `wr_en` 
- `rd_en`    
- `full`  
- `empty`
- `cross wr_en,full`
- `cross rd_en,empty`

    
Functional coverage:


## Structure
- `rtl/`       : DUT (chip_top.sv)
- `tb/`        : UVM components (interface, package, top, tests)
- `sim/`       : Scripts/Makefile for running simulations

## Status
- [ ] DUT complete
- [ ] Basic UVM env
- [ ] Coverage & scoreboard

Tools: Questa/EDA Playground
