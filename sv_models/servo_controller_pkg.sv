package servo_controller_pkg
    // default parameters //
    parameter int unsigned DEFAULT_CLK_FREQ_HZ = 50_000_000;

	parameter int unsigned DEFAULT_MIN_HIGH_STATE_DURATION_US = 500;
	parameter int unsigned DEFAULT_MAX_HIGH_STATE_DURATION_US = 2_500;
	parameter int unsigned DEFAULT_FULL_PERIOD_DURATION_US = 20_000;

	parameter int unsigned DEFAULT_MAX_ANGLE = 180;

	parameter int unsigned DEFAULT_CNT_BIT_FOR_FRACT_PART = 10;

    // functions //
    function automatic real calc_CLK_PERIOD_DURATION_US(
        int unsigned clk_freq_hz_arg
    );
        return 1 / clk_freq_hz_arg * 1_000_000;
    endfunction

    function automatic int unsigned calc_CNT_TICKS_FOR_FULL_PERIOD(
        int unsigned full_period_duration_us_arg,
        real clk_period_duration_us_arg
    );
        return full_period_duration_us_arg / clk_period_duration_us_arg;
    endfunction

    function automatic int unsigned calc_CNT_TICKS_FOR_MIN_HIGH_STATE(
        int unsigned min_high_state_duration_us_arg,
        real clk_period_duration_us_arg
    );
        return min_high_state_duration_us_arg / clk_period_duration_us_arg;
    endfunction

    function automatic int unsigned calc_CNT_TICKS_FOR_MAX_HIGH_STATE(
        int unsigned max_high_state_duration_us_arg,
        real clk_period_duration_us_arg
    );
        return max_high_state_duration_us_arg / clk_period_duration_us_arg;
    endfunction

    function automatic int unsigned calc_K_VALUE(
        int unsigned cnt_ticks_for_max_high_state_arg,
        int unsigned cnt_ticks_for_min_high_state_arg,
        int unsigned cnt_bit_for_fract_part_arg
    );
        return ((cnt_ticks_for_max_high_state_arg - cnt_ticks_for_min_high_state_arg) << cnt_bit_for_fract_part_arg) / 180;
    endfunction

    function automatic logic [$clog2(CNT_TICKS_FOR_MAX_HIGH_STATE)-1:0] calc_cnt_ticks_for_high_state #(
        parameter int unsigned MAX_ANGLE,
        parameter int unsigned CNT_TICKS_FOR_MAX_HIGH_STATE
    )
    (
        logic [$clog2(MAX_ANGLE)-1:0] angle_arg,
        int unsigned cnt_ticks_for_min_high_state_arg,
        int unsigned k_value_arg,
        int unsigned cnt_bit_for_fract_part_arg
    );
        return cnt_ticks_for_min_high_state_arg + 
				((angle_arg * k_value_arg + (32'd1 << (cnt_bit_for_fract_part_arg - 1))) >> cnt_bit_for_fract_part_arg);
    endfunction

endpackage