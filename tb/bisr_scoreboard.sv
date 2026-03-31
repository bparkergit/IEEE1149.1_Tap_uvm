// ───────────────────────────────────────────────
//   SCOREBOARD
// ───────────────────────────────────────────────
      
      class bisr_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(bisr_scoreboard)

        
        // implementation port  
        // Means this component implements the corresponding write function.
        uvm_analysis_imp #(bisr_seq_item, bisr_scoreboard) imp;

        
        virtual bisr_if vif;
        bit [7:0] model_q[$];
        bit [7:0] expected;
  		int DEPTH = 16;
        
      
        function new(string name = "bisr_scoreboard",uvm_component parent);    
          super.new(name,parent);
        endfunction
        
        
        function void build_phase(uvm_phase phase);
          imp = new("imp",this);
          // we need to access the VIF to detect reset
          
          if (!uvm_config_db#(virtual bisr_if)::get(this,"","vif",vif)) 				`uvm_fatal("NO_VIF","No vif");
          
        endfunction

        
        // write function implementation    
        
        function void write(bisr_seq_item txn); 
                      
          if(txn.rd_dr) 
              if (model_q.size() == 0) begin
                `uvm_error("MODEL_UNDERFLOW","Model underflow")
              end
              else 
                begin
                   expected = model_q.pop_front();

                  if (txn.data_tdo !== expected) 
                    `uvm_error("DATA_MISMATCH",$sformatf("Expected %8h Got %8h", expected, txn.data_tdo))
                  else 
                    `uvm_info("MATCH",$sformatf("Matched %8h", txn.data_tdo), UVM_LOW);
             s
                end
          
          if(txn.wr_dr) 
              if (model_q.size() == DEPTH) 
      			`uvm_error("MODEL_OVERFLOW","Model overflow")
              else 
                model_q.push_back(txn.data_tdi);


            
        endfunction

        

        
        
          // Reset handling
  task run_phase(uvm_phase phase);
    forever begin
      @(negedge vif.TRST);
      model_q.delete();
      `uvm_info("RESET","Scoreboard model cleared", UVM_LOW)
    end
  endtask
        
        
      endclass
