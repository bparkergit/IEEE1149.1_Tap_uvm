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
        forever begin
          seq_item_port.get_next_item(item);

          if(item.wr_ir)
            begin
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b1; // select DR
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b1; // select IR
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b0; // capture IR
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b0; // shift IR
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b0; 
              vif.cb_drv.TDI <= vif.item.instr;
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b1; // exit1 IR
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b1; // update IR
              @(vif.cb_drv);
              vif.cb_drv.TMS <= 1'b0; // IDLE
            end
          

            seq_item_port.item_done();
        end
    endtask
endclass
