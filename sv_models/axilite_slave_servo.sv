module AxiLiteServo #(
        parameter BASE_ADDR = 32'h4000_0000
    )
    (
    // global signals
    input logic ACLK,
    input logic ARESETn,
    
    // write address channel
    input logic [31:0] AWADDR,
    input logic AWVALID,
    output logic AWREADY,
    input logic [2:0] AWPROT,

    // write data channel
    input logic [31:0] WDATA,
    input logic [3:0] WSTRB,
    input logic WVALID,
    output logic WREADY,

    // write response channel
    output logic BVALID,
    input logic BREADY,
    output logic [1:0] BRESP,

    // read address channel
    input logic [31:0] ARADDR,
    input logic ARVALID,
    output logic ARREADY,
    input logic [2:0] ARPROT,

    // read data channel
    output logic [31:0] RDATA,
    output logic [1:0] RRESP,
    output logic RVALID,
    input logic RREADY,

    // servo_controller outputs
    output logic out_cont,
    output logic cont_is_active
    );

    // write address channel handler //
    logic awready_sig = 1'b1;
    assign AWREADY = awready_sig;

    logic [31:0] awaddr_reg;
    logic awaddr_received_flag;
    always_ff @(posedge ACLK, negedge ARESETn) begin
        if (!ARESETn) begin
            awaddr_reg <= '0;
            awaddr_received_flag <= '0;
        end
        else if (AWVALID) begin
            awaddr_reg <= AWADDR;
            awaddr_received_flag <= 1'b1;
        end
        else if (BVALID && BREADY) begin
            awaddr_received_flag <= '0;
        end
    end

    // write data channel handler //
    logic wready_sig = 1'b1;
    assign WREADY = wready_sig;

    logic [31:0] wdata_reg;
    logic wdata_received_flag;
    always_ff @(posedge ACLK, negedge ARESETn) begin
        if (!ARESETn) begin
            wdata_reg <= '0;
            wdata_received_flag <= '0;
        end
        else if (WVALID) begin
            wdata_reg <= WDATA;
            wdata_received_flag <= 1'b1;
        end
        else if (BVALID && BREADY) begin
            wdata_received_flag <= '0;
        end

    end

    // write response channel handler //
    logic w_received_data_is_valid_sig;

    // check awaddr, wdata on valid
    always_comb begin
        if ((awaddr_reg == BASE_ADDR) && (wdata_reg <= 32'd180)) begin
            w_received_data_is_valid_sig = 1'b1;
        end
        else if ((awaddr_reg == BASE_ADDR + 32'h0000_0004) && 
                (wdata_reg == '0 || wdata_reg == 32'h1111_1111)) begin
                    w_received_data_is_valid_sig = 1'b1;
        end
        else begin
            w_received_data_is_valid_sig = 1'b0;
        end
    end

    logic [1:0] bresp_reg;
    logic bvalid_reg;

    assign BRESP = bresp_reg;
    assign BVALID = bvalid_reg;

    always_ff @(posedge ACLK, negedge ARESETn) begin
        if (!ARESETn) begin
            bresp_reg <= '0;
            bvalid_reg <= '0;

            angle_reg <= '0;
            en_servo_cont_reg <= '0;
        end
        else if (BVALID && BREADY) begin
            bvalid_reg <= '0;
        end
        else begin
            if (awaddr_received_flag && wdata_received_flag) begin
                if (w_received_data_is_valid_sig) begin
                    bresp_reg <= 2'b00;
                    
                    if (awaddr_reg == BASE_ADDR) begin
                        angle_reg <= wdata_reg[7:0];
                    end
                    else begin
                        en_servo_cont_reg <= wdata_reg[0];
                    end
                end
                else begin
                    bresp_reg <= 2'b10;
                end
                bvalid_reg <= 1'b1;
            end
        end
    end

    // read address channel handler //
    logic arready_sig = 1'b1;
    assign ARREADY = arready_sig;

    logic [31:0] araddr_reg;
    logic araddr_received_flag;

    always_ff @(posedge ACLK, negedge ARESETn) begin
        if (!ARESETn) begin
            araddr_reg <= '0;
            araddr_received_flag <= '0;
        end
        else begin
            if (ARVALID) begin
                araddr_reg <= ARADDR;
                araddr_received_flag <= 1'b1;
            end
            else if (RVALID && RREADY) begin
                araddr_reg <= '0;
                araddr_received_flag = '0;
            end
        end
    end

    // read data channel handler //
    // check araddr on valid
    logic r_received_data_is_valid_sig;

    always_comb begin
        if ((araddr_reg == BASE_ADDR) || (araddr_reg == BASE_ADDR + 32'h0000_0004)) begin
            r_received_data_is_valid_sig = 1'b1;
        end
        else begin
            r_received_data_is_valid_sig = '0;
        end
    end

    logic [31:0] rdata_reg;
    logic [1:0] rresp_reg;
    logic rvalid_reg;

    assign RDATA = rdata_reg;
    assign RRESP = rresp_reg;
    assign RVALID = rvalid_reg;

    always_ff @(posedge ACLK, negedge ARESETn) begin
        if (!ARESETn) begin
            rdata_reg <= '0;
            rresp_reg <= '0;
            rvalid_reg <= '0;
        end
        else if (RVALID && RREADY) begin
            rvalid_reg <= '0;
        end
        else begin
            if (araddr_received_flag) begin
                if (r_received_data_is_valid_sig) begin
                    rresp_reg <= 2'b00;
                    
                    if (araddr_reg == BASE_ADDR) begin
                        rdata_reg <= {24'b0, angle_reg};
                    end
                    else begin
                        rdata_reg <= (en_servo_cont_reg) ? 32'h1111_1111 : '0;
                    end
                end
                else begin
                    rresp_reg <= 2'b10;
                    rdata_reg <= '0;
                end
                rvalid_reg <= 1'b1;
            end
        end
    end

    // regs for servo_controller //
    logic [7:0] angle_reg;
    logic en_servo_cont_reg;
    
    // connecting of servo_controller //
    ServoController servo_controller(
        .clk(ACLK),
        .nreset(ARESETn),
        .en_cont(en_servo_cont_reg),
        .angle(angle_reg),
        .out_cont(out_cont),
        .st_cont_is_active(cont_is_active)
    );

endmodule : AxiLiteServo