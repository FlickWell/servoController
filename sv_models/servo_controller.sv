module servo_controller #(
	parameter int unsigned CLK_FREQ_MHz,

	parameter int unsigned MIN_HIGH_STATE_DURATION_US,
	parameter int unsigned MAX_HIGH_STATE_DURATION_US,
	parameter int unsigned FULL_PERIOD_DURATION_US,

	parameter int unsigned MAX_ANGLE
)
(
	input logic clk,
	input logic nreset,
	input logic en_cont,
	input logic [$clog2(MAX_ANGLE)-1:0] angle,

	output logic out_cont,
	output logic st_cont_is_active
	);

	// localparams
	localparam int unsigned CNT_TICKS_FOR_FULL_PERIOD = servo_controller_pkg::calc_cnt_ticks_for_duration(FULL_PERIOD_DURATION_US, CLK_FREQ_MHz);
	localparam int unsigned CNT_TICKS_FOR_MIN_HIGH_STATE = servo_controller_pkg::calc_cnt_ticks_for_duration(MIN_HIGH_STATE_DURATION_US, CLK_FREQ_MHz);
	localparam int unsigned CNT_TICKS_FOR_MAX_HIGH_STATE = servo_controller_pkg::calc_cnt_ticks_for_duration(MAX_HIGH_STATE_DURATION_US, CLK_FREQ_MHz);
	localparam int unsigned CNT_TICKS_FOR_ONE_DEGREE = (CNT_TICKS_FOR_MAX_HIGH_STATE - CNT_TICKS_FOR_MIN_HIGH_STATE) / 180;

	// signals and registers
	logic [$clog2(CNT_TICKS_FOR_FULL_PERIOD)-1:0] cnt_ticks;

	logic [$clog2(MAX_ANGLE)-1:0] next_angle;

	logic [$clog2(CNT_TICKS_FOR_MAX_HIGH_STATE)-1:0] cnt_high_ticks_sig;
	logic [$clog2(CNT_TICKS_FOR_MAX_HIGH_STATE)-1:0] cnt_high_ticks_reg;

	// states of controller
	typedef enum logic [1:0] {
		IDLE,
		CONT_EN_H,
		CONT_EN_L
	} state_t;
	
	state_t state, nextstate;

	// reg of state
	always_ff @(posedge clk) begin
		if (~nreset) begin
			state <= IDLE;
		end
		else begin
			state <= nextstate;
		end
	end

	// control of state machine
	always_comb begin
		case (state)
			IDLE: begin
				if (en_cont) begin
					nextstate = CONT_EN_H;
				end
				else begin
					nextstate = IDLE;
				end
			end
			CONT_EN_H: begin
				if (cnt_ticks == cnt_high_ticks_reg - 1) begin
					if (en_cont) begin
						nextstate = CONT_EN_L;
					end
					else begin
						nextstate = IDLE;
					end
				end
				else begin
					nextstate = CONT_EN_H;
				end
			end
			CONT_EN_L: begin
				if (cnt_ticks == CNT_TICKS_FOR_FULL_PERIOD - 1) begin
					if (en_cont) begin
						nextstate = CONT_EN_H;
					end
					else begin
						nextstate = IDLE;
					end
				end
				else begin
					nextstate = CONT_EN_L;
				end
			end
			default: begin
				nextstate = IDLE;
			end
		endcase
	end

	// counter
	always_ff @(posedge clk) begin
		if (!nreset || state == IDLE) begin
			cnt_ticks <= 0;
		end
		else if (cnt_ticks == CNT_TICKS_FOR_FULL_PERIOD - 1) begin
			cnt_ticks <= 0;
		end
		else begin
			cnt_ticks <= cnt_ticks + 1;
		end
	end

	// control new angle
	always_ff @(posedge clk) begin
		if (!nreset) begin
			next_angle <= 0;
		end
		else begin
			if (!en_cont) begin
				next_angle <= angle;
			end
			else if (cnt_ticks == CNT_TICKS_FOR_FULL_PERIOD - 1) begin
				next_angle <= angle;
			end
		end
	end

	// calculate cnt_ticks for high and low states
	always_comb begin
		if (next_angle == '0) begin
			cnt_high_ticks_sig = CNT_TICKS_FOR_MIN_HIGH_STATE;
		end
		else begin
			cnt_high_ticks_sig = CNT_TICKS_FOR_MIN_HIGH_STATE + (next_angle * CNT_TICKS_FOR_ONE_DEGREE);
		end
	end

	always_ff @(posedge clk) begin
		if (!nreset) begin
			cnt_high_ticks_reg <= 0;
		end
		else begin
			cnt_high_ticks_reg <= cnt_high_ticks_sig;
		end
	end

// output signals
assign out_cont = (state == CONT_EN_H) ? 1'b1 : 1'b0;
assign st_cont_is_active = (state == CONT_EN_H || state == CONT_EN_L) ? 1'b1 : 1'b0;
	
endmodule : servo_controller
