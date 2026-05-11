## Clock signal
set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports { sysclk }];
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { sysclk }];

## Hardware Reset Button (BTN0)
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { btn[0] }];

## Mode Select Switch (SW0)
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { sw[0] }];

## Diagnostic LEDs
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { led[3] }];

## Pmod Header JD (PMOD NAV)
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { nav_cs }];
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports { nav_mosi }];
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { nav_miso }];
set_property -dict { PACKAGE_PIN R14   IOSTANDARD LVCMOS33 } [get_ports { nav_sclk }];

## Pmod Header JC (PMOD JSTK2, top row)
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { jstk_cs }];
set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS33 } [get_ports { jstk_mosi }];
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { jstk_miso }];
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { jstk_sclk }];
