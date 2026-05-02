IVERILOG ?= iverilog
VVP ?= vvp

# RTL files for the full chip top (control_unit + queues + timer + scan +
# UART-to-APB bridge + APB slave wrapper). The bridge RTL is vendored
# from shalan/uart_apb_master under vendor/.
RTL_TOP_FILES := \
	rtl/hw_scheduler_top.v rtl/control_unit.v rtl/harts_apb_slave.v \
	rtl/priority_queue.v rtl/pq_cell.v rtl/sleep_queue.v rtl/timer.v \
	rtl/interrupt_ctrl.v rtl/scan_chain.v rtl/task_table.v \
	vendor/uart_apb_master/rtl/uart_apb_master.v \
	vendor/uart_apb_master/rtl/baud_gen.v \
	vendor/uart_apb_master/rtl/uart_rx.v \
	vendor/uart_apb_master/rtl/uart_tx.v \
	vendor/uart_apb_master/rtl/cmd_parser.v \
	vendor/uart_apb_master/rtl/resp_builder.v \
	vendor/uart_apb_master/rtl/apb_master.v

.PHONY: test-verilog test-pq test-sq test-tt test-timer test-top test-top-final test-ctrl test-phase1 test-bridge test-cocotb test-vcd

test-verilog: test-pq test-sq test-tt test-timer test-top test-top-final test-ctrl test-phase1 test-bridge

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
	$(IVERILOG) -g2012 -o verif/sim/top_tb verif/tb_verilog/tb_hw_scheduler_top.v $(RTL_TOP_FILES)
	$(VVP) verif/sim/top_tb

test-top-final:
	$(IVERILOG) -g2012 -o verif/sim/top_final_tb verif/tb_verilog/tb_hw_scheduler_top_final.v $(RTL_TOP_FILES)
	$(VVP) verif/sim/top_final_tb

test-bridge:
	$(IVERILOG) -g2012 -o verif/sim/bridge verif/tb_verilog/tb_uart_apb_bridge.v $(RTL_TOP_FILES)
	$(VVP) verif/sim/bridge

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
	python3 scripts/vcd_sanity.py verif/sim/tb_hw_scheduler_top_final.vcd --mode top
	python3 scripts/vcd_sanity.py verif/sim/tb_control_unit_assert.vcd --mode ctrl
	python3 scripts/vcd_sanity.py verif/sim/tb_phase1_vcd.vcd --mode phase1
	python3 scripts/vcd_sanity.py verif/sim/tb_uart_apb_bridge.vcd --mode top
