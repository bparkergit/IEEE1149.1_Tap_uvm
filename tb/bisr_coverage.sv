// ───────────────────────────────────────────────
//   COVERAGE
// ───────────────────────────────────────────────
class bisr_coverage extends uvm_subscriber #(bisr_seq_item);
  `uvm_component_utils(bisr_coverage)

       covergroup cg_transaction with function sample(
    bit       wr_ir,
    bit       wr_dr,
    bit [7:0] instr = 8'h00, 
    bit       rd_dr
  );
        coverpoint wr_ir {
          bins low   = {0};
          bins high  = {1};
        }

        coverpoint wr_dr {
          bins low  = {0};
          bins high  = {1};
        }
        
        coverpoint rd_dr {
          bins low  = {0};
          bins high = {1};
    	}

    	coverpoint instr;

 
      endgroup
        
        
  function new(string name="bisr_coverage", uvm_component parent);
          super.new(name, parent);
          cg_transaction = new();
          cg_transaction.set_inst_name("cg_transaction");  // helps reporting
        endfunction
        
      // This is called automatically via analysis_export
  virtual function void write(bisr_seq_item t);
    // debug
    `uvm_info("COV_SAMPLE", $sformatf("Sampling txn: wr_ir=%0b wr_dr=%0b rd_rd=%0b instr=%0b", 
                                     t.wr_ir, t.wr_dr, t.rd_dr, t.instr), UVM_MEDIUM)
    // Pass relevant fields to the covergroup's sample function
    cg_transaction.sample(
      .wr_ir   (t.wr_ir),
      .wr_dr   (t.wr_dr),
      .rd_dr (t.rd_dr),
      .instr (t.instr)
    );
  endfunction

      endclass
        
