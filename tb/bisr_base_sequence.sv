// ───────────────────────────────────────────────
//   BASE SEQUENCE
// ───────────────────────────────────────────────
class bisr_base_sequence extends uvm_sequence #(bisr_seq_item);

  `uvm_object_utils(bisr_base_sequence)

        logic [7:0] saved_addr;
      
  
  function new(string name = "bisr_base_sequence");
        super.new(name);
    endfunction

    task body();
        bisr_seq_item item;
            item = bisr_seq_item::type_id::create("item");

      // start the test
      
      // write IR (SIB)
      begin
  	 	start_item(item); 
        assert(item.randomize() with {
          wr_ir==1'b1;
          wr_dr==1'b0;
          rd_dr==1'b0;
          instr==4'b0011; });
        
        `uvm_info("SEQ", $sformatf("Write IR: instr=%4b", item.instr), UVM_MEDIUM) 
        
    	finish_item(item);
      end
      
      // write DR (SIB)
      begin
  	 	start_item(item); 
        assert(item.randomize() with {
          wr_dr==1'b1;
          wr_ir==1'b0;
          rd_dr==1'b0; 
          dr_bits==2; 
          data_tdi[1]==1'b1;  // [sib_b], [sib_m]
          data_tdi[0]==1'b0;
          });   
        
        `uvm_info("SEQ", $sformatf("Write DR: data=%0b", item.data_tdi), UVM_MEDIUM) 
        
    	finish_item(item);
      end  
     

      
      // random writes
      repeat(8) begin
      
      // write DR
      begin
  	 	start_item(item); 
        assert(item.randomize() with {
          wr_dr==1'b1;
          wr_ir==1'b0;
          rd_dr==1'b0; 
          dr_bits==18;
          data_tdi[17] == 1'b1;
          data_tdi[0] == 1'b0;
        })else 
        `uvm_fatal(get_type_name(), "Randomize failed for DR write")
          
          saved_addr = item.data_tdi[16:9];
              
        `uvm_info("SEQ", $sformatf("Write DR: addr=%h data=%h", item.data_tdi[16:9], item.data_tdi[8:1]), UVM_MEDIUM) 
        
    	finish_item(item);
      end  
      
      // read DR
      begin
  	 	start_item(item); 
        assert(item.randomize() with {
          wr_dr==1'b1;
          wr_ir==1'b0;
          rd_dr==1'b1; 
          dr_bits==18;
          data_tdi[17] == 1'b1;
          data_tdi[0] == 1'b0;
          data_tdi[16:9] == saved_addr;
        })else 
          `uvm_fatal(get_type_name(), "Randomize failed for DR read")
          
        `uvm_info("SEQ", $sformatf("Read DR: addr=%h", item.data_tdi[16:9]), UVM_MEDIUM) 
        
    	finish_item(item);
      end 
        
      end
      
      
    endtask

endclass
