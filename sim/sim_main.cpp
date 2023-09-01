#include <memory>
#include <verilated.h>
#include "Vtop.h"

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    const std::unique_ptr<Vtop> top{new Vtop};
    top->clk   = 0;
    top->rst_n = 0;

    while (!Verilated::gotFinish()) {
        main_time++;
        top->clk = !top->clk;
        if (main_time==10) {
            top->rst_n = 1;
        }
        top->eval();
    }

    top->final();
    return 0;
}
