# servoController
This repository contains the implementation of a SG90 servo controller in SystemVerilog

## building and running test for servo
```bash
verilator --cc ./sv_models/servo_controller.sv --exe ./testbenches/sim_wrapper_servo_tb.cpp --trace-fst
make -C obj_dif -f Vservo_controller.mk Vservo_controller
./obj_dir/Vservo_controller
```

## building and running test for axiliteSlaveServo
```bash
verilator \
	--cc ./sv_models/axilite_slave_servo.sv ./sv_models/servo_controller.sv \
	--exe ./testbenches/sim_wrapper_axilite_slave_tb.cpp \
	--trace-fst
make -C obj_dir -f Vaxilite_slave_servo.mk Vaxilite_slave_servo
./obj_dir/Vaxilite_slave_servo
```

> **!Warning:** All commands are executed in the root folder. The Verilator must be installed!!!
