`timescale 1ns/1ns

module servo_controller_tb #(
    parameter int unsigned CLK_FREQ_MHz = servo_controller_pkg::DEFAULT_CLK_FREQ_MHz,

	parameter int unsigned MIN_HIGH_STATE_DURATION_US = servo_controller_pkg::DEFAULT_MIN_HIGH_STATE_DURATION_US,
	parameter int unsigned MAX_HIGH_STATE_DURATION_US = servo_controller_pkg::DEFAULT_MAX_HIGH_STATE_DURATION_US,
	parameter int unsigned FULL_PERIOD_DURATION_US = servo_controller_pkg::DEFAULT_FULL_PERIOD_DURATION_US,

	parameter int unsigned MAX_ANGLE = servo_controller_pkg::DEFAULT_MAX_ANGLE
);

localparam int unsigned CNT_TICKS_FOR_FULL_PERIOD = servo_controller_pkg::calc_cnt_ticks_for_duration(FULL_PERIOD_DURATION_US, CLK_FREQ_MHz);
localparam int unsigned CNT_TICKS_FOR_MIN_HIGH_STATE = servo_controller_pkg::calc_cnt_ticks_for_duration(MIN_HIGH_STATE_DURATION_US, CLK_FREQ_MHz);
localparam int unsigned CNT_TICKS_FOR_MAX_HIGH_STATE = servo_controller_pkg::calc_cnt_ticks_for_duration(MAX_HIGH_STATE_DURATION_US, CLK_FREQ_MHz);
localparam int unsigned CNT_TICKS_FOR_ONE_DEGREE = (CNT_TICKS_FOR_MAX_HIGH_STATE - CNT_TICKS_FOR_MIN_HIGH_STATE) / 180;

logic clk_sig, nreset_sig, en_cont_sig, out_cont_sig, st_cont_is_active_sig;
logic [$clog2(MAX_ANGLE)-1:0] angle_sig;

logic out_cont_negedge_detected_sig, out_cont_posedge_detected_sig;
logic was_out_cont_negedge_reg;

servo_controller #(
    .CLK_FREQ_MHz(CLK_FREQ_MHz),
    
    .MIN_HIGH_STATE_DURATION_US(MIN_HIGH_STATE_DURATION_US),
    .MAX_HIGH_STATE_DURATION_US(MAX_HIGH_STATE_DURATION_US),
    .FULL_PERIOD_DURATION_US(FULL_PERIOD_DURATION_US),

    .MAX_ANGLE(MAX_ANGLE)
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
    en_cont_sig = 0;
    repeat (2)
	    @(posedge clk_sig);
    nreset_sig = 1;
    @(posedge clk_sig);

    angle_sig = 60;
    @(posedge clk_sig);
    en_cont_sig = 1;
    repeat (2)
        @(posedge out_cont_sig);

    repeat (100000)
        @(posedge clk_sig);
    angle_sig = 160;
    @(posedge out_cont_sig)

    repeat (500000)
        @(posedge clk_sig);
    angle_sig = 45;
    @(posedge out_cont_sig)

    en_cont_sig = 0;
    repeat (2)
        @(posedge clk_sig);

    $finish;
end

always begin
    #10 clk_sig = ~clk_sig;
end

logic out_cont_previous_val_reg;
always_ff @(posedge clk_sig) begin
    if (!nreset_sig) begin
        out_cont_previous_val_reg <= 0;
    end
    else begin
        out_cont_previous_val_reg <= out_cont_sig;
    end
end

assign out_cont_negedge_detected_sig = out_cont_previous_val_reg & ~out_cont_sig;
assign out_cont_posedge_detected_sig = ~out_cont_previous_val_reg & out_cont_sig;

int counter;
always_ff @(posedge clk_sig) begin
    if (!nreset_sig) begin
        counter <= 0;
        was_out_cont_negedge_reg <= 1'b0;
    end
    else begin
        counter <= counter + 1;

        if (out_cont_negedge_detected_sig) begin
            automatic int unsigned valid_cnt_ticks = CNT_TICKS_FOR_MIN_HIGH_STATE + (angle_sig * CNT_TICKS_FOR_ONE_DEGREE);
            was_out_cont_negedge_reg <= 1'b1;
            $display("Angle = %d", angle_sig);
            $display("Count tics in high state = %d", counter);
            $display("Valid count tics = %d", valid_cnt_ticks);
            assert(counter == valid_cnt_ticks)
                else $error("Value of counter for high state is not equal valid_cnt_ticks");
            
        end
        if (out_cont_posedge_detected_sig) begin
            if (was_out_cont_negedge_reg) begin
                was_out_cont_negedge_reg <= 1'b0;
                $display("Angle = %d", angle_sig);
                $display("Count tics for full period = %d", counter);
                $display("Valid count tics = %d", CNT_TICKS_FOR_FULL_PERIOD);
                assert(counter == CNT_TICKS_FOR_FULL_PERIOD)
                    else $error("Value of counter for full period is not equal calculated value");
            end
            counter <= 1;
        end
    end
end

endmodule: servo_controller_tb
