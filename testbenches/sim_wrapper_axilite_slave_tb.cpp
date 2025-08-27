#include "verilated.h"
#include "verilated_fst_c.h"
#include "../obj_dir/Vaxilite_slave_servo.h"
#include <iostream>

#define ANGLE_REG 0x40000000
#define CTRL_REG (ANGLE_REG + 0x4)

const vluint64_t HALF_PERIOD_CLK_DURATION_PS = 500000;

void wait_n_ticks(int cnt_ticks,
                 VerilatedContext* v_context_p, 
                 Vaxilite_slave_servo* top_p, 
                 VerilatedFstC* tfp_p)
{
    int ticks_counter = 0;

    while (ticks_counter < cnt_ticks)
    {
        top_p->ACLK = 1;
        top_p->eval();
        tfp_p->dump(v_context_p->time());
        v_context_p->timeInc(HALF_PERIOD_CLK_DURATION_PS);

        top_p->ACLK = 0;
        top_p->eval();
        tfp_p->dump(v_context_p->time());
        v_context_p->timeInc(HALF_PERIOD_CLK_DURATION_PS);

        ticks_counter++;
    }
}

// тестирование при входной частоте 1 МГц
int main(int argc, char** argv)
{
    VerilatedContext* v_context_p = new VerilatedContext;
    v_context_p->commandArgs(argc, argv);

    Vaxilite_slave_servo* top_p = new Vaxilite_slave_servo;

    v_context_p->traceEverOn(true);
    VerilatedFstC* tfp_p = new VerilatedFstC;
    top_p->trace(tfp_p, 1);
    tfp_p->open("./sims_result/result_axilite_slave_servo.fst");

    v_context_p->time(0);

    // reset
    top_p->ARESETn = 0;
    wait_n_ticks(2, v_context_p, top_p, tfp_p);
    top_p->ARESETn = 1;
    wait_n_ticks(5, v_context_p, top_p, tfp_p);

    // send address angle_reg and angle 60 degree
    top_p->AWADDR = (vluint32_t) ANGLE_REG;
    top_p->AWVALID = 1;
    top_p->WDATA = (vluint32_t) 0x3c;
    top_p->WSTRB = (vluint8_t) 0b11111111;
    top_p->WVALID = 1;
    wait_n_ticks(1, v_context_p, top_p, tfp_p);
    top_p->AWVALID = 0;
    top_p->WVALID = 0;

    // wait bresponse
    while (!top_p->BVALID)
    {
        wait_n_ticks(1, v_context_p, top_p, tfp_p);
    }
    top_p->BREADY = 1;
    wait_n_ticks(1, v_context_p, top_p, tfp_p);
    vluint8_t bresp = top_p->BRESP;
    top_p->BREADY = 0;
    std::cout << "After send angle response = " << +bresp << std::endl;
    std::cout << std::endl;

    wait_n_ticks(10, v_context_p, top_p, tfp_p);

    // send address ctrl_reg and en_cont
    top_p->AWADDR = (vluint32_t) CTRL_REG;
    top_p->AWVALID = 1;
    top_p->WDATA = (vluint32_t) 0x11111111;
    top_p->WSTRB = (uint8_t) 0b11111111;
    top_p->WVALID = 1;
    wait_n_ticks(1, v_context_p, top_p, tfp_p);
    top_p->AWVALID = 0;
    top_p->WVALID = 0;

    // wait response
    while (!top_p->BVALID)
    {
        wait_n_ticks(1, v_context_p, top_p, tfp_p);
    }
    top_p->BREADY = 1;
    wait_n_ticks(1, v_context_p, top_p, tfp_p);
    bresp = top_p->BRESP;
    top_p->BREADY = 0;
    std::cout << "After send en_cont signal response = " << +bresp << std::endl;
    std::cout << std::endl;

    wait_n_ticks(40000, v_context_p, top_p, tfp_p);

    // read data from ANGLE_REG
    top_p->ARADDR = (vluint32_t) ANGLE_REG;
    top_p->ARVALID = 1;
    wait_n_ticks(1, v_context_p, top_p, tfp_p);
    top_p->ARVALID = 0;

    //wait response
    while (!top_p->RVALID)
    {
        wait_n_ticks(1, v_context_p, top_p, tfp_p);
    }
    top_p->RREADY = 1;
    wait_n_ticks(1, v_context_p, top_p, tfp_p);
    vluint32_t received_data = top_p->RDATA;
    vluint8_t rresp = top_p->RRESP;
    top_p->RREADY = 0;
    std::cout << "After read data from ANGLE_REG response = " << +rresp << std::endl;
    std::cout << "After read data from ANGLE_REG data = " << +received_data << std::endl;
    std::cout << std::endl;

    wait_n_ticks(40000, v_context_p, top_p, tfp_p);

    // read data from CTRL_REG
    top_p->ARADDR = (vluint32_t) CTRL_REG;
    top_p->ARVALID = 1;
    wait_n_ticks(1, v_context_p, top_p, tfp_p);
    top_p->ARVALID = 0;

    while (!top_p->RVALID)
    {
        wait_n_ticks(1, v_context_p, top_p, tfp_p);
    }
    top_p->RREADY = 1;
    wait_n_ticks(1, v_context_p, top_p, tfp_p);
    received_data = top_p->RDATA;
    rresp = top_p->RRESP;
    top_p->RREADY = 0;
    std::cout << "After read data from CTRL_REG response = " << +rresp << std::endl;
    std::cout << "After read data from CTRL_REG data = " << +received_data << std::endl;
    std::cout << std::endl;

    wait_n_ticks(20000, v_context_p, top_p, tfp_p);

    tfp_p->close();
    delete tfp_p;
    delete top_p;
    delete v_context_p;

    return 0;
}

