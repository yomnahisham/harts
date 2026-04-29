IVERILOG ?= iverilog
VVP ?= vvp

.PHONY: test-verilog test-pq test-sq test-tt test-timer test-top test-ctrl test-phase1 test-cocotb test-vcd

test-verilog: test-pq test-sq test-tt test-timer test-top test-ctrl test-phase1

test-pq:
	$(IVERILOG) -g2012 -o verif/sim/pq verif/tb_verilog/tb_priority_queue.v rtl/priority_queue.v rtl/pq_cell.v
	$(VVP) verif/sim/pq

test-sq:
	$(IVERILOG) -g2012 -o verif/sim/sq verif/tb_verilog/tb_sleep_queue.v rtl/sleep_queue.v
	$(VVP) verif/sim/sq

test-tt:
	$(IVERILOG) -g2012 -o verif/sim/tt verif/tb_verilog/tb_task_table.v rtl/task_table.v
	$(VVP) verif/sim/tt

test-timer:
	$(IVERILOG) -g2012 -o verif/sim/tm verif/tb_verilog/tb_timer.v rtl/timer.v
	$(VVP) verif/sim/tm

test-top:
	$(IVERILOG) -g2012 -o verif/sim/top_tb verif/tb_verilog/tb_hw_scheduler_top.v \
		rtl/hw_scheduler_top.v rtl/control_unit.v rtl/spi_slave_if.v \
		rtl/priority_queue.v rtl/pq_cell.v rtl/sleep_queue.v rtl/timer.v \
		rtl/interrupt_ctrl.v rtl/scan_chain.v rtl/task_table.v
	$(VVP) verif/sim/top_tb

test-ctrl:
	$(IVERILOG) -g2012 -o verif/sim/ctrl verif/tb_verilog/tb_control_unit_assert.v \
		rtl/control_unit.v rtl/task_table.v rtl/priority_queue.v rtl/pq_cell.v \
		rtl/sleep_queue.v rtl/timer.v
	$(VVP) verif/sim/ctrl

test-phase1:
	$(IVERILOG) -g2012 -o verif/sim/phase1_vcd verif/tb_verilog/tb_phase1_vcd.v \
		rtl/control_unit.v rtl/task_table.v rtl/priority_queue.v rtl/pq_cell.v \
		rtl/sleep_queue.v rtl/timer.v
	$(VVP) verif/sim/phase1_vcd

test-cocotb:
	@echo "run cocotb tests with your simulator and pytest plugin setup"

test-vcd:
	python3 scripts/vcd_sanity.py verif/sim/tb_priority_queue.vcd --mode pq
	python3 scripts/vcd_sanity.py verif/sim/tb_sleep_queue.vcd --mode sq
	python3 scripts/vcd_sanity.py verif/sim/tb_hw_scheduler_top.vcd --mode top
	python3 scripts/vcd_sanity.py verif/sim/tb_control_unit_assert.vcd --mode ctrl
	python3 scripts/vcd_sanity.py verif/sim/tb_phase1_vcd.vcd --mode phase1
