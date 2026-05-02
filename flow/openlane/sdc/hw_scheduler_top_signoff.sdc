# hw_scheduler_top — Signoff-oriented SDC (sky130)
# Structured like Caravel/aes_wb_wrapper signoff.sdc; relaxed max_transition vs PnR.

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

set_case_analysis 0 [get_ports scan_en]

# Clock non-idealities
set_propagated_clock [get_clocks {clk}]
set_clock_uncertainty 0.1 [get_clocks {clk}]
puts "\[INFO\]: Setting clock uncertainty to: 0.1"

# Maximum transition time for the design nets
set_max_transition 1.5 [current_design]
puts "\[INFO\]: Setting maximum transition to: 1.5"

# Maximum fanout (17 seen on one CTS branch vs limit 16 — allow headroom)
set_max_fanout 24 [current_design]
puts "\[INFO\]: Setting maximum fanout to: 24"

# No incremental derate: corner libs (min/nom/max) already span PVT. Stacking ±5%
# late derate on max_ss blew setup by hundreds of paths; PnR SDC matches that choice.

#------------------------------------------#
# Multicycle paths
#------------------------------------------#
# None at this IP boundary; add in wrapper SDC when bus fabric ports exist.

#------------------------------------------#
# Retrieved constraints — replace at SoC integration
#------------------------------------------#

set clk_max_latency 0.0
set clk_min_latency 0.0
set_clock_latency -source -max $clk_max_latency [get_clocks {clk}]
set_clock_latency -source -min $clk_min_latency [get_clocks {clk}]
puts "\[INFO\]: Setting clock latency range: $clk_min_latency : $clk_max_latency"

# Clock input transition
set_input_transition 0.61 [get_ports $clk_input]

# Input delays (slightly relaxed vs PnR, same pattern as reference signoff.sdc)
set_input_delay -max 3.17 -clock [get_clocks {clk}] [get_ports {scan_in}]
set_input_delay -max 3.74 -clock [get_clocks {clk}] [get_ports {scan_en}]
set_input_delay -max 3.89 -clock [get_clocks {clk}] [get_ports {ext_irq[*]}]
set_input_delay -max 4.61 -clock [get_clocks {clk}] [get_ports {uart_rx}]

set_input_delay -min 0.79 -clock [get_clocks {clk}] [get_ports {ext_irq[*]}]
# Min delay: hold at max_tt was −33 ps uart_rx → _47725_; +50 ps margin vs 0.22
set_input_delay -min 0.27 -clock [get_clocks {clk}] [get_ports {uart_rx}]
set_input_delay -min 0.79 -clock [get_clocks {clk}] [get_ports {scan_in}]
set_input_delay -min 0.79 -clock [get_clocks {clk}] [get_ports {scan_en}]

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

# Output delays
set_output_delay -max 3.62 -clock [get_clocks {clk}] [get_ports {uart_tx}]
set_output_delay -max [expr {$CLK_PERIOD * 0.34}] -clock [get_clocks {clk}] [get_ports {irq_n}]
set_output_delay -max 3.62 -clock [get_clocks {clk}] [get_ports {scan_out}]
set_output_delay -min 1.13 -clock [get_clocks {clk}] [get_ports {uart_tx}]
set_output_delay -min 1.37 -clock [get_clocks {clk}] [get_ports {irq_n}]
set_output_delay -min 1.13 -clock [get_clocks {clk}] [get_ports {scan_out}]

# Output loads
set_load 0.19 [all_outputs]
