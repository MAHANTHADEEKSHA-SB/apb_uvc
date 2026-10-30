// -----------------------------------------------------------------------------
// apb_sequencer — non-parameterized APB sequencer
//
// Carries the instance configuration so sequences can give their items the
// bus context (widths, present features) before randomization.
// Included by apb_uvc_pkg.
// -----------------------------------------------------------------------------

class apb_sequencer extends uvm_sequencer #(apb_transaction);
  `uvm_component_utils(apb_sequencer)

  apb_agent_cfg cfg;  // set by apb_agent before build_phase of this component

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass : apb_sequencer
