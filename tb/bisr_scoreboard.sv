// ───────────────────────────────────────────────
//   SCOREBOARD
// ───────────────────────────────────────────────
      
      class bisr_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(bisr_scoreboard)

        
        // implementation port  
        // Means this component implements the corresponding write function.
        uvm_analysis_imp #(bisr_seq_item, bisr_scoreboard) imp;

        
        virtual bisr_if vif;
        bit [31:0] model_q[$];
        bit [31:0] expected;
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
              if (model_q.size() == 0) 
                `uvm_error("MODEL_UNDERFLOW","Model underflow")
              else 
                begin
                   expected = model_q.pop_front();

                  if (txn.data_tdo[31:16] !== expected[31:16]) 
                    `uvm_error("DATA_MISMATCH",$sformatf("Expected %b Got %b", expected[31:16], txn.data_tdo[31:16]))
                  else 
                    `uvm_info("MATCH",$sformatf("Matched %b", txn.data_tdo[31:16]), UVM_LOW);
             
                end
          
         
          if(txn.wr_dr && txn.dr_bits > 2) // hard coded only save non sib writes
              if (model_q.size() == DEPTH) 
      			`uvm_error("MODEL_OVERFLOW","Model overflow")
              else begin
                model_q.push_back(txn.data_tdi);
              end


            
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
