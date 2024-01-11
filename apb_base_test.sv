class apb_base_test extends uvm_test;
  apb_config cfg;
  bit coverage_enable = 1;
  bit checks_enable = 1;
  int i;
  apb_env env;
  `uvm_component_utils(apb_base_test)
  
  function new(string name = "apb_base_test",uvm_component parent);
    super.new(name,parent);
  endfunction : new
  
  virtual function void build_phase(uvm_phase phase);
    env = apb_env :: type_id :: create("env",this);
    cfg = apb_config :: type_id :: create("cfg");
    uvm_config_db #(bit) :: set(this,"*","coverage_enable",coverage_enable);
    uvm_config_db #(bit) :: set(this,"*","checks_enable",checks_enable);
    
    for(i = 0;i < `NO_OF_SLAVES; i = i + 1)begin
      bit[`ADDR_WIDTH - 1 : 0] start_addr,end_addr;
      
      start_addr = start_addr + (`ADDR_WIDTH'h100*i);
      end_addr = end_addr + ((`ADDR_WIDTH 'h100*i) + `ADDR_WIDTH'hFC);
      cfg.wait_cycles[i] = i;
      cfg.add_slave(.start_addr(start_addr),.end_addr(end_addr));
    end
    uvm_config_db #(apb_config) ::set(this,"*","cfg",cfg);
  endfunction : build_phase
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    phase.drop_objection(this);
  endtask : run_phase
endclass : apb_base_test