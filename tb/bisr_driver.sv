// ───────────────────────────────────────────────
//   DRIVER
// ───────────────────────────────────────────────
class bisr_driver extends uvm_driver #(bisr_seq_item);

  `uvm_component_utils(bisr_driver)

    virtual bisr_if.DRIVER vif;

  function new(string name = "bisr_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
      if (!uvm_config_db#(virtual bisr_if.DRIVER)::get(this, "", "vif", vif))
            `uvm_fatal("DRV_NOVIF", "Driver virtual interface not set")
    endfunction

    task run_phase(uvm_phase phase);
        bisr_seq_item item;    
    
        vif.cb_drv.TMS <= 1'b0;
        vif.cb_drv.TDI <= 1'b0;
      
        forever begin
          seq_item_port.get_next_item(item);
          
          goto_idle();
          
          if(item.wr_ir)
            begin
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b0; // IDLE
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b1; // select DR
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b1; // select IR
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b0; // capture IR
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b0; // shift IR

              for (int i = 0; i < $bits(item.instr); i++) begin
                @(vif.cb_drv);
                vif.cb_drv.TDI <= item.instr[i];

                // Last bit → exit shift
                if (i == $bits(item.instr)-1)
                  vif.cb_drv.TMS <= 1'b1; // Exit1-IR
                else
                  vif.cb_drv.TMS <= 1'b0; // stay in Shift-IR
              end
              
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b1; // exit1 IR
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b1; // update IR
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b0; // IDLE
            end
          else if(item.wr_dr)
            begin
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b0; // select DR
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b1; // select DR
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b0; // capture DR
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b0; // shift DR

              for (int i = 0; i < $bits(item.data); i++) begin
                @(vif.cb_drv);
                vif.cb_drv.TDI <= item.data[i];

                // Last bit → exit shift
                if (i == $bits(item.data)-1)
                  vif.cb_drv.TMS <= 1'b1; // Exit1-DR
                else
                  vif.cb_drv.TMS <= 1'b0; // stay in Shift-DR
              end
              
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b1; // exit1 DR
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b1; // update DR
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b0; // IDLE
            end
          

            seq_item_port.item_done();
        end
    endtask
      
      task goto_idle();
        repeat(5) begin
          @(vif.cb_drv);
          vif.cb_drv.TMS <= 1'b1; // force reset
        end
        @(vif.cb_drv);
        vif.cb_drv.TMS <= 1'b0; // idle
      endtask
      
endclass
