# 工程师 B — 寄存器与辅助信号工程师 (pill_bottling.v)

## 职责
内部寄存器声明、按键同步打拍寄存器、下降沿边缘检测逻辑。

## 负责代码

### 内部寄存器声明

| 行号 | 代码 |
|------|------|
| 19 | `reg [6:0] cur_pills;` |
| 20 | `reg [6:0] cur_bottles;` |
| 23 | `reg [6:0] set_pills;` |
| 24 | `reg [6:0] set_bottles;` |
| 29 | `reg [2:0] sys_state;` |
| 37 | `reg set_mode;` |

### 按键边沿检测（同步打拍 + 下降沿产生）

| 行号 | 代码 |
|------|------|
| 42 | `reg r_sta_k0, r_pau_k1, r_set_k2, r_inc_k3, r_dec_k4;` |
| 43 | `always @(posedge clk_1hz or negedge rst) begin` |
| 44-49 | 异步复位至 1（高电平释放，以便检测下降沿） |
| 50-55 | 每个 1Hz 时钟周期采样输入 |
| 56-57 | end |
| 60 | `wire sta_edge = (r_sta_k0 && !sta_k0);` — 下降沿 |
| 61 | `wire pau_edge = (r_pau_k1 && !pau_k1);` |
| 62 | `wire set_edge = (r_set_k2 && !set_k2);` |
| 63 | `wire inc_edge = (r_inc_k3 && !inc_k3);` |
| 64 | `wire dec_edge = (r_dec_k4 && !dec_k4);` |

### 设计说明
- 使用 **下降沿检测**（`r_xx && !xx`）而非上升沿
- 按键低电平有效 → 同步寄存器初始化为 1 → 按下时跳变为 0 → 组合逻辑产生单周期脉冲

## 工作量
- **行数**: ~30 行
- **占比**: ~11%
- **关键贡献**: 6 个内部工作寄存器、5 路按键同步采样、5 路下降沿脉冲产生
