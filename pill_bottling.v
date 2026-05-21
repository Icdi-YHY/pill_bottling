module pill_bottling (
    input clk_1hz,
    input rst,
    input sta_k0,   // 启动
    input pau_k1,   // 暂停
    input set_k2,   // 设置 / 切换设置项
    input inc_k3,   // -1
    input dec_k4,   // +1
    input vie_k5,   // 查看设定值
    output reg [3:0] pill_ten,
    output reg [3:0] pill_one,
    output reg [3:0] bottle_ten,
    output reg [3:0] bottle_one,
    output reg [3:0] state,
    output reg [6:0] alarm
);

// 当前值寄存器
reg [6:0] cur_pills;
reg [6:0] cur_bottles;

// 设定值寄存器
reg [6:0] set_pills;
reg [6:0] set_bottles;

// ====================================================
// 系统状态机定义
// ====================================================
reg [2:0] sys_state;
localparam IDLE  = 3'd0;
localparam WORK  = 3'd1;
localparam PAUSE = 3'd2;
localparam SET   = 3'd3;
localparam DONE  = 3'd4;

// 设置子状态：0-设置每瓶片数，1-设置目标瓶数
reg set_mode; 

// ====================================================
// 按键边缘检测 (针对 1Hz 慢时钟的同步边缘触发寄存器)
// ====================================================
reg r_sta_k0, r_pau_k1, r_set_k2, r_inc_k3, r_dec_k4;
always @(posedge clk_1hz or negedge rst) begin
    if(!rst) begin
        r_sta_k0 <= 1'b1; 
        r_pau_k1 <= 1'b1; 
        r_set_k2 <= 1'b1;
        r_inc_k3 <= 1'b1; 
        r_dec_k4 <= 1'b1;
    end else begin
        r_sta_k0 <= sta_k0; 
        r_pau_k1 <= pau_k1; 
        r_set_k2 <= set_k2;
        r_inc_k3 <= inc_k3; 
        r_dec_k4 <= dec_k4;
    end
end

// 下降沿有效 (捕捉按键按下瞬间)
wire sta_edge = (r_sta_k0 && !sta_k0);
wire pau_edge = (r_pau_k1 && !pau_k1);
wire set_edge = (r_set_k2 && !set_k2);
wire inc_edge = (r_inc_k3 && !inc_k3);
wire dec_edge = (r_dec_k4 && !dec_k4);

