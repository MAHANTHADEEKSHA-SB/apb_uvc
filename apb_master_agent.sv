class apb_master_agent extends uvm_agent;
  apb_config cfg;
  
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  
  uvm_analysis_port #(apb_transfer) master_ap;
  
  apb_master_sequencer sequencer;
  apb_master_driver driver;
  apb_collector collector;
  apb_monitor monitor;
  
  `uvm_component_utils_begin(apb_master_agent)
     `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
  `uvm_component_utils_end
  
  function new(string name = "apb_master_agent",uvm_component parent);
    super.new(name,parent);
  endfunction : new
  
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
endclass : apb_master_agent
    
    function void apb_master_agent :: build_phase(uvm_phase phase);
      super.build_phase(phase);
      master_ap = new("master_ap",this);
      
      monitor = apb_monitor :: type_id :: create("monitor",this);
      collector = apb_collector :: type_id :: create("collector",this);
      if(is_active == UVM_ACTIVE)begin
        sequencer = apb_master_sequencer :: type_id :: create("sequencer",this);
        driver = apb_master_driver :: type_id :: create("driver",this);
      end
      
    endfunction : build_phase
    
    function void apb_master_agent :: connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      collector.collector_ap.connect(monitor.monitor_imp);
      monitor.monitor_ap.connect(master_ap);
      if(is_active == UVM_ACTIVE)begin
        driver.seq_item_port.connect(sequencer.seq_item_export);
        driver.rsp_port.connect(sequencer.rsp_export);
      end
      
    endfunction : connect_phase