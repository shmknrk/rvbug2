`ifndef CONFIG_VH_
`define CONFIG_VH_

/***** Processor *****/
`ifndef RESET_VECTOR
    `define RESET_VECTOR 32'h00000000
`endif

`ifndef ILEN
    `define ILEN 32
`endif

`ifndef XLEN
    `define XLEN 32
`endif
`define XBYTES (`XLEN/8)

/***** Memory *****/
`ifndef MEMSIZE
//    `define MEMSIZE 64         //  64   B
//    `define MEMSIZE 128        // 128   B
//    `define MEMSIZE 256        // 256   B
//    `define MEMSIZE 512        // 512   B
//    `define MEMSIZE (1*1024)   //   1 KiB
//    `define MEMSIZE (2*1024)   //   2 KiB
//    `define MEMSIZE (4*1024)   //   4 KiB
    `define MEMSIZE (8*1024)   //   8 KiB
//    `define MEMSIZE (16*1024)  //  16 KiB
//    `define MEMSIZE (32*1024)  //  32 KiB
//    `define MEMSIZE (64*1024)  //  64 KiB
//    `define MEMSIZE (128*1024) // 128 KiB
`endif

`ifndef TOHOST_ADDR
    `define TOHOST_ADDR 32'h40008000
`endif

/***** IP *****/
`ifndef NO_IP
//    `define NO_IP
`endif

`endif // CONFIG_VH_
