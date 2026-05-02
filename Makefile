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

VENV ?= verif/.venv
VENV_PY := $(VENV)/bin/python

.PHONY: test-all test-verilog test-pq test-sq test-tt test-timer test-top test-top-final \
	test-top-policies test-ctrl test-phase1 test-bridge test-cocotb test-pytest test-formal test-vcd \
	coverage coverage-rtl coverage-py

test-all: test-verilog test-vcd test-cocotb test-pytest test-formal

# Line coverage: Verilator (timer + priority_queue TBs) + pytest-cov (golden/sched).
coverage: coverage-rtl coverage-py

test-verilog: test-pq test-sq test-tt test-timer test-top test-top-final test-top-policies test-ctrl test-phase1 test-bridge

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

test-top-policies:
	$(IVERILOG) -g2012 -o verif/sim/policies_tb verif/tb_verilog/tb_hw_scheduler_top_policies.v $(RTL_TOP_FILES)
	$(VVP) verif/sim/policies_tb

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
	@test -d $(VENV) || python3 -m venv $(VENV)
	@$(VENV_PY) -m pip install -q -r verif/requirements.txt
	@$(VENV_PY) verif/cocotb/run_cocotb.py

test-pytest:
	@test -d $(VENV) || python3 -m venv $(VENV)
	@$(VENV_PY) -m pip install -q -r verif/requirements.txt
	@$(VENV_PY) -m pytest -q verif/tb/test_golden_model.py verif/tb/test_sched_modes.py verif/tb/test_rtl_regression.py

test-formal:
	@cd formal && sby -f timer_bmc.sby

coverage-rtl:
	@command -v verilator >/dev/null 2>&1 || { echo "coverage-rtl: install Verilator"; exit 1; }
	@bash scripts/rtl_coverage.sh

coverage-py:
	@test -d $(VENV) || python3 -m venv $(VENV)
	@$(VENV_PY) -m pip install -q -r verif/requirements.txt
	@PYTHONPATH=verif/tb $(VENV_PY) -m pytest -q verif/tb/test_golden_model.py verif/tb/test_sched_modes.py \
		--cov=golden_model --cov=test_sched_modes --cov-branch \
		--cov-report=term-missing --cov-report=html:verif/sim/coverage_py_html
	@echo "coverage-py: HTML -> verif/sim/coverage_py_html/index.html"

test-vcd:
	python3 scripts/vcd_sanity.py verif/sim/tb_priority_queue.vcd --mode pq
	python3 scripts/vcd_sanity.py verif/sim/tb_sleep_queue.vcd --mode sq
	python3 scripts/vcd_sanity.py verif/sim/tb_hw_scheduler_top.vcd --mode top
	python3 scripts/vcd_sanity.py verif/sim/tb_hw_scheduler_top_final.vcd --mode top
	python3 scripts/vcd_sanity.py verif/sim/tb_hw_scheduler_top_policies.vcd --mode top
	python3 scripts/vcd_sanity.py verif/sim/tb_control_unit_assert.vcd --mode ctrl
	python3 scripts/vcd_sanity.py verif/sim/tb_phase1_vcd.vcd --mode phase1
	python3 scripts/vcd_sanity.py verif/sim/tb_uart_apb_bridge.vcd --mode top
