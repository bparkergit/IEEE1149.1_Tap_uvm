// ───────────────────────────────────────────────
//   ENVIRONMENT
// ───────────────────────────────────────────────
class bisr_env extends uvm_env;

  `uvm_component_utils(bisr_env)

    bisr_agent agent;
  	bisr_scoreboard scoreboard;
  

  function new(string name = "bisr_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        agent = bisr_agent::type_id::create("agent", this);
      	scoreboard = bisr_scoreboard::type_id::create("scoreboard", this);
      
    endfunction
  
  function void connect_phase(uvm_phase phase);
    agent.mon.ap.connect(scoreboard.imp);

  endfunction
  

endclass
