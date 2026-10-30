// -----------------------------------------------------------------------------
// apb_bfm_pkg — types shared by the HDL BFMs and the HVL adapters
//
// Types and pure functions only: no classes, no UVM, no timing. It lets both
// sides of the HDL/HVL boundary agree on revision, status, fault and error
// encodings without duplicating integer constants (APB_PROTOCOL_CONTRACT
// section 9). SV interfaces are not declared here; they cannot live in a
// package.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

package apb_bfm_pkg;

  // Revision names per IHI 0024D Preface "APB Revisions"
  typedef enum int unsigned {
    APB2 = 2,
    APB3 = 3,
    APB4 = 4,
    APB5 = 5
  } apb_revision_e;

  // IHI 0024D section 5.2 Check_Type property
  typedef enum int unsigned {
    APB_CHECK_NONE                = 0,
    APB_CHECK_ODD_PARITY_BYTE_ALL = 1
  } apb_check_type_e;

  // Per-instance feature presence pushed from apb_agent_cfg to both BFMs.
  // A user width of 0 means the signal is absent (IHI 0024D section 2.1).
  typedef struct packed {
    apb_revision_e   revision;
    bit              has_pprot;
    bit              has_pstrb;
    bit              has_pwakeup;
    int unsigned     user_req_width;
    int unsigned     user_data_width;
    int unsigned     user_resp_width;
    apb_check_type_e check_type;
  } apb_features_t;

  // Result of one driver BFM transfer
  typedef enum int unsigned {
    APB_ST_OK            = 0,
    APB_ST_SLVERR        = 1,
    APB_ST_RESET_ABORTED = 2,  // RST-3
    APB_ST_TIMEOUT       = 3,  // POL-02
    APB_ST_NOT_ENABLED   = 4,  // driver BFM released (passive)
    APB_ST_BAD_REQUEST   = 5,  // e.g. PSEL index out of range, BFM busy
    APB_ST_FAULT_INJECTED = 6  // transfer deliberately abandoned by a fault mode
  } apb_bfm_status_e;

  // Deliberate protocol faults the driver BFM can inject (negative tests)
  typedef enum int unsigned {
    APB_FAULT_NONE              = 0,
    APB_FAULT_PADDR_UNSTABLE    = 1,  // change PADDR in the first wait state (APB-R04)
    APB_FAULT_SKIP_SETUP        = 2,  // assert PENABLE with PSEL (APB-R03)
    APB_FAULT_DROP_PSEL_IN_WAIT = 3   // release PSEL while PREADY is LOW (APB-R04)
  } apb_fault_e;

  // Protocol violations detected by the monitor BFM
  typedef enum int unsigned {
    APB_MON_ERR_SETUP_NOT_FOLLOWED_BY_ACCESS = 0,  // APB-R03
    APB_MON_ERR_ACCESS_WITHOUT_SETUP         = 1,  // APB-R03
    APB_MON_ERR_UNSTABLE_IN_ACCESS           = 2,  // APB-R04
    APB_MON_ERR_PSEL_DROPPED_IN_ACCESS       = 3,  // APB-R04
    APB_MON_ERR_PSEL_XZ                      = 4,  // APB-R13
    APB_MON_ERR_MULTIPLE_PSEL                = 5,  // APB-R22
    APB_MON_ERR_PREADY_XZ                    = 6,  // RISK-008: present input not driven
    APB_MON_ERR_PSTRB_ON_READ                = 7,  // APB-R09
    APB_MON_ERR_PRESETN_XZ                   = 8,  // RST-7
    APB_MON_ERR_QUEUE_OVERFLOW               = 9,
    APB_MON_ERR_CONTROL_XZ                   = 10  // APB-R13/A.1: control X/Z while PSEL
  } apb_mon_error_e;
  localparam int unsigned APB_MON_NUM_ERRORS = 11;

  // IHI 0024D Table B-1: PREADY and PSLVERR exist from APB3 onwards
  function automatic bit apb_has_pready(apb_revision_e rev);
    return rev >= APB3;
  endfunction

  function automatic bit apb_has_pslverr(apb_revision_e rev);
    return rev >= APB3;
  endfunction

  // Default configuration: APB4 with PSTRB and PPROT (owner decision)
  function automatic apb_features_t apb_default_features();
    apb_features_t f;
    f.revision        = APB4;
    f.has_pprot       = 1'b1;
    f.has_pstrb       = 1'b1;
    f.has_pwakeup     = 1'b0;
    f.user_req_width  = 0;
    f.user_data_width = 0;
    f.user_resp_width = 0;
    f.check_type      = APB_CHECK_NONE;
    return f;
  endfunction

endpackage : apb_bfm_pkg
