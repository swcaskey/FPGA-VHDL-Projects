## Dont use this board unless I am doing PMOD* just use other board

##Clock signal
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];

##Buttons
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { btn_0 }];

##Pmod Header JE (Used for UART)
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { TXD }];
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports { RXD }];
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { CTS }];
set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { RTS }];

##Pmod Header JC (Mapped to VGA R, G, and VS via PmodVGA)
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { vga_r[0] }]; 
set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS33 } [get_ports { vga_r[1] }]; 
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { vga_r[2] }]; 
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { vga_r[3] }]; 
set_property -dict { PACKAGE_PIN W14   IOSTANDARD LVCMOS33 } [get_ports { vga_b[0] }]; 
set_property -dict { PACKAGE_PIN Y14   IOSTANDARD LVCMOS33 } [get_ports { vga_b[1] }]; 
set_property -dict { PACKAGE_PIN T12   IOSTANDARD LVCMOS33 } [get_ports { vga_b[2] }]; 
set_property -dict { PACKAGE_PIN U12   IOSTANDARD LVCMOS33 } [get_ports { vga_b[3] }]; 

##Pmod Header JD (Mapped to VGA B, G, and HS via PmodVGA)
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { vga_g[0] }]; 
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports { vga_g[1] }]; 
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { vga_g[2] }]; 
set_property -dict { PACKAGE_PIN R14   IOSTANDARD LVCMOS33 } [get_ports { vga_g[3] }]; 
set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports { vga_hs }]; 
set_property -dict { PACKAGE_PIN U15   IOSTANDARD LVCMOS33 } [get_ports { vga_vs }]; 
