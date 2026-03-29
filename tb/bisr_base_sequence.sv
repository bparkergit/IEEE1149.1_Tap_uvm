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
      // fill fifo to get write when full
      repeat (8) begin
  	 	start_item(item); 
    	assert(item.randomize() with { wr_en==1; rd_en==0; });
    	finish_item(item);
      end
      
      repeat(20) begin

            start_item(item);
            assert(item.randomize() with {
              wr_en dist {1 := 80, 0 := 20};
              rd_en dist {1 := 20, 0 := 80};
            });
            `uvm_info("SEQ", $sformatf("Generated item: wr_en=%0b wr_data=%02h rd_en=%0b", 
                                       item.wr_en, item.wr_data, item.rd_en), UVM_MEDIUM)
            finish_item(item);
        end
      // empty fifo to get write when empty
      repeat (8) begin
  	 	start_item(item); 
        assert(item.randomize() with { wr_en==0; rd_en==1; });
    	finish_item(item);
      end
      
      repeat(20) begin

            start_item(item);
            assert(item.randomize() with {
              wr_en dist {1 := 20, 0 := 80};
              rd_en dist {1 := 80, 0 := 20};
            });
            `uvm_info("SEQ", $sformatf("Generated item: wr_en=%0b wr_data=%02h rd_en=%0b", 
                                       item.wr_en, item.wr_data, item.rd_en), UVM_MEDIUM)
            finish_item(item);
        end
      
    endtask

endclass
