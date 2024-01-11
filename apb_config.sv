
class apb_config extends uvm_object;
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  uvm_active_passive_enum is_active_slv = UVM_ACTIVE;
  bit [`NO_OF_SLAVES - 1 : 0] no_of_slaves;
  
  bit [`ADDR_WIDTH - 1 : 0] slv_cfg [$][2];
  int wait_cycles [`NO_OF_SLAVES - 1 : 0];
  
  `uvm_object_utils(apb_config)
  
  function new(string name = "apb_config");
    super.new(name);
  endfunction : new
  
  function int get_slave_psel_by_addr(bit[`ADDR_WIDTH - 1 : 0] addr); 
    int i,j;
    for(i = 0; i < `NO_OF_SLAVES; i = i + 1)begin
      //$display("\n\tindex %0d address %0h %0h",i,slv_cfg[i][0],slv_cfg[i][1]);
      if((addr >= slv_cfg[i][0]) && (addr <= slv_cfg[i][1]))begin
        //$display("\n\tindex",i);
          return i;
        end      
    end
  endfunction 
  
  function void add_slave(bit[`ADDR_WIDTH - 1 : 0] start_addr, bit[`ADDR_WIDTH - 1 : 0]end_addr);
    bit[`ADDR_WIDTH - 1 : 0]temp [2];
    temp[0] = start_addr;
    temp[1] = end_addr;
    slv_cfg.push_back(temp);
    no_of_slaves = no_of_slaves + 1;
  endfunction : add_slave
endclass : apb_config
//----------------------------------------------------------------------------------------------------------