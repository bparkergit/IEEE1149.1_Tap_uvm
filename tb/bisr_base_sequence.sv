// ───────────────────────────────────────────────
//   BASE SEQUENCE
// ───────────────────────────────────────────────
class bisr_base_sequence extends uvm_sequence #(bisr_seq_item);

  `uvm_object_utils(bisr_base_sequence)

  function new(string name = "bisr_base_sequence");
        super.new(name);
    endfunction

    task body();
        bisr_seq_item item;
            item = bisr_seq_item::type_id::create("item");
      
      // start the test
      
      // write IR
      begin
  	 	start_item(item); 
        assert(item.randomize() with {
          wr_ir==1'b1;
          wr_dr==1'b0;
          rd_dr==1'b0;
          instr==4'b0010; });
        
        `uvm_info("SEQ", $sformatf("Write IR: instr=%4b", item.instr), UVM_MEDIUM) 
        
    	finish_item(item);
      end
      
      // write DR
      begin
  	 	start_item(item); 
        assert(item.randomize() with {
          wr_dr==1'b1;
          wr_ir==1'b0;
          rd_dr==1'b0; 
          data==32'h1; });
        
        `uvm_info("SEQ", $sformatf("Write DR: data=%8h", item.data), UVM_MEDIUM) 
        
    	finish_item(item);
      end  

      // read DR
      begin
  	 	start_item(item); 
        assert(item.randomize() with {
          wr_dr==1'b1;
          wr_ir==1'b0;
          rd_dr==1'b1; });
        
        `uvm_info("SEQ", $sformatf("Read DR: instr=%4b data=%8h", item.instr, item.data), UVM_MEDIUM) 
        
    	finish_item(item);
      end  
      
    endtask

endclass
