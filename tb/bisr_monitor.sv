// ───────────────────────────────────────────────
//   MONITOR WR
// ───────────────────────────────────────────────
class bisr_monitor extends uvm_monitor;
  `uvm_component_utils(bisr_monitor)
        
  uvm_analysis_port #(bisr_seq_item) ap;
         virtual bisr_if.MONITOR vif;

     
    
      // TAP states
    typedef enum bit [3:0] {
        TEST_LOGIC_RESET, RUN_TEST_IDLE, SELECT_DR_SCAN,
        CAPTURE_DR, SHIFT_DR, EXIT1_DR, PAUSE_DR, EXIT2_DR, UPDATE_DR,
        SELECT_IR_SCAN, CAPTURE_IR, SHIFT_IR, EXIT1_IR, PAUSE_IR, EXIT2_IR, UPDATE_IR
    } tap_state_t;

    tap_state_t state, next_state;
  
  bit [3:0] instr;
  bit [31:0] data;
  
  
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

         if(vif.cb_mon.TRST)
                state = TEST_LOGIC_RESET;
            
            
            if(state == SHIFT_IR)
              instr = {instr[30:0],vif.cb_mon.TDI};

            if(state == EXIT1_IR)
              begin
                txn = bisr_seq_item::type_id::create("txn");
                txn.instr = instr;
                txn.wr_ir = 1'b1;
                ap.write(txn);     
                
                `uvm_info("MON", $sformatf("Write IR observed: %0h", txn.instr), UVM_LOW);
              end

          end
        
  endtask
  
  
        
        
        
endclass
