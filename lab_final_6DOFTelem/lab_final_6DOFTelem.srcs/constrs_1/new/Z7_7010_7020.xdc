## Clock signal
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { sysclk }];
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { sysclk }];

## Hardware Reset Button (BTN0)
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { btn[0] }];

## HDMI TX (Video Output)
set_property -dict { PACKAGE_PIN H17   IOSTANDARD TMDS_33 } [get_ports { TMDS_Clk_n }];
set_property -dict { PACKAGE_PIN H16   IOSTANDARD TMDS_33 } [get_ports { TMDS_Clk_p }];
set_property -dict { PACKAGE_PIN D20   IOSTANDARD TMDS_33 } [get_ports { TMDS_Data_n[0] }];
set_property -dict { PACKAGE_PIN D19   IOSTANDARD TMDS_33 } [get_ports { TMDS_Data_p[0] }];
set_property -dict { PACKAGE_PIN B20   IOSTANDARD TMDS_33 } [get_ports { TMDS_Data_n[1] }];
set_property -dict { PACKAGE_PIN C20   IOSTANDARD TMDS_33 } [get_ports { TMDS_Data_p[1] }];
set_property -dict { PACKAGE_PIN A20   IOSTANDARD TMDS_33 } [get_ports { TMDS_Data_n[2] }];
set_property -dict { PACKAGE_PIN B19   IOSTANDARD TMDS_33 } [get_ports { TMDS_Data_p[2] }];

## Pmod Header JA (PMOD NAV - Top Row)
set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { nav_cs }];
set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33 } [get_ports { nav_mosi }];
set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports { nav_miso }];
set_property -dict { PACKAGE_PIN K14   IOSTANDARD LVCMOS33 } [get_ports { nav_sclk }];

## Pmod Header JC (PMOD JSTK2 - Top Row)
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { jstk_cs }];
set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS33 } [get_ports { jstk_mosi }];
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { jstk_miso }];
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { jstk_sclk }];