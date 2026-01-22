`timescale 1ns / 1ps
module hermitian #(
    parameter DATA_WIDTH         = 24,
    parameter BRAM_RD_ADDR_WIDTH = 10,
    parameter BRAM_WR_ADDR_WIDTH = 10,
    parameter BRAM_RD_INCREASE   = 4,
    parameter BRAM_WR_INCREASE   = 4,
    parameter LATENCY            = 2,
    parameter MIC_NUM            = 8,
    parameter SOR_NUM            = 2,
    parameter FREQ_NUM           = 257
)(
    input                                      clk,
    input                                      rst_n,
    input                                      start,
    input      signed [DATA_WIDTH-1:0]         bram_rd_real,
    input      signed [DATA_WIDTH-1:0]         bram_rd_imag,
    output reg        [BRAM_RD_ADDR_WIDTH-1:0] bram_rd_addr,
    output reg signed [DATA_WIDTH-1:0]         bram_wr_real,
    output reg signed [DATA_WIDTH-1:0]         bram_wr_imag,
    output reg        [BRAM_WR_ADDR_WIDTH-1:0] bram_wr_addr,
    output                                     bram_wr_en,
    output reg [3:0]                           bram_wr_we,
    output reg                                 done
);
    localparam S_IDLE = 0;
    localparam S_RD   = 1;
    localparam S_WR   = 2;
    localparam S_DONE = 3;

    localparam TOTAL_NUM = MIC_NUM * SOR_NUM * FREQ_NUM;
    localparam CNT_WIDTH = $clog2(TOTAL_NUM);

    // ==============================
    // bram start delay
    // ==============================
    reg [LATENCY:0] start_delay;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_delay <= 0;
        end else begin
            start_delay <= {start_delay[LATENCY-1:0], start};
        end
    end

    // ==============================
    // FSM
    // ==============================
    reg [1:0] state;
    reg [1:0] next_state;
    reg [CNT_WIDTH-1:0] idx;

    assign bram_wr_en = start_delay[LATENCY];

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case(state)
            S_IDLE:  next_state = (start_delay[LATENCY]) ? S_RD : S_IDLE;
            S_RD:    next_state = S_WR;
            S_WR:    next_state = (idx == TOTAL_NUM - 1) ? S_DONE : S_WR;
            S_DONE:  next_state = S_IDLE;
            default: next_state = S_IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bram_rd_addr <= 0;
            bram_wr_addr <= 0;
            bram_wr_we   <= 4'd0;
            idx          <= 0;
            done         <= 1'b0;
        end else begin
            case(state)
                S_IDLE: begin
                    done <= 0;
                    if (start_delay[LATENCY]) begin
                        bram_rd_addr <= 0;
                        bram_wr_addr <= 0;
                        bram_wr_we   <= 4'b1111;
                    end
                end
                S_RD: begin
                    bram_wr_addr <= bram_rd_addr;
                end
                S_WR: begin
                    bram_wr_real <= bram_rd_real;
                    bram_wr_imag <= -bram_rd_imag;
                    bram_rd_addr <= bram_rd_addr + BRAM_RD_INCREASE;
                    idx          <= (idx == TOTAL_NUM - 1) ? idx : idx + 1;
                end
                S_DONE: begin
                    done <= 1;
                    idx  <= 0;
                end
                default: begin
                    bram_rd_addr <= 0;
                    bram_wr_addr <= 0;
                    bram_wr_we   <= 4'd0;
                    idx          <= 0;
                    done         <= 1'b0;
                end
            endcase
        end
    end

endmodule