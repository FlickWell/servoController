#include <iostream>
#include "verilated.h"
#include "verilated_fst_c.h"
#include "../obj_dir/Vservo_controller.h"

const vluint64_t HALF_PERIOD_CLK_DURATION_PS = 500000;

// func to wait n ticks
void wait_n_ticks(int cnt_ticks, VerilatedContext *v_context, Vservo_controller *dut, VerilatedFstC *tfp)
{
    int ticks_counter = 0;

    while (ticks_counter < cnt_ticks)
    {
        dut->clk = 1;
        dut->eval();
        tfp->dump(v_context->time());
        v_context->timeInc(HALF_PERIOD_CLK_DURATION_PS);

        dut->clk = 0;
        dut->eval();
        tfp->dump(v_context->time());
        v_context->timeInc(HALF_PERIOD_CLK_DURATION_PS);
        
        ticks_counter++;
    }
}

// testing at an input frequency of 1 MHz
int main(int argc, char ** argv)
{
    VerilatedContext *v_context_p = new VerilatedContext();
    v_context_p->commandArgs(argc, argv);

    Vservo_controller *top = new Vservo_controller(v_context_p);

    v_context_p->traceEverOn(true);
    VerilatedFstC * tfp = new VerilatedFstC();
    top->trace(tfp, 1);
    tfp->open("./sims_result/result_servo_tb.fst");

    v_context_p->time(0);

    top->nreset = 0;
    wait_n_ticks(1, v_context_p, top, tfp);
    top->nreset = 1;

    // angle = 0 degree
    wait_n_ticks(10, v_context_p, top, tfp);
    top->angle = 0;
    wait_n_ticks(1, v_context_p, top, tfp);
    top->en_cont = 1;
    wait_n_ticks(200000, v_context_p, top, tfp);

    //angle = 60 degree
    wait_n_ticks(2, v_context_p, top, tfp);
    top->angle = 60;
    wait_n_ticks(200000, v_context_p, top, tfp);

    // disable cont, angle = 180 deg, enable cont
    top->en_cont = 0;
    wait_n_ticks(2, v_context_p, top, tfp);
    top->angle = 180;
    wait_n_ticks(1, v_context_p, top, tfp);
    top->en_cont = 1;
    wait_n_ticks(200000, v_context_p, top, tfp);

    // angle = 30 deg
    wait_n_ticks(2, v_context_p, top, tfp);
    top->angle = 30;
    wait_n_ticks(200000, v_context_p, top, tfp);

    // disable cont
    top->en_cont = 0;
    wait_n_ticks(200000, v_context_p, top, tfp);
    

    tfp->close();
    delete tfp;
    delete top;
    delete v_context_p;

    return 0;
}
