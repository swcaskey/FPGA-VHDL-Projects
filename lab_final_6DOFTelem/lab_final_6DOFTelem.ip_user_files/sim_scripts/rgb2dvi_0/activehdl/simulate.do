onbreak {quit -force}
onerror {quit -force}

asim +access +r +m+rgb2dvi_0 -L xil_defaultlib -L secureip -O5 xil_defaultlib.rgb2dvi_0

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {wave.do}

view wave
view structure

do {rgb2dvi_0.udo}

run -all

endsim

quit -force
