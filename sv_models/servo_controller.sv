module servo_controller #(
	parameter int unsigned CLK_FREQ_HZ = 50_000_000,

	parameter int unsigned MIN_HIGH_STATE_DURATION_US = 500,
	parameter int unsigned MAX_HIGH_STATE_DURATION_US = 2_500,
	parameter int unsigned FULL_PERIOD_DURATION_US = 20_000,

	parameter int unsigned MAX_ANGLE = 180,

	parameter int unsigned CNT_BIT_FOR_FRACT_PART = 10
)
(
	input logic clk,
	input logic nreset,
	input logic en_cont,
	input logic [7:0] angle,

	output logic out_cont,
	output logic st_cont_is_active
	);

	// localparams
	localparam real CLK_PERIOD_DURATION_US = 1 / CLK_FREQ_HZ * 1_000_000;

	localparam int unsigned CNT_TICKS_FOR_FULL_PERIOD = FULL_PERIOD_DURATION_US / CLK_PERIOD_DURATION_US;
	localparam int unsigned CNT_TICKS_FOR_MIN_HIGH_STATE = 
		MIN_HIGH_STATE_DURATION_US / CLK_PERIOD_DURATION_US;
	localparam int unsigned CNT_TICKS_FOR_MAX_HIGH_STATE = 
		MAX_HIGH_STATE_DURATION_US / CLK_PERIOD_DURATION_US;

	localparam int unsigned K_VALUE = 
		((CNT_TICKS_FOR_MAX_HIGH_STATE - CNT_TICKS_FOR_MIN_HIGH_STATE) << CNT_BIT_FOR_FRACT_PART) / 180;

	// states of controller
	typedef enum logic [1:0] {
		IDLE,
		CONT_EN_H,
		CONT_EN_L
	} statetype;
	
	statetype state, nextstate;

	// reg of state
	always_ff @(posedge clk, negedge nreset) begin
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
	logic [31:0] cnt_ticks;
	always_ff @(posedge clk, negedge nreset) begin
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
	logic [7:0] next_angle;
	always_ff @(posedge clk, negedge nreset) begin
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
	logic [31:0] cnt_high_ticks_sig;
	logic [31:0] cnt_high_ticks_reg;

	always_comb begin
		if (next_angle == '0) begin
			cnt_high_ticks_sig = CNT_TICKS_FOR_MIN_HIGH_STATE;
		end
		else begin
			cnt_high_ticks_sig = CNT_TICKS_FOR_MIN_HIGH_STATE + 
				(next_angle * K_VALUE + (1 << (CNT_BIT_FOR_FRACT_PART - 1)) >> CNT_BIT_FOR_FRACT_PART);
		end
	end

	always_ff @(posedge clk, negedge nreset) begin
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
