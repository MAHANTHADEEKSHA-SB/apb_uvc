class apb_monitor extends uvm_monitor;
  bit coverage_enable = 0;
  bit checks_enable = 0;
  
  apb_transfer trans_collected;
  
  uvm_analysis_imp #(apb_transfer, apb_monitor) monitor_imp;
  
  uvm_analysis_port#(apb_transfer) monitor_ap;
  
  `uvm_component_utils(apb_monitor)
  
  covergroup apb_transfer_cg;
    TRANS_ADDR : coverpoint trans_collected.paddr{
      bins ZERO = {0};
      bins NON_ZERO = {[1:8'hf7]};
    }
    TRANS_PWRITE : coverpoint trans_collected.pwrite;
    TRANS_ADDR_X_TRANS_PWRITE : cross TRANS_ADDR, TRANS_PWRITE;
  endgroup : apb_transfer_cg
  
  function new(string name = "apb_monitor",uvm_component parent);
    
    super.new(name,parent);
    apb_transfer_cg = new();
  endfunction : new
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
      monitor_imp = new("monitor_imp",this);
      
      monitor_ap = new("monitor_ap",this);
      
      trans_collected = apb_transfer :: type_id :: create("trans_colected");
    
      if(!uvm_config_db #(bit) :: get(this, "*", "coverage_enable", coverage_enable))begin
        `uvm_error(get_type_name(), "Unable to get coverage from config_db")end
        
      if(!uvm_config_db #(bit) :: get(this, "*", "checks_enable", checks_enable))begin
        `uvm_error(get_type_name(), "Unable to get checks from config_db")end
       
        
    endfunction : build_phase
  
  
    
  virtual function void write(apb_transfer trans_collected);
      this.trans_collected = trans_collected;
      //trans_collected.print();
      if(coverage_enable)begin
        perform_coverage();
      end    
      monitor_ap.write(trans_collected);
    endfunction : write
  
  virtual function void perform_coverage();  
    apb_transfer_cg.sample();
  endfunction : perform_coverage
endclass : apb_monitor

  