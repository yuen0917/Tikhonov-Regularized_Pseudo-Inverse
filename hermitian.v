module hermitian #(
    parameter DATA_WIDTH         = 24,
    parameter BRAM_RD_ADDR_WIDTH = 10,
    parameter LATENCY            = 2
)(
    input                               clk,
    input                               rst_n,
    input                               start,
    input      [DATA_WIDTH-1:0]         real_in,
    input      [DATA_WIDTH-1:0]         imag_in,
    output reg [BRAM_RD_ADDR_WIDTH-1:0] bram_rd_addr,
    output reg [DATA_WIDTH-1:0]         real_out,
    output reg [DATA_WIDTH-1:0]         imag_out
);
    localparam S_IDLE = 0;
    localparam S_RUN  = 1;
    localparam S_DONE = 2;

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
    // state machine
    // ==============================
    reg [1:0] state;
    reg [1:0] next_state;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case(state)
            S_IDLE: next_state = (start_delay[LATENCY]) ? S_RUN : S_IDLE;
            S_RUN:
            S_DONE:
            default: next_state = S_IDLE
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bram_rd_addr <= 0;
        end else begin
            case(state)
                S_IDLE: begin
                    
                end
                S_RUN: begin
                    
                end
                S_DONE: begin
                    
                end
                default: begin
                    
                end
            endcase
        end
    end

endmodule