// ====================================================
// 主状态机与核心计数逻辑
// ====================================================
always @(posedge clk_1hz or negedge rst) begin
    if(!rst) begin
        cur_pills   <= 7'd0;
        cur_bottles <= 7'd0;
        set_pills   <= 7'd10; // 默认每瓶10片
        set_bottles <= 7'd5;  // 默认目标5瓶
        sys_state   <= IDLE;
        set_mode    <= 1'b0;
    end else begin
        
        // 1. 状态跳转与参数调整分支
        case(sys_state)
            IDLE: begin
                cur_pills   <= 7'd0;
                cur_bottles <= 7'd0;
                if(sta_edge)       sys_state <= WORK;
                else if(set_edge) begin
                    sys_state <= SET;
                    set_mode  <= 1'b0; // 默认先进入"设置单瓶片数"
                end
            end
            
            WORK: begin
                if(pau_edge) begin
                    sys_state <= PAUSE;
                end else if(cur_bottles >= set_bottles) begin
                    sys_state <= DONE;
                end
            end
            
            PAUSE: begin
                if(sta_edge)      sys_state <= WORK;
                else if(set_edge) begin
                    sys_state <= SET;
                    set_mode  <= 1'b0;
                end
            end
            
            SET: begin
                // 按下 SET 键顺序切换
                if(set_edge) begin
                    if(set_mode == 1'b0) begin
                        set_mode <= 1'b1; // 切换到"设置总瓶数"
                    end else begin
                        sys_state <= IDLE; // 设置完毕，回到空闲状态
                    end
                end
                
                // 参数加减调节控制
                if(set_mode == 1'b0) begin // 调整单瓶药片数目标限制 (1 ~ 99)
                    if(inc_edge && set_pills < 7'd99) set_pills <= set_pills + 7'd1;
                    if(dec_edge && set_pills > 7'd1)  set_pills <= set_pills - 7'd1;
                end else begin             // 调整目标总瓶数限制 (1 ~ 99)
                    if(inc_edge && set_bottles < 7'd99) set_bottles <= set_bottles + 7'd1;
                    if(dec_edge && set_bottles > 7'd1)  set_bottles <= set_bottles - 7'd1;
                end
            end
            
            DONE: begin
                // 完成状态，不作跳出处理。直到硬件外部产生 rst 信号恢复到 IDLE
            end
            
            default: sys_state <= IDLE;
        endcase
        
        // 2. 自动药片流水线计数逻辑 (仅工作状态且瓶数未满)
        if(sys_state == WORK && cur_bottles < set_bottles) begin
            if(cur_pills + 7'd1 >= set_pills) begin
                cur_pills   <= 7'd0;
                cur_bottles <= cur_bottles + 7'd1;
            end else begin
                cur_pills   <= cur_pills + 7'd1;
            end
        end
        
    end
end

// ====================================================
// 显示输出控制逻辑 (多路组合复用器)
// ====================================================

// 修复语法错误：result 寄存器必须定义在 always 块外部
reg [7:0] result_pills;
reg [7:0] result_bottles;

always @(*) begin
    // 默认防锁存器清除赋值
    result_pills   = 8'd0;
    result_bottles = 8'd0;

    if(sys_state == SET) begin
        // 设置状态下：数码管直接实时显示正在修改的配置目标值
        result_pills   = split_bcd(set_pills);
        result_bottles = split_bcd(set_bottles);
    end else if(vie_k5 == 1'b0) begin
        // 任何非设置状态下按下【查看键】：切为显示设定目标值
        result_pills   = split_bcd(set_pills);
        result_bottles = split_bcd(set_bottles);
    end else begin
        // 默认运行状态下：持续输出当前的实时运行计数值
        result_pills   = split_bcd(cur_pills);
        result_bottles = split_bcd(cur_bottles);
    end
    
    // 总线分拆到十位与个位输出信号
    pill_ten    = result_pills[7:4];
    pill_one    = result_pills[3:0];
    bottle_ten  = result_bottles[7:4];
    bottle_one  = result_bottles[3:0];
end

// ====================================================
// 7段共阴极数码管译码与警报状态指示
// ====================================================

// 单独状态数码管显示处理
always @(*) begin
    case(sys_state)
        IDLE:    state = 4'd0; // 空闲状态：显示字形 0
        WORK:    state = 4'd1; // 运行状态：显示字形 1
        PAUSE:   state = 4'd2; // 暂停状态：显示字形 2
        SET:     state = (set_mode == 1'b0) ? 4'd3 : 4'd5; // 调片数显3，调瓶数显5
        DONE:    state = 4'd4; // 完成状态：显示字形 4
        default: state = 4'd0;
    endcase
end

// 模式/告警输出总线控制 (用于指示当前是否属于查看模式/设置模式)
always @(*) begin
    if(sys_state == SET) begin
        alarm = 7'b1010101; // 设置模式：LED交替发光
    end else if(vie_k5 == 1'b0) begin
        alarm = 7'b1111111; // 运行中看目标值：LED全亮提示
    end else if(sys_state == DONE) begin
        alarm = 7'b1111111; // 满载完成：LED全亮提示
    end else begin
        alarm = 7'b0000000; // 正常工作运行实时值：LED全灭
    end
end

// ====================================================
// 工具辅助函数 (Functions)
// ====================================================

// 0-99 纯组合逻辑高速减法实现 BCD 拆分（规避硬件除法器，100%可综合）
function [7:0] split_bcd;
    input [6:0] num;
    reg [3:0] ten;
    reg [3:0] one;
    begin
        if(num >= 90) begin
            ten = 9;  one = num - 90;
        end else if(num >= 80) begin
            ten = 8;  one = num - 80;
        end else if(num >= 70) begin
            ten = 7;  one = num - 70;
        end else if(num >= 60) begin
            ten = 6;  one = num - 60;
        end else if(num >= 50) begin
            ten = 5;  one = num - 50;
        end else if(num >= 40) begin
            ten = 4;  one = num - 40;
        end else if(num >= 30) begin
            ten = 3;  one = num - 30;
        end else if(num >= 20) begin
            ten = 2;  one = num - 20;
        end else if(num >= 10) begin
            ten = 1;  one = num - 10;
        end else begin
            ten = 0;  one = num;
        end
        split_bcd = {ten, one};
    end
endfunction

// 7段数码管经典真值表 (共阴极格式，1点亮，0熄灭)
function [6:0] seg7;
    input [3:0] num;
    begin
        case(num)
            4'd0: seg7 = 7'b0111111;
            4'd1: seg7 = 7'b0000110;
            4'd2: seg7 = 7'b1011011;
            4'd3: seg7 = 7'b1001111;
            4'd4: seg7 = 7'b1100110;
            4'd5: seg7 = 7'b1101101;
            4'd6: seg7 = 7'b1111101;
            4'd7: seg7 = 7'b0000111;
            4'd8: seg7 = 7'b1111111;
            4'd9: seg7 = 7'b1101111;
            default: seg7 = 7'b0000000;
        endcase
    end
endfunction

endmodule