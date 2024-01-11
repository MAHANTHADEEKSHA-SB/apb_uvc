class apb_slave_driver extends uvm_driver#(apb_transfer);
  apb_slave_config cfg;

  bit[`DATA_WIDTH - 1 : 0] mem [bit[`ADDR_WIDTH - 1 : 0]];
  
  local virtual apb_if vif;
  
  `uvm_component_utils(apb_slave_driver)
  
  function new(string name = "apb_slave_driver",uvm_component parent);
    super.new(name,parent);
  endfunction : new
  
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(cfg == null)begin
      `uvm_info(get_type_name(),"CFG was null",UVM_MEDIUM)
      cfg = apb_slave_config :: type_id :: create("cfg");
    end
    if(!uvm_config_db #(virtual apb_if) :: get(this, "*", "vif", vif))begin
      `uvm_fatal(get_type_name(), "Unable to get interface from config_db")end
    
  endfunction : build_phase
  
  virtual task run_phase(uvm_phase phase);
    reset_signals();
    get_and_drive();
  endtask : run_phase
  
  virtual protected task get_and_drive();
    while(1)begin
      fork
        begin  
            @(negedge vif.presetn)
            `uvm_info(get_type_name(),"\tRESET_ASSERTED",UVM_MEDIUM)
        end
        begin
          forever begin
            @(posedge vif.pclock iff(vif.presetn));
            seq_item_port.get_next_item(req);
            
            drive_transfer();
            seq_item_port.item_done(req);
          end
        end
      join_any
      disable fork;
        if(req.is_active) this.end_tr(req);
    end
   endtask : get_and_drive
   
     
  virtual protected task drive_transfer();
    @(posedge vif.pclock);
    wait(vif.slv_drv_cb.psel_x !=0);
    if((vif.slv_drv_cb.paddr <= cfg.end_addr) && (vif.slv_drv_cb.paddr >= cfg.start_addr))begin
        `uvm_info(get_type_name(),$sformatf("\tDRIVING_STARTED time %0t",$time),UVM_MEDIUM)

          repeat(cfg.wait_cycles) begin 
            @(posedge vif.pclock);
            vif.slv_drv_cb.pready <= 1'b0;
          end
          vif.slv_drv_cb.pready <= 1'b1;
 
          if(vif.slv_drv_cb.pwrite == 1'b0)begin
            vif.slv_drv_cb.prdata <= mem[vif.slv_drv_cb.paddr];
            `uvm_info(get_type_name(),$sformatf("\tREADING_STARTED time %0t",$time),UVM_MEDIUM)
          end
          else begin
            mem[vif.slv_drv_cb.paddr] = vif.slv_drv_cb.pwdata;
          end
       @(posedge vif.pclock);
       vif.slv_drv_cb.prdata <=  'h0;
       vif.slv_drv_cb.pready <= 1'b0; 
     end
  endtask : drive_transfer
  
  virtual protected task reset_signals();
    @(negedge vif.presetn);
    if(cfg.start_addr == 'h0)begin
      vif.pready <= 'h0;
      vif.prdata <= 'h0;
      @(posedge vif.presetn);
      `uvm_info(get_type_name(),"\tRESET_ASSERTED",UVM_MEDIUM)
    end
  endtask : reset_signals
endclass :apb_slave_driver