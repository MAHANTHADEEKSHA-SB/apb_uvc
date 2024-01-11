class apb_write_test extends apb_base_test;
  apb_write_seq seq;
  apb_read_seq seq_r;
  apb_slave_seq seqa[];
  `uvm_component_utils(apb_write_test)
  
  function new(string name= "apb_write_test",uvm_component parent);
    super.new(name,parent);
  endfunction : new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seq = apb_write_seq :: type_id :: create("seq");
    seq_r = apb_read_seq :: type_id :: create("seqr");
    seqa = new[`NO_OF_SLAVES];
    foreach(cfg.slv_cfg[i])begin
      seqa[i] = apb_slave_seq :: type_id :: create($sformatf("seqa[%0d]",i));
    end
  endfunction : build_phase
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    fork
      begin
       seq.start(env.master.sequencer);
        seq_r.start(env.master.sequencer);
      end
      begin
        //foreach(cfg.slv_cfg[i])begin
          //seqa[i].start(env.slaves[i].sequencer);
        //end
        seqa[0].start(env.slaves[0].sequencer);
        seqa[0].start(env.slaves[0].sequencer);

      end
      begin
        seqa[1].start(env.slaves[1].sequencer);
        seqa[1].start(env.slaves[1].sequencer);

      end
      begin
        seqa[2].start(env.slaves[2].sequencer);
        seqa[2].start(env.slaves[2].sequencer);
      end
      begin
        seqa[3].start(env.slaves[3].sequencer);
        seqa[3].start(env.slaves[3].sequencer);
      end
      begin
        seqa[4].start(env.slaves[4].sequencer);
        seqa[4].start(env.slaves[4].sequencer);
      end
      begin
        seqa[5].start(env.slaves[5].sequencer);
        seqa[5].start(env.slaves[5].sequencer);
      end
      begin
        seqa[6].start(env.slaves[6].sequencer);
        seqa[6].start(env.slaves[6].sequencer);
      end
    join
    #10;
    phase.drop_objection(this);
  endtask : run_phase
endclass : apb_write_test