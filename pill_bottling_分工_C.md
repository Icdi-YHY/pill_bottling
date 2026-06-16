# 工程师 C — 核心时序逻辑工程师 (pill_bottling.v)

## 职责
主 always 块：复位初始化、5 状态状态机跳转、SET 模式下 inc/dec 参数调整、WORK 模式下自动药片流水线计数。

## 负责代码

### 复位初始化

| 行号 | 代码 |
|------|------|
| 69 | `always @(posedge clk_1hz or negedge rst) begin` |
| 70-76 | 复位：cur=0，set_pills=10，set_bottles=5，sys_state=IDLE，set_mode=0 |

### 状态机跳转

| 行号 | 状态 | 代码 |
|------|------|------|
| 81-89 | **IDLE** | 清零当前值；sta_edge→WORK；set_edge→SET(set_mode=0) |
| 91-97 | **WORK** | pau_edge→PAUSE；cur_bottles ≥ set_bottles→DONE |
| 99-106 | **PAUSE** | sta_edge→WORK；set_edge→SET(set_mode=0) |
| 108-125 | **SET** | set_edge 切换：mode0→mode1→回到 IDLE；inc/dec 调整 set_pills(1-99) 或 set_bottles(1-99) |
| 127-129 | **DONE** | 空等待，仅外部 rst 可退出 |
| 131 | default | IDLE |

### 自动流水线计数

| 行号 | 代码 |
|------|------|
| 135-142 | `if(sys_state == WORK && cur_bottles < set_bottles)`<br>`cur_pills+1 ≥ set_pills` → pills 归零，bottles+1<br>否则 → pills+1 |

## 工作量
- **行数**: ~78 行
- **占比**: ~29%
- **关键贡献**: 5 状态完整状态机、按键驱动状态跃迁、参数加减调节、药片流水线累加/进位逻辑
