// ───────────────────────────────────────────────
//   MONITOR WR
// ───────────────────────────────────────────────
class bisr_monitor extends uvm_monitor;
  `uvm_component_utils(bisr_write_monitor)
        
  uvm_analysis_port #(bisr_seq_item) ap;
         virtual bisr_if.MONITOR vif;
  
  function new(string name = "bisr_monitor", uvm_component parent);
          super.new(name,parent);
        endfunction
        
        function void build_phase(uvm_phase phase);
          ap = new("ap",this);
          
          if (!uvm_config_db#(virtual bisr_if.MONITOR)::get(this,"","vif",vif)) 			begin
 		     `uvm_fatal("NOVIF", "Virtual interface not set")
 			end
        endfunction
        
        task run_phase(uvm_phase phase);
          bisr_seq_item txn;
          
          forever begin
            @(vif.cb_mon);

         	 txn = bisr_seq_item::type_id::create("txn");
          	 txn.wr_en = vif.cb_mon.wr_en;
             txn.rd_en = vif.cb_mon.rd_en;
             txn.wr_data = vif.cb_mon.wr_data;
             txn.empty = vif.cb_mon.empty;
             txn.full = vif.cb_mon.full;
              
         	 ap.write(txn);
              
              `uvm_info("WRITE_MON", $sformatf("Write observed: %0h", txn.wr_data), UVM_LOW);

          end
        endtask
        
        
        
endclass
