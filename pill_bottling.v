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
// 系统状态寄存器
// ====================================================
reg [2:0] sys_state;  // 改为3位，因为有5个状态
localparam IDLE  = 3'd0;
localparam WORK  = 3'd1;
localparam PAUSE = 3'd2;
localparam SET   = 3'd3;
localparam DONE  = 3'd4;  // 第8步：新增完成状态

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
        // 状态切换逻辑
        // ========================================
        case(sys_state)
            IDLE: begin
                if(sta_k0 == 1'b0) begin
                    sys_state <= WORK;
                end else if(set_k2 == 1'b0) begin
                    sys_state <= SET;
                end
            end
            
            WORK: begin
                if(pau_k1 == 1'b0) begin
                    sys_state <= PAUSE;
                end
                // 第8步：检查是否完成
                else if(cur_bottles >= set_bottles) begin
                    sys_state <= DONE;
                end
            end
            
            PAUSE: begin
                if(sta_k0 == 1'b0) begin
                    sys_state <= WORK;
                end
            end
            
            SET: begin
                if(set_k2 == 1'b1) begin
                    sys_state <= IDLE;
                end
            end
            
            DONE: begin
                // 完成状态下，只有复位才能退出
                // 复位在外面处理
            end
        endcase
        
        // ========================================
        // 设置状态下的参数调整
        // ========================================
        if(sys_state == SET) begin
            if(inc_k3 == 1'b0 && set_pills < 7'd99) begin
                set_pills <= set_pills + 7'd1;
            end
            if(dec_k4 == 1'b0 && set_pills > 7'd1) begin
                set_pills <= set_pills - 7'd1;
            end
        end
        
        // ========================================
        // 第8步：计数逻辑（只在工作状态，且未完成）
        // ========================================
        if(sys_state == WORK && cur_bottles < set_bottles) begin
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
// ====================================================
// 函数：将0-99的数字拆分成十位和个位
// ====================================================
function [7:0] split_bcd;
    input [6:0] num;
    reg [3:0] ten;
    reg [3:0] one;
    begin
        if(num >= 90) begin
            ten = 9;
            one = num - 90;
        end else if(num >= 80) begin
            ten = 8;
            one = num - 80;
        end else if(num >= 70) begin
            ten = 7;
            one = num - 70;
        end else if(num >= 60) begin
            ten = 6;
            one = num - 60;
        end else if(num >= 50) begin
            ten = 5;
            one = num - 50;
        end else if(num >= 40) begin
            ten = 4;
            one = num - 40;
        end else if(num >= 30) begin
            ten = 3;
            one = num - 30;
        end else if(num >= 20) begin
            ten = 2;
            one = num - 20;
        end else if(num >= 10) begin
            ten = 1;
            one = num - 10;
        end else begin
            ten = 0;
            one = num;
        end
        split_bcd = {ten, one};  // 高4位十位，低4位个位
    end
endfunction


always @(*) begin
    reg [7:0] result;
    
    if(vie_k5 == 1'b0) begin
        // 显示当前值
        result = split_bcd(cur_pills);
        pill_ten = result[7:4];
        pill_one = result[3:0];
        
        result = split_bcd(cur_bottles);
        bottle_ten = result[7:4];
        bottle_one = result[3:0];
    end else begin
        // 显示设定值
        result = split_bcd(set_pills);
        pill_ten = result[7:4];
        pill_one = result[3:0];
        
        result = split_bcd(set_bottles);
        bottle_ten = result[7:4];
        bottle_one = result[3:0];
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
        SET:   state = seg7(4'd3);
        DONE:  state = seg7(4'd4);  // 完成状态显示4
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