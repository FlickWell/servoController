package servo_controller_pkg;
    // default parameters //
    parameter int unsigned DEFAULT_CLK_FREQ_MHz = 50;

	parameter int unsigned DEFAULT_MIN_HIGH_STATE_DURATION_US = 500;
	parameter int unsigned DEFAULT_MAX_HIGH_STATE_DURATION_US = 2_500;
	parameter int unsigned DEFAULT_FULL_PERIOD_DURATION_US = 20_000;

	parameter int unsigned DEFAULT_MAX_ANGLE = 180;

    // functions //
    function automatic int unsigned calc_cnt_ticks_for_duration(
        int unsigned duration_us_,
        int unsigned clk_freq_mhz_
    );
        return duration_us_ * clk_freq_mhz_;
    endfunction

endpackage: servo_controller_pkg
