module ServoController(
	input logic clk,
	input logic nreset,
	input logic en_cont,
	input logic [7:0] angle,

	output logic out_cont,
	output logic st_cont_is_active
	);

	// localparams
	localparam INPUT_FREQ_HZ = 1_000_000;
	localparam PERIOD_DURATION_IN_TICKS = INPUT_FREQ_HZ / 1000 * 20;
	localparam ONE_DEGREE_IN_TICKS = 11;
	localparam ADDING_FOR_TIME_RANGE_IN_TICKS = 500;

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
				if (cnt_ticks == PERIOD_DURATION_IN_TICKS - 1) begin
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
		else if (cnt_ticks == PERIOD_DURATION_IN_TICKS - 1) begin
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
			else if (cnt_ticks == PERIOD_DURATION_IN_TICKS - 1) begin
				next_angle <= angle;
			end
		end
	end

	// calculate cnt_ticks for high and low states
	logic [31:0] cnt_high_ticks_sig;
	logic [31:0] cnt_high_ticks_reg;

	always_comb begin
		if (next_angle == '0) begin
			cnt_high_ticks_sig = ADDING_FOR_TIME_RANGE_IN_TICKS;
		end
		else begin
			cnt_high_ticks_sig = ADDING_FOR_TIME_RANGE_IN_TICKS + (next_angle * ONE_DEGREE_IN_TICKS);
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
	
endmodule : ServoController
