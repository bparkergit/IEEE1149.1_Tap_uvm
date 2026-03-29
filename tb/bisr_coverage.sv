// ───────────────────────────────────────────────
//   COVERAGE
// ───────────────────────────────────────────────
class bisr_coverage extends uvm_subscriber #(bisr_seq_item);
  `uvm_component_utils(bisr_coverage)

       covergroup cg_transaction with function sample(
    bit       wr_en,
    bit       rd_en,
    bit [7:0] wr_data = 8'h00,   // optional, default if not passed
    bit [7:0] rd_data = 8'h00,
    bit       full,
    bit       empty
  );
        coverpoint wr_en {
          bins low   = {0};
          bins high  = {1};
        }

        coverpoint rd_en {
          bins low  = {0};
          bins high  = {1};
        }
        
        coverpoint full {
     	 bins full    = {1};
      	 bins not_full= {0};
    	}

    	coverpoint empty {
      	bins empty    = {1};
      	bins not_empty= {0};
    	}

    cross wr_en, full;
    cross rd_en, empty;
 
      endgroup
        
        
  function new(string name="bisr_coverage", uvm_component parent);
          super.new(name, parent);
          cg_transaction = new();
          cg_transaction.set_inst_name("cg_transaction");  // helps reporting
        endfunction
        
      // This is called automatically via analysis_export
  virtual function void write(bisr_seq_item t);
    // debug
      `uvm_info("COV_SAMPLE", $sformatf("Sampling txn: wr_en=%0b rd_en=%0b full=%0b empty=%0b", 
                                     t.wr_en, t.rd_en, t.full, t.empty), UVM_MEDIUM)
    // Pass relevant fields to the covergroup's sample function
    cg_transaction.sample(
      .wr_en   (t.wr_en),
      .rd_en   (t.rd_en),
      .wr_data (t.wr_data),
      .rd_data (t.rd_data),
      .full    (t.full),
      .empty   (t.empty)
    );
  endfunction

      endclass
        
