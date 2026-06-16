# 工程师 A — 架构与接口工程师 (pill_bottling.v)

## 职责
模块声明、端口 I/O 定义、状态机参数 localparam、endmodule。

## 负责代码

| 行号 | 代码 |
|------|------|
| 1 | `module pill_bottling (` |
| 2 | `input clk_1hz,` |
| 3 | `input rst,` |
| 4 | `input sta_k0,   // 启动` |
| 5 | `input pau_k1,   // 暂停` |
| 6 | `input set_k2,   // 设置 / 切换设置项` |
| 7 | `input inc_k3,   // -1` |
| 8 | `input dec_k4,   // +1` |
| 9 | `input vie_k5,   // 查看设定值` |
| 10 | `output reg [3:0] pill_ten,` |
| 11 | `output reg [3:0] pill_one,` |
| 12 | `output reg [3:0] bottle_ten,` |
| 13 | `output reg [3:0] bottle_one,` |
| 14 | `output reg [3:0] state,` |
| 15 | `output reg [6:0] alarm` |
| 16 | `);` |
| 30 | `localparam IDLE  = 3'd0;` |
| 31 | `localparam WORK  = 3'd1;` |
| 32 | `localparam PAUSE = 3'd2;` |
| 33 | `localparam SET   = 3'd3;` |
| 34 | `localparam DONE  = 3'd4;` |
| 265 | `endmodule` |

## 工作量
- **行数**: ~18 行
- **占比**: ~7%
- **关键贡献**: 模块接口定义、5 状态状态机参数、顶层框架
