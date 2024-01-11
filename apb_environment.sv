class apb_env extends uvm_env;
  apb_config cfg;
  apb_master_agent master;
  apb_slave_config slv_cfg[];
  apb_slave_agent slaves [];
  
  `uvm_component_utils(apb_env)
  
  function new(string name = "apb_env",uvm_component parent);
    super.new(name,parent);
  endfunction : new
  
  extern virtual function void build_phase(uvm_phase phase);
  
    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      
      
    endfunction : connect_phase
endclass : apb_env
    
    function void apb_env :: build_phase(uvm_phase phase);
      super.build_phase(phase);
      
      if(uvm_config_db #(apb_config) :: get(this, "*", "cfg", cfg))begin
        `uvm_info(get_type_name(), "got config from config_db",UVM_MEDIUM)end
        
      else begin 
        `uvm_error(get_type_name(), "Unable to get config from config_db")
      end
      master  = apb_master_agent :: type_id :: create("apb_env",this);
      master.cfg = cfg;
      master.is_active = cfg.is_active;
      
      slv_cfg = new[cfg.no_of_slaves];
      
      foreach(cfg.slv_cfg[i])begin
        slv_cfg[i] = apb_slave_config :: type_id :: create($sformatf("slave_config[%0d]",i));
        slv_cfg[i].start_addr = cfg.slv_cfg[i][0];
        slv_cfg[i].end_addr = cfg.slv_cfg[i][1];
        slv_cfg[i].wait_cycles = cfg.wait_cycles[i];
        //slv_cfg[i].print();
      end
      slaves = new[cfg.no_of_slaves];
      foreach(slaves[i])begin
        slaves[i] = apb_slave_agent :: type_id :: create($sformatf("slave[%0d]",i),this);
        slaves[i].is_active = cfg.is_active_slv;
        slaves[i].cfg = slv_cfg[i];
      end
    endfunction : build_phase