`timescale 1ns/1ns

import servo_controller_pkg;

module servo_controller_tb #(
    parameter int unsigned CLK_FREQ_HZ = servo_controller_pkg::DEFAULT_CLK_FREQ_HZ,

	parameter int unsigned MIN_HIGH_STATE_DURATION_US = servo_controller_pkg::DEFAULT_MIN_HIGH_STATE_DURATION_US,
	parameter int unsigned MAX_HIGH_STATE_DURATION_US = servo_controller_pkg::DEFAULT_MAX_HIGH_STATE_DURATION_US,
	parameter int unsigned FULL_PERIOD_DURATION_US = servo_controller_pkg::DEFAULT_FULL_PERIOD_DURATION_US,

	parameter int unsigned MAX_ANGLE = servo_controller_pkg::DEFAULT_MAX_ANGLE,

	parameter int unsigned CNT_BIT_FOR_FRACT_PART = servo_controller_pkg::DEFAULT_CNT_BIT_FOR_FRACT_PART
);

localparam real CLK_PERIOD_DURATION_US = servo_controller_pkg::calc_CLK_PERIOD_DURATION_US(CLK_FREQ_HZ);

localparam int unsigned CNT_TICKS_FOR_FULL_PERIOD = 
	servo_controller_pkg::calc_CNT_TICKS_FOR_FULL_PERIOD(FULL_PERIOD_DURATION_US, CLK_PERIOD_DURATION_US);
localparam int unsigned CNT_TICKS_FOR_MIN_HIGH_STATE = 
	servo_controller_pkg::calc_CNT_TICKS_FOR_MIN_HIGH_STATE(MIN_HIGH_STATE_DURATION_US, CLK_PERIOD_DURATION_US);
localparam int unsigned CNT_TICKS_FOR_MAX_HIGH_STATE = 
	servo_controller_pkg::calc_CNT_TICKS_FOR_MAX_HIGH_STATE(MAX_HIGH_STATE_DURATION_US, CLK_PERIOD_DURATION_US);

localparam int unsigned K_VALUE = 
	servo_controller_pkg::calc_K_VALUE(CNT_TICKS_FOR_MAX_HIGH_STATE, CNT_TICKS_FOR_MIN_HIGH_STATE, CNT_BIT_FOR_FRACT_PART);

logic clk_sig, nreset_sig, en_cont_sig, out_cont_sig, st_cont_is_active_sig;
logic [7:0] angle_sig;

servo_controller #(
    .CLK_FREQ_HZ(CLK_FREQ_HZ),
    
    .MIN_HIGH_STATE_DURATION_US(MIN_HIGH_STATE_DURATION_US),
    .MAX_HIGH_STATE_DURATION_US(MAX_HIGH_STATE_DURATION_US),
    .FULL_PERIOD_DURATION_US(FULL_PERIOD_DURATION_US),

    .MAX_ANGLE(MAX_ANGLE),

    CNT_BIT_FOR_FRACT_PART(CNT_BIT_FOR_FRACT_PART)
    ) dut (
    .clk(clk_sig),
    .nreset(nreset_sig),
    .en_cont(en_cont_sig),
    .angle(angle_sig),

    .out_cont(out_cont_sig),
    .st_cont_is_active(st_cont_is_active_sig)
);

initial begin
    clk_sig = 1;
    nreset_sig = 0;
    @(posedge clk_sig);
    nreset_sig = 1;
    @(posedge clk_sig);

    angle_sig = 0;
    en_cont_sig = 1;
    wait (out_cont_posedge_detected_sig);
    angle_sig = 60;

    repeat (100000)
        @(posedge clk_sig);
    angle_sig = 160;
    wait (out_cont_posedge_detected_sig);

    repeat (500000)
        @(posedge clk_sig);
    angle_sig = 45;
    wait (out_cont_posedge_detected_sig);

    en_cont_sig = 0;
    @(posedge clk_sig);

    $finish;

end

always begin
    #10 clk_sig = ~clk_sig;
end

logic out_cont_previous_val_reg;
always_ff @(posedge clk_sig or negedge nreset_sig) begin
    if (!nreset_sig) begin
        out_cont_previous_val_reg <= 0;
    end
    else begin
        out_cont_previous_val_reg <= out_cont_sig;
    end
end

logic out_cont_negedge_detected_sig, out_cont_posedge_detected_sig;
assign out_cont_negedge_detected_sig = out_cont_previous_val_reg & ~out_cont_sig;
assign out_cont_posedge_detected_sig = ~out_cont_previous_val_reg & out_cont_sig;

int counter;
always_ff @(posedge clk_sig or negedge nreset_sig) begin
    if (!nreset_sig) begin
        counter <= 0;
    end
    else begin
        if (out_cont_sig) begin
            counter <= counter + 1;
        end
        if (out_cont_negedge_detected_sig) begin
            $display("Count tics in high state = %d", counter + 1);
            int unsigned valid_cnt_ticks = servo_controller_pkg::calc_cnt_ticks_for_high_state #(
                .MAX_ANGLE(MAX_ANGLE),
                .CNT_TICKS_FOR_MAX_HIGH_STATE(CNT_TICKS_FOR_MAX_HIGH_STATE)
            )(
                next_angle,
                CNT_TICKS_FOR_MIN_HIGH_STATE,
                K_VALUE,
                CNT_BIT_FOR_FRACT_PART
            );
            $assert((counter + 1) == valid_cnt_ticks)
                else $error("Value of counter for high state is not equal valid_cnt_ticks");
            
        end
        if (out_cont_posedge_detected_sig) begin
            $display("Count tics for full period = %d", counter + 1);
            $assert((counter + 1) == CNT_TICKS_FOR_FULL_PERIOD)
                else $error("Value of counter for full period is not equal calculated value");
            counter <= 0;
        end
    end
end

endmodule: servo_controller_tb