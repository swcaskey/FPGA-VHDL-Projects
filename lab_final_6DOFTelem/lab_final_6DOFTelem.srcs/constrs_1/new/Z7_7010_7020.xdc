## Clock signal (125 MHz)
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { sysclk }]; # [cite: 797]
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { sysclk }]; # [cite: 798]

## Hardware Reset Button (BTN0)
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { btn[0] }]; # [cite: 799]

## Mode Select Switch (SW0)
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { sw[0] }]; # [cite: 800]

## Diagnostic LEDs
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led[0] }]; # [cite: 801]
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { led[1] }]; # [cite: 802]
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { led[2] }]; # [cite: 803]
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { led[3] }]; # [cite: 804]

## Pmod Header JD (PMOD NAV - Top Row Pins 1-4)
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { nav_cs }];   # JD Pin 1 (CS Q_A/G) [cite: 587, 805]
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports { nav_mosi }]; # JD Pin 2 (SDI) [cite: 587, 806]
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { nav_miso }]; # JD Pin 3 (SDO) [cite: 587, 807]
set_property -dict { PACKAGE_PIN R14   IOSTANDARD LVCMOS33 } [get_ports { nav_sclk }]; # JD Pin 4 (SCK) [cite: 587, 808]

## Pmod Header JC (PMOD JSTK2 - Top Row Pins 1-4)
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { jstk_cs }];   # JC Pin 1 [cite: 809]
set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS33 } [get_ports { jstk_mosi }]; # JC Pin 2 [cite: 810]
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { jstk_miso }]; # JC Pin 3 [cite: 811]
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { jstk_sclk }]; # JC Pin 4 [cite: 812]