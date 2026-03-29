// ───────────────────────────────────────────────
//   SEQUENCER
// ───────────────────────────────────────────────
class bisr_sequencer extends uvm_sequencer #(bisr_seq_item);

  `uvm_component_utils(bisr_sequencer)

  function new(string name = "bisr_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass
