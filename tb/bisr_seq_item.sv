// ───────────────────────────────────────────────
//   SEQUENCE ITEM
// ───────────────────────────────────────────────
class bisr_seq_item extends uvm_sequence_item;


    rand bit [8:0]	 instruction;
    rand bit [31:0]	 data;


  `uvm_object_utils(bisr_seq_item)

  function new(string name = "bisr_seq_item");
        super.new(name);
    endfunction

endclass
