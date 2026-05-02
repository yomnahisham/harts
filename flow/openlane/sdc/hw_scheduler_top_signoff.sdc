# hw_scheduler_top — Signoff-oriented SDC (sky130)
# Block-level defaults; tighten latencies / mins when closing chip-level timing.

set CLK_PERIOD 25
set clk_input clk

create_clock [get_ports $clk_input] -name clk -period $CLK_PERIOD
puts "\[INFO\]: Creating clock {clk} for port $clk_input with period: $CLK_PERIOD"

# set_propagated_clock [get_clocks {clk}]
set_clock_uncertainty 0.1 [get_clocks {clk}]
puts "\[INFO\]: Setting clock uncertainty to: 0.1"

set_max_transition 1.5 [current_design]
set_max_fanout 16 [current_design]

set_timing_derate -early [expr {1-0.05}]
set_timing_derate -late [expr {1+0.05}]
puts "\[INFO\]: Setting timing derate to: [expr {0.05 * 100}] %"

set_clock_latency -source -max 0.0 [get_clocks {clk}]
set_clock_latency -source -min 0.0 [get_clocks {clk}]
puts "\[INFO\]: Source clock latency 0 (macro boundary)"

set_input_transition 0.61 [get_ports $clk_input]

set_input_delay -max 3.17 -clock [get_clocks {clk}] [get_ports {scan_in}]
set_input_delay -max 3.74 -clock [get_clocks {clk}] [get_ports {scan_en}]
set_input_delay -max 3.89 -clock [get_clocks {clk}] [get_ports {ext_irq[*]}]
set_input_delay -max 4.13 -clock [get_clocks {clk}] [get_ports {sclk}]
set_input_delay -max 4.61 -clock [get_clocks {clk}] [get_ports {mosi}]
set_input_delay -max 4.74 -clock [get_clocks {clk}] [get_ports {cs_n}]

set_input_delay -min 0.0 -clock [get_clocks {clk}] [get_ports {ext_irq[*]}]
set_input_delay -min 0.0 -clock [get_clocks {clk}] [get_ports {mosi}]
set_input_delay -min 0.0 -clock [get_clocks {clk}] [get_ports {scan_in}]
set_input_delay -min 0.0 -clock [get_clocks {clk}] [get_ports {scan_en}]
set_input_delay -min 0.0 -clock [get_clocks {clk}] [get_ports {cs_n}]
set_input_delay -min 0.0 -clock [get_clocks {clk}] [get_ports {sclk}]

set_input_delay -max [expr {$CLK_PERIOD * 0.5}] -clock [get_clocks {clk}] [get_ports {rst_n}]
set_input_delay -min 0.0 -clock [get_clocks {clk}] [get_ports {rst_n}]

set_input_transition -max 0.14  [get_ports {scan_en}]
set_input_transition -max 0.15  [get_ports {sclk}]
set_input_transition -max 0.17  [get_ports {cs_n}]
set_input_transition -max 0.18  [get_ports {scan_in}]
set_input_transition -max 0.84  [get_ports {mosi}]
set_input_transition -max 0.92  [get_ports {ext_irq[*]}]
set_input_transition -min 0.07  [get_ports {ext_irq[*]}]
set_input_transition -min 0.07  [get_ports {mosi}]
set_input_transition -min 0.09  [get_ports {cs_n}]
set_input_transition -min 0.09  [get_ports {scan_in}]
set_input_transition -min 0.09  [get_ports {scan_en}]
set_input_transition -min 0.15  [get_ports {sclk}]

set_output_delay -max 3.62 -clock [get_clocks {clk}] [get_ports {miso}]
set_output_delay -max 8.41 -clock [get_clocks {clk}] [get_ports {irq_n}]
set_output_delay -max 3.62 -clock [get_clocks {clk}] [get_ports {scan_out}]
set_output_delay -min 0.0 -clock [get_clocks {clk}] [get_ports {miso}]
set_output_delay -min 0.0 -clock [get_clocks {clk}] [get_ports {irq_n}]
set_output_delay -min 0.0 -clock [get_clocks {clk}] [get_ports {scan_out}]

set_load 0.19 [all_outputs]
