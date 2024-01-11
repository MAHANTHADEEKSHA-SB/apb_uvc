class apb_slave_agent extends uvm_agent;
  uvm_analysis_port #(apb_transfer)slave_ap;
  
  apb_slave_driver    driver;
  apb_slave_sequencer sequencer;
  //apb_slave_monitor   monitor;
  
  apb_slave_config cfg;
  
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  
  `uvm_component_utils(apb_slave_agent)
  
  function new(string name = "apb_slave_agent",uvm_component parent);
    super.new(name,parent);
  endfunction : new
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    slave_ap = new("slave_ap",this);
     if(cfg == null)begin
      `uvm_info(get_type_name(),"CFG was null",UVM_MEDIUM)
       cfg = apb_slave_config :: type_id :: create("cfg");
    end
    else begin
      `uvm_info(get_type_name(),"got slave CFG",UVM_MEDIUM)
    end
    //monitor = apb_slave_monitor :: type_id :: create("monitor",this);
    
    if(is_active == UVM_ACTIVE)begin
      driver    = apb_slave_driver :: type_id :: create("driver",this);
      sequencer = apb_slave_sequencer :: type_id :: create("sequencer",this);
    end
    driver.cfg  = cfg;
  endfunction : build_phase
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(is_active == UVM_ACTIVE)begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
      driver.rsp_port.connect(sequencer.rsp_export);
      
    end
    //monitor.cfg = cfg;
    //monitor.monitor_ap.connect(slave_ap);
  endfunction : connect_phase
endclass : apb_slave_agent