class apb_master_driver extends uvm_driver #(apb_transfer);
  apb_config cfg;
  
  bit coverage_enable ;
  bit checks_enable ;
  
  local virtual apb_if vif;
  
  `uvm_component_utils(apb_master_driver)
  
  function new(string name = "apb_master_driver",uvm_component parent);
    super.new(name,parent);
  endfunction : new
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(uvm_config_db #(apb_config) :: get(this, "*", "cfg", cfg))begin
        `uvm_info(get_type_name(), "got config from config_db",UVM_MEDIUM)end
        
    else begin 
        `uvm_error(get_type_name(), "Unable to get config from config_db")
    end
    
    if(!uvm_config_db #(virtual apb_if) :: get(this, "*", "vif", vif))begin
      `uvm_fatal(get_type_name(), "Unable to get interface from config_db")end
        
    if(!uvm_config_db #(bit) :: get(this, "*", "coverage_enable", coverage_enable))begin
      `uvm_error(get_type_name(), "Unable to get coverage from config_db")end
        
    if(!uvm_config_db #(bit) :: get(this, "*", "checks_enable", checks_enable))begin
      `uvm_error(get_type_name(), "Unable to get checks from config_db")end
       
  endfunction : build_phase
            
  virtual task run_phase(uvm_phase phase);
    reset_signals();
    get_and_drive();
  endtask : run_phase
    
  
  virtual protected task get_and_drive();
    apb_transfer rsp;
    while(1)begin
      fork
        begin
        @(negedge vif.presetn)
        `uvm_info(get_type_name(),"\tRESET_ASSERTED",UVM_MEDIUM)
        end
        begin
          forever begin
            
            `uvm_info(get_type_name(),"\tentered",UVM_MEDIUM)
            @(posedge vif.pclock iff(vif.presetn));
            seq_item_port.get_next_item(req);
            req.print();
            $cast(rsp, req.clone());
            rsp.set_id_info(req);
            drive_transfer(req);
            seq_item_port.item_done(req);
          end
        end
      join_any
      disable fork;
      if(req.is_active()) this.end_tr(req);
    end
   endtask : get_and_drive
  
  virtual protected task drive_transfer(apb_transfer trans);
      int slave_indx;
      
      if(checks_enable) begin
          vif.has_checks <= 1'b1;
      end
      else begin
        vif.has_checks <= 1'b0;
      end
        
      if(coverage_enable)begin
          vif.has_coverage <= 1'b1;
      end
      else begin
        vif.has_coverage <= 1'b0;
      end
      if(trans.transmit_delay > 0) begin
        repeat(trans.transmit_delay) @(posedge vif.pclock);
      end
      
      slave_indx = cfg.get_slave_psel_by_addr(trans.paddr);
      
      vif.m_drv_cb.paddr <= trans.paddr;
      vif.m_drv_cb.psel_x <= (1<<slave_indx);
      vif.m_drv_cb.penable <= 1'b0;
      
      if(trans.pwrite == APB_READ)begin
        vif.m_drv_cb.pwrite <= 1'b0;
        vif.m_drv_cb.pwdata <= 'h0;
      end
      
      else begin
        vif.m_drv_cb.pwrite <= 1'b1;
        vif.m_drv_cb.pwdata <= trans.pwdata;
      end
      
      @(posedge vif.pclock);
      vif.m_drv_cb.penable <= 1'b1;
      @(posedge vif.pclock);
    
    wait(vif.m_drv_cb.pready == 1);
    
      vif.m_drv_cb.penable <= 1'b0;
      vif.m_drv_cb.psel_x <= 0;
      vif.m_drv_cb.pwrite <= 1'b0;
      rsp_port.write(req);
    endtask : drive_transfer
  
  virtual protected task reset_signals();
    @(negedge vif.presetn);
    vif.paddr <= 'h0;
    vif.pwdata <= 'h0;
    vif.pwrite <= 'h0;
    vif.psel_x <= 'h0;
    vif.penable <= 'h0;
    `uvm_info(get_type_name(),"\tRESET_ASSERTED",UVM_MEDIUM)
    @(posedge vif.presetn);
  endtask : reset_signals
endclass : apb_master_driver

