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
reg [6:0] cur_pills;
reg [6:0] cur_bottles;

// 设定值寄存器
reg [6:0] set_pills;
reg [6:0] set_bottles;

// ====================================================
// 第5+7步：系统状态寄存器（扩展为3位，因为有4个状态）
// ====================================================
reg [1:0] sys_state;
localparam IDLE  = 2'd0;
localparam WORK  = 2'd1;
localparam PAUSE = 2'd2;
localparam SET   = 2'd3;   // 第7步：新增设置状态

// ====================================================
// 主逻辑
// ====================================================
always @(posedge clk_1hz or negedge rst) begin
    if(!rst) begin
        cur_pills <= 7'd0;
        cur_bottles <= 7'd0;
        set_pills <= 7'd10;
        set_bottles <= 7'd5;
        sys_state <= IDLE;
    end else begin
        
        // ========================================
        // 第7步：状态切换逻辑（增加SET状态）
        // ========================================
        case(sys_state)
            IDLE: begin
                if(sta_k0 == 1'b0) begin
                    sys_state <= WORK;
                end else if(set_k2 == 1'b0) begin
                    sys_state <= SET;   // 按设置键进入设置状态
                end
            end
            
            WORK: begin
                if(pau_k1 == 1'b0) begin
                    sys_state <= PAUSE;
                end
            end
            
            PAUSE: begin
                if(sta_k0 == 1'b0) begin
                    sys_state <= WORK;
                end
            end
            
            SET: begin
                if(set_k2 == 1'b1) begin
                    sys_state <= IDLE;   // 松开设置键，返回空闲
                end
            end
        endcase
        
        // ========================================
        // 第7步：设置状态下的参数调整
        // ========================================
        if(sys_state == SET) begin
            // 按增加键
            if(inc_k3 == 1'b0 && set_pills < 7'd99) begin
                set_pills <= set_pills + 7'd1;
            end
            // 按减少键
            if(dec_k4 == 1'b0 && set_pills > 7'd1) begin
                set_pills <= set_pills - 7'd1;
            end
        end
        
        // ========================================
        // 计数逻辑（只在工作状态）
        // ========================================
        if(sys_state == WORK) begin
            if(cur_pills + 1 >= set_pills) begin
                cur_pills <= 7'd0;
                cur_bottles <= cur_bottles + 7'd1;
            end else begin
                cur_pills <= cur_pills + 7'd1;
            end
        end
        
    end
end

// ====================================================
// 显示输出
// ====================================================
always @(*) begin
    if(vie_k5 == 1'b0) begin
        pill_one   = cur_pills % 10;
        pill_ten   = cur_pills / 10;
        bottle_one = cur_bottles % 10;
        bottle_ten = cur_bottles / 10;
    end else begin
        pill_one   = set_pills % 10;
        pill_ten   = set_pills / 10;
        bottle_one = set_bottles % 10;
        bottle_ten = set_bottles / 10;
    end
end

// 7段数码管编码
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

// 状态显示
always @(*) begin
    case(sys_state)
        IDLE:  state = seg7(4'd0);
        WORK:  state = seg7(4'd1);
        PAUSE: state = seg7(4'd2);
        SET:   state = seg7(4'd3);  // 设置状态显示3
        default: state = seg7(4'd0);
    endcase
end

// 模式显示
always @(*) begin
    if(vie_k5 == 1'b0) begin
        alarm = 7'b0000000;
    end else begin
        alarm = 7'b1111111;
    end
end

endmodule