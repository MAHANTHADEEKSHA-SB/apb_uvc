class apb_collector extends uvm_component;
  local virtual apb_if vif;
  
  bit checks_enable = 0;
  bit coverage_enable = 0;
  
  uvm_analysis_port #(apb_transfer) collector_ap;
  
  `uvm_component_utils(apb_collector)
  
  function new(string name = "apb_collector",uvm_component parent);
    super.new(name,parent);
  endfunction : new
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
      collector_ap = new("collector_ap",this);

      if(!uvm_config_db #(virtual apb_if) :: get (this, "", "vif", vif))
         `uvm_fatal(get_type_name(), "Unable to get interface from config_db")
        
      if(!uvm_config_db #(bit) :: get(this, "*", "coverage_enable", coverage_enable))begin
        `uvm_error(get_type_name(), "Unable to get coverage from config_db")end
        
      if(!uvm_config_db #(bit) :: get(this, "*", "checks_enable", checks_enable))begin
        `uvm_error(get_type_name(), "Unable to get checks from config_db")end
       
        
    endfunction : build_phase
        
  virtual task run_phase(uvm_phase phase);
    apb_transfer trans_collected;
      
      forever begin
        @(posedge vif.pclock);
        trans_collected = apb_transfer :: type_id :: create("trans_collected");        
        wait((vif.m_drv_cb.pready == 1)&&((vif.m_mon_cb.psel_x != 0)&&(vif.m_mon_cb.penable)));
        begin
          accept_tr(trans_collected,$time);
        
          void'(begin_tr(trans_collected,"apb_collector"));
          @(posedge vif.pclock);
          trans_collected.paddr = vif.m_mon_cb.paddr;
          trans_collected.pwrite = pwrite_e'(vif.m_mon_cb.pwrite);
          if(vif.m_mon_cb.pwrite)begin
            trans_collected.pwdata = vif.m_mon_cb.pwdata;
            trans_collected.prdata = 0;
          end
          if(!vif.m_mon_cb.pwrite)begin
            trans_collected.prdata = vif.m_mon_cb.prdata;
            trans_collected.pwdata = 0;
          end
          
        
          if(checks_enable) begin
            perform_checks();
          end
        
          if(coverage_enable)begin
            perform_coverage(trans_collected);
          end
        
          collector_ap.write(trans_collected);
          end_tr(trans_collected);
          trans_collected.print();
        end
      end
    endtask : run_phase
    
  virtual function void perform_checks();
  endfunction : perform_checks
    
  virtual function void perform_coverage(apb_transfer trans_collected);
    trans_collected.trigger("perform_coverage");
  endfunction : perform_coverage
endclass : apb_collector
 