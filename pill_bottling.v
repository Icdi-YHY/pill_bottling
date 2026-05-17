module pill_bottling (
    input clk_1hz,
    input rst,
    input sta_k0,
    input pau_k1,
    input set_k2,
    input inc_k3,
    input dec_k4,
    input vie_k5,
    output reg [3:0] pill_ten,
    output reg [3:0] pill_one,
    output reg [3:0] bottle_ten,
    output reg [3:0] bottle_one,
    output reg [6:0] state,
    output reg [6:0] alarm

);
    
// 当前值寄存器
reg [6:0] cur_pills;      // 当前瓶内药片数 (0-99)
reg [6:0] cur_bottles;    // 已装瓶数 (0-99)

// 设定值寄存器
reg [6:0] set_pills;      // 每瓶设定片数 (1-99)
reg [6:0] set_bottles;    // 目标瓶数 (1-99)




endmodule