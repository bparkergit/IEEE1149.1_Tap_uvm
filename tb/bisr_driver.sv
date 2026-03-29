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

            @(vif.cb_drv);
            vif.cb_drv.wr_en   <= item.wr_en;
            vif.cb_drv.wr_data <= item.wr_data;
            vif.cb_drv.rd_en   <= item.rd_en;

            @(vif.cb_drv);
            vif.cb_drv.wr_en  <= 0;
            vif.cb_drv.rd_en  <= 0;
          
            seq_item_port.item_done();
        end
    endtask
endclass
