// ───────────────────────────────────────────────
//   INTERFACE
// ───────────────────────────────────────────────
interface bisr_if (
    input logic TCK,
    input logic TRST
);

    logic              TMS;
    logic			   TDI;
    logic              TDO;


  clocking cb_drv @(posedge TCK);
        output TRST;
        output TMS;
    	output TDI;
        input  TDO;
    endclocking

  clocking cb_mon @(posedge TCK);
        input TRST;
        input TMS;
    	input TDI;
        output  TDO;
    endclocking

    modport DUT (
      	input TCK,
        input TRST,
        input TMS,
    	input TDI,
        output  TDO
    );

    modport DRIVER (
        clocking cb_drv,
        input TRST
    );

    modport MONITOR (
        clocking cb_mon,
        input TRST
    );

endinterface
