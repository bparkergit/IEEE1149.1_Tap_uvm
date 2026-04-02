// ───────────────────────────────────────────────
//   MONITOR WR
// ───────────────────────────────────────────────
class bisr_monitor extends uvm_monitor;
  `uvm_component_utils(bisr_monitor)
        
  uvm_analysis_port #(bisr_seq_item) ap;
         virtual bisr_if.MONITOR vif;

     
    
      // TAP states
    typedef enum bit [3:0] {
      TEST_LOGIC_RESET, // 0
      RUN_TEST_IDLE, 	// 1
      SELECT_DR_SCAN,	// 2
      CAPTURE_DR, 		// 3
      SHIFT_DR, 		// 4
      EXIT1_DR, 		// 5
      PAUSE_DR, 		// 6
      EXIT2_DR, 		// 7
      UPDATE_DR,		// 8
      SELECT_IR_SCAN, 	// 9
      CAPTURE_IR, 		// 10
      SHIFT_IR, 		// 11
      EXIT1_IR, 		// 12
      PAUSE_IR, 		// 13
      EXIT2_IR, 		// 14
      UPDATE_IR			// 15
    } tap_state_t;

    tap_state_t state, next_state;
  
  bit [3:0] instr;
  bit [31:0] data_tdi,data_tdo;
  int dr_bits;
  string bin_str;
  
  function new(string name = "bisr_monitor", uvm_component parent);            
    super.new(name,parent);       
  endfunction

            
  function void build_phase(uvm_phase phase);
              ap = new("ap",this);

              if (!uvm_config_db#(virtual bisr_if.MONITOR)::get(this,"","vif",vif)) 					begin
                 `uvm_fatal("NOVIF", "Virtual interface not set")
                end
        
           
  endfunction
  

        
  task run_phase(uvm_phase phase);
          bisr_seq_item txn;
          
          forever begin
            @(vif.cb_mon);
                 

         if(vif.cb_mon.TRST)
                state = TEST_LOGIC_RESET;
            
            if(state == SHIFT_IR && !vif.cb_mon.TMS)
              instr = {vif.cb_mon.TDI,instr[3:1]};


            if(state == EXIT1_IR)
              begin
                txn = bisr_seq_item::type_id::create("txn");
                txn.instr = instr;
                txn.wr_ir = 1'b1;
                txn.wr_dr = 1'b0;
                txn.rd_dr = 1'b0;
                ap.write(txn);     
                
                `uvm_info("MON", $sformatf("Write IR observed: %4b", txn.instr), UVM_LOW);
              end

                        
            if (state == CAPTURE_DR) begin
              data_tdi = '0;
              data_tdo = '0;
              dr_bits = 0;
            end
            else if (state == SHIFT_DR && !vif.cb_mon.TMS) begin
              data_tdi = {vif.cb_mon.TDI,data_tdi[31:1]};
              data_tdo = {vif.cb_mon.TDO,data_tdo[31:1]};
              dr_bits++;
            end
            
            if(state == EXIT1_DR)
              begin
                txn = bisr_seq_item::type_id::create("txn");
                txn.wr_ir = 1'b0;
                txn.wr_dr = 1'b1;
                txn.rd_dr = 1'b1;
                txn.data_tdi = data_tdi;
                txn.data_tdo = data_tdo;
                txn.dr_bits = dr_bits;

                ap.write(txn);     
                
                bin_str = "";

                for (int i = 31; i >= 32-dr_bits; i--) begin
                    bin_str = {bin_str, txn.data_tdi[i] ? "1" : "0"};
                end


                
                `uvm_info("MON", $sformatf("Write DR observed: %0b dr_bits: %d", bin_str.atobin(), dr_bits), UVM_LOW)


                bin_str = "";
                
                for (int i = 15; i >= 16-dr_bits; i--) begin
                  bin_str = {bin_str, txn.data_tdo[i] ? "1" : "0"};
                end

                `uvm_info("MON", $sformatf("Read DR observed: %0h", bin_str.atobin()) ,UVM_LOW);
                
                
              end        
                      
            case(state)
              TEST_LOGIC_RESET: state = vif.cb_mon.TMS ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
              RUN_TEST_IDLE:    state = vif.cb_mon.TMS ? SELECT_DR_SCAN : RUN_TEST_IDLE;
              SELECT_DR_SCAN:   state = vif.cb_mon.TMS ? SELECT_IR_SCAN : CAPTURE_DR;
              CAPTURE_DR:       state = vif.cb_mon.TMS ? EXIT1_DR : SHIFT_DR;
              SHIFT_DR:         state = vif.cb_mon.TMS ? EXIT1_DR : SHIFT_DR;
              EXIT1_DR:         state = vif.cb_mon.TMS ? UPDATE_DR : PAUSE_DR;
              PAUSE_DR:         state = vif.cb_mon.TMS ? EXIT2_DR : PAUSE_DR;
              EXIT2_DR:         state = vif.cb_mon.TMS ? UPDATE_DR : SHIFT_DR;
              UPDATE_DR:        state = vif.cb_mon.TMS ? SELECT_DR_SCAN : RUN_TEST_IDLE;
              SELECT_IR_SCAN:   state = vif.cb_mon.TMS ? TEST_LOGIC_RESET : CAPTURE_IR;
              CAPTURE_IR:       state = vif.cb_mon.TMS ? EXIT1_IR : SHIFT_IR;
              SHIFT_IR:         state = vif.cb_mon.TMS ? EXIT1_IR : SHIFT_IR;
              EXIT1_IR:         state = vif.cb_mon.TMS ? UPDATE_IR : PAUSE_IR;
              PAUSE_IR:         state = vif.cb_mon.TMS ? EXIT2_IR : PAUSE_IR;
              EXIT2_IR:         state = vif.cb_mon.TMS ? UPDATE_IR : SHIFT_IR;
              UPDATE_IR:        state = vif.cb_mon.TMS ? SELECT_DR_SCAN : RUN_TEST_IDLE;
              default:          state = TEST_LOGIC_RESET;
          endcase
            
            
          end
        
  endtask
  
  
        
        
        
endclass
