# hw_scheduler_top — PnR-oriented SDC (sky130)
# Structured like Caravel/aes_wb_wrapper pnr.sdc; ports and budgets match this block.
# OpenLane sets $::env(CLOCK_PERIOD) from config.json before reading this file.

if {[info exists ::env(CLOCK_PERIOD)]} {
  set CLK_PERIOD $::env(CLOCK_PERIOD)
} else {
  set CLK_PERIOD 25
}
set clk_input clk

#------------------------------------------#
# Design constraints
#------------------------------------------#

# Clock network
create_clock [get_ports $clk_input] -name clk -period $CLK_PERIOD
puts "\[INFO\]: Creating clock {clk} for port $clk_input with period: $CLK_PERIOD"

# Functional STA: scan_chain loads parallel_in when scan_en=0 (scan_chain.v).
set_case_analysis 0 [get_ports scan_en]

# Clock non-idealities
# Ideal clock at the port for pre-CTS / yosys netlist STA (synexp, floorplan, pre-CTS).
# After CTS, OpenLane/signoff may use propagated delay on the clock tree — do not
# set_propagated_clock here or SS reg–reg is pessimized with no real skew to model.
# Pre-CTS / gate-level STA: keep small; post-route signoff SDC still uses 0.1 ns.
set_clock_uncertainty 0.06 [get_clocks {clk}]
puts "\[INFO\]: Setting clock uncertainty to: 0.06"

# Maximum transition time for the design nets
set_max_transition 0.75 [current_design]
puts "\[INFO\]: Setting maximum transition to: 0.75"

# Slightly above 16 so post-CTS buffers with 17 sinks do not false-fail max_fanout reports
set_max_fanout 24 [current_design]
puts "\[INFO\]: Setting maximum fanout to: 24"

# No incremental derate on this netlist: sky130 SS/FF corners already span PVT.
# aes_wb_wrapper uses ±7% on a taped-out chip; stacking that on gate-level + SS
# blew synexp (e.g. sleep_queue cnt_mem paths). Re-enable ±7% in a wrapper SDC
# at SoC signoff if your methodology requires OCV on top of corners.

#------------------------------------------#
# Multicycle paths
#------------------------------------------#
# This top is UART / IRQ / scan — no Wishbone wbs_* ports. Multicycle through bus
# ack/cyc/stb belongs in a Caravel (or other) wrapper SDC when those nets exist.

#------------------------------------------#
# Retrieved constraints — replace at SoC integration (Caravel pad / harness)
#------------------------------------------#

# Clock source latency (0 at IP core; paste extracted values when hardening in chip)
set clk_max_latency 0.0
set clk_min_latency 0.0
set_clock_latency -source -max $clk_max_latency [get_clocks {clk}]
set_clock_latency -source -min $clk_min_latency [get_clocks {clk}]
puts "\[INFO\]: Setting clock latency range: $clk_min_latency : $clk_max_latency"

# Clock input transition
set_input_transition 0.61 [get_ports $clk_input]

# Input delays (max budgets aligned to aes_wb-style magnitudes; scaled to this port list)
set_input_delay -max 3.27 -clock [get_clocks {clk}] [get_ports {scan_in}]
set_input_delay -max 3.84 -clock [get_clocks {clk}] [get_ports {scan_en}]
set_input_delay -max 3.99 -clock [get_clocks {clk}] [get_ports {ext_irq[*]}]
set_input_delay -max 4.71 -clock [get_clocks {clk}] [get_ports {uart_rx}]

set_input_delay -min 0.0 -clock [get_clocks {clk}] [get_ports {ext_irq[*]}]
set_input_delay -min 0.27 -clock [get_clocks {clk}] [get_ports {uart_rx}]
set_input_delay -min 0.0 -clock [get_clocks {clk}] [get_ports {scan_in}]
set_input_delay -min 0.0 -clock [get_clocks {clk}] [get_ports {scan_en}]

# Reset input delay (recovery / max arrival vs clk — same 0.5×period idea as wb_rst_i)
set_input_delay -max [expr {$CLK_PERIOD * 0.5}] -clock [get_clocks {clk}] [get_ports {rst_n}]
set_input_delay -min 0.85 -clock [get_clocks {clk}] [get_ports {rst_n}]

# Input transition
set_input_transition -max 0.14  [get_ports {scan_en}]
set_input_transition -max 0.18  [get_ports {scan_in}]
set_input_transition -max 0.84  [get_ports {uart_rx}]
set_input_transition -max 0.92  [get_ports {ext_irq[*]}]
set_input_transition -min 0.07  [get_ports {ext_irq[*]}]
set_input_transition -min 0.07  [get_ports {uart_rx}]
set_input_transition -min 0.09  [get_ports {scan_in}]
set_input_transition -min 0.09  [get_ports {scan_en}]

# Output delays (max + min for board/pad hold, same pattern as wbs_dat_o / wbs_ack_o)
set_output_delay -max 3.72 -clock [get_clocks {clk}] [get_ports {uart_tx}]
set_output_delay -max [expr {$CLK_PERIOD * 0.34}] -clock [get_clocks {clk}] [get_ports {irq_n}]
set_output_delay -max 3.72 -clock [get_clocks {clk}] [get_ports {scan_out}]
set_output_delay -min 0.0 -clock [get_clocks {clk}] [get_ports {uart_tx}]
set_output_delay -min 0.0 -clock [get_clocks {clk}] [get_ports {irq_n}]
set_output_delay -min 0.0 -clock [get_clocks {clk}] [get_ports {scan_out}]

# Output loads
set_load 0.19 [all_outputs]
