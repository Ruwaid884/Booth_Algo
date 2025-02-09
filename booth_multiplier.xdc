# Clock signal
set_property PACKAGE_PIN W5 [get_ports clk]							
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]
 
# Reset signal
set_property PACKAGE_PIN U18 [get_ports rst]                          
set_property IOSTANDARD LVCMOS33 [get_ports rst]

# Start signal
set_property PACKAGE_PIN T18 [get_ports start]                          
set_property IOSTANDARD LVCMOS33 [get_ports start]

# Done signal
set_property PACKAGE_PIN U16 [get_ports done]                          
set_property IOSTANDARD LVCMOS33 [get_ports done]

# Multiplicand input M[3:0]
set_property PACKAGE_PIN V17 [get_ports {M[0]}]                          
set_property IOSTANDARD LVCMOS33 [get_ports {M[0]}]
set_property PACKAGE_PIN V16 [get_ports {M[1]}]                          
set_property IOSTANDARD LVCMOS33 [get_ports {M[1]}]
set_property PACKAGE_PIN W16 [get_ports {M[2]}]                          
set_property IOSTANDARD LVCMOS33 [get_ports {M[2]}]
set_property PACKAGE_PIN W17 [get_ports {M[3]}]                          
set_property IOSTANDARD LVCMOS33 [get_ports {M[3]}]

# Multiplier input R[3:0]
set_property PACKAGE_PIN W15 [get_ports {R[0]}]                          
set_property IOSTANDARD LVCMOS33 [get_ports {R[0]}]
set_property PACKAGE_PIN V15 [get_ports {R[1]}]                          
set_property IOSTANDARD LVCMOS33 [get_ports {R[1]}]
set_property PACKAGE_PIN W14 [get_ports {R[2]}]                          
set_property IOSTANDARD LVCMOS33 [get_ports {R[2]}]
set_property PACKAGE_PIN W13 [get_ports {R[3]}]                          
set_property IOSTANDARD LVCMOS33 [get_ports {R[3]}]

# Product output [7:0]
set_property PACKAGE_PIN U14 [get_ports {product[0]}]                    
set_property IOSTANDARD LVCMOS33 [get_ports {product[0]}]
set_property PACKAGE_PIN U15 [get_ports {product[1]}]                    
set_property IOSTANDARD LVCMOS33 [get_ports {product[1]}]
set_property PACKAGE_PIN V14 [get_ports {product[2]}]                    
set_property IOSTANDARD LVCMOS33 [get_ports {product[2]}]
set_property PACKAGE_PIN V13 [get_ports {product[3]}]                    
set_property IOSTANDARD LVCMOS33 [get_ports {product[3]}]
set_property PACKAGE_PIN V3 [get_ports {product[4]}]                     
set_property IOSTANDARD LVCMOS33 [get_ports {product[4]}]
set_property PACKAGE_PIN W3 [get_ports {product[5]}]                     
set_property IOSTANDARD LVCMOS33 [get_ports {product[5]}]
set_property PACKAGE_PIN U3 [get_ports {product[6]}]                     
set_property IOSTANDARD LVCMOS33 [get_ports {product[6]}]
set_property PACKAGE_PIN P3 [get_ports {product[7]}]                     
set_property IOSTANDARD LVCMOS33 [get_ports {product[7]}] 