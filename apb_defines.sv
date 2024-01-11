`define ADDR_WIDTH  32
`define DATA_WIDTH  32
`define NO_OF_SLAVES 7

// Slave devices address ranges
`define SLAVE0_START_ADDR  32'h0000_0000
`define SLAVE0_END_ADDR    32'h0000_00FC
`define SLAVE1_START_ADDR  32'h0000_0100
`define SLAVE1_END_ADDR    32'h0000_01FC
`define SLAVE2_START_ADDR  32'h0000_0200
`define SLAVE2_END_ADDR    32'h0000_02FC
`define SLAVE3_START_ADDR  32'h0000_0300
`define SLAVE3_END_ADDR    32'h0000_03FC
`define SLAVE4_START_ADDR  32'h0000_0400
`define SLAVE4_END_ADDR    32'h0000_04FC
`define SLAVE5_START_ADDR  32'h0000_0500
`define SLAVE5_END_ADDR    32'h0000_05FC
`define SLAVE6_START_ADDR  32'h0000_0600
`define SLAVE6_END_ADDR    32'h0000_06FC


typedef enum bit {APB_READ  = 1'b0,
                  APB_WRITE = 1'b1} pwrite_e;

typedef enum {ZERO ,
              SHORT,
              MEDIUM,
              LONG,
              MAX} apb_dly_e;