// ───────────────────────────────────────────────
//   COVERAGE
// ───────────────────────────────────────────────
class bisr_coverage extends uvm_subscriber #(bisr_seq_item);
  `uvm_component_utils(bisr_coverage)

       covergroup cg_transaction with function sample(
    bit       	wr_ir,
    bit       	wr_dr,
    bit [7:0] 	instr = 8'h00,
    bit [31:0] 	data_tdo = 32'h00000000,
    int			dr_bits,
    bit       	rd_dr
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

         coverpoint data_tdo[31] {
          bins sib_bisr_closed  = {0};
          bins sib_bisr_open = {1};
         }
         
         coverpoint data_tdo[32-dr_bits] {
          bins sib_mbist_closed  = {0};
          bins sib_mbist_open = {1};
         }
         
         rd_data : coverpoint data_tdo[22:15] iff (dr_bits == 18) {
           bins low   = {[8'h00 : 8'h3F]};
           bins mid1  = {[8'h40 : 8'h7F]};
           bins mid2  = {[8'h80 : 8'hBF]};
           bins high  = {[8'hC0 : 8'hFF]};
        // fewer bins for better readability
        // bins range[16] = {[0:$]};     // distribute into 16 auto bins

    }
                  
         addr : coverpoint data_tdo[30:23] iff (dr_bits == 18) {
           bins low   = {[8'h00 : 8'h3F]};
           bins mid1  = {[8'h40 : 8'h7F]};
           bins mid2  = {[8'h80 : 8'hBF]};
           bins high  = {[8'hC0 : 8'hFF]};   
        // fewer bins for better readability
        // bins range[16] = {[0:$]};     // distribute into 16 auto bins

    }
         
         
         coverpoint instr {
           bins IR_SIB = {4'b0011};
         }

 
      endgroup
        
        
  function new(string name="bisr_coverage", uvm_component parent);
          super.new(name, parent);
          cg_transaction = new();
          cg_transaction.set_inst_name("cg_transaction");  // helps reporting
        endfunction
        
      // This is called automatically via analysis_export
  virtual function void write(bisr_seq_item t);
    // debug
   // `uvm_info("COV_SAMPLE", $sformatf("Sampling txn: wr_ir=%0b wr_dr=%0b rd_rd=%0b instr=%4b", 
  //                                   t.wr_ir, t.wr_dr, t.rd_dr, t.instr), UVM_MEDIUM)
  
    // Pass relevant fields to the covergroup's sample function
    cg_transaction.sample(
      .wr_ir   (t.wr_ir),
      .wr_dr   (t.wr_dr),
      .rd_dr (t.rd_dr),
      .instr (t.instr),
      .data_tdo (t.data_tdo),
      .dr_bits (t.dr_bits)
    );
  endfunction

      endclass
        
