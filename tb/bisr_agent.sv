// ───────────────────────────────────────────────
//   AGENT
// ───────────────────────────────────────────────
class bisr_agent extends uvm_agent;

  `uvm_component_utils(bisr_agent)

    bisr_sequencer  sqr;
    bisr_driver     drv;
	bisr_monitor mon;
  	bisr_coverage coverage;
  
  uvm_analysis_port #(bisr_seq_item) ap;
  
    uvm_active_passive_enum is_active = UVM_ACTIVE;

  function new(string name = "bisr_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sqr = bisr_sequencer::type_id::create("sqr", this);
        if (is_active == UVM_ACTIVE) begin
        	drv = bisr_driver::type_id::create("drv", this);
        end
        mon = bisr_monitor::type_id::create("mon", this);
        ap = new("ap", this);
        coverage  = bisr_coverage::type_id::create("coverage", this);
      
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
      
         mon.ap.connect(ap);
         mon.ap.connect(coverage.analysis_export);

      
    endfunction

endclass

