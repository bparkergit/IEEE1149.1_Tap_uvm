// ───────────────────────────────────────────────
//   SEQUENCE ITEM
// ───────────────────────────────────────────────
class bisr_seq_item extends uvm_sequence_item;

    rand bit         wr_en;
    rand bit [7:0]   wr_data;
    rand bit         rd_en;

    bit [7:0]        rd_data;
    bit              full;
    bit              empty;

    constraint valid_wr_rd {
        !(wr_en && rd_en);
    }

  `uvm_object_utils(bisr_seq_item)

  function new(string name = "bisr_seq_item");
        super.new(name);
    endfunction

endclass
