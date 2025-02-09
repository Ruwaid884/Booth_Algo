library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity booth_multiplier_visualizer is
    generic (
        N : integer := 4
    );
    Port ( 
        clk           : in  STD_LOGIC;
        rst           : in  STD_LOGIC;
        -- Signals to monitor
        M             : in  STD_LOGIC_VECTOR(N-1 downto 0);
        R             : in  STD_LOGIC_VECTOR(N-1 downto 0);
        A             : in  STD_LOGIC_VECTOR(N-1 downto 0);  -- Accumulator
        Q             : in  STD_LOGIC_VECTOR(N-1 downto 0);  -- Multiplier register
        Q_1           : in  STD_LOGIC;                       -- Extra bit
        state         : in  STD_LOGIC_VECTOR(1 downto 0);    -- Current state
        step_counter  : in  INTEGER;                         -- Step counter
        done          : in  STD_LOGIC
    );
end booth_multiplier_visualizer;

architecture Behavioral of booth_multiplier_visualizer is
    -- File handle for visualization output
    file visualization_file: TEXT;
    
begin
    -- Process to generate visualization
    visualization_process: process(clk)
        variable line_out : LINE;
        variable step_str : STRING(1 to 40);
        
        -- Helper function to convert std_logic_vector to string with binary representation
        function to_string(input: std_logic_vector) return string is
            variable result: string(1 to input'length);
        begin
            for i in input'range loop
                case input(i) is
                    when '0' => result(i+1) := '0';
                    when '1' => result(i+1) := '1';
                    when others => result(i+1) := 'X';
                end case;
            end loop;
            return result;
        end function;
        
    begin
        if rising_edge(clk) then
            if rst = '1' then
                -- Open the visualization file
                file_open(visualization_file, "booth_multiplication_steps.txt", WRITE_MODE);
                write(line_out, string'("=== Booth Multiplier Visualization ==="));
                writeline(visualization_file, line_out);
                write(line_out, string'("Initial values:"));
                writeline(visualization_file, line_out);
                write(line_out, string'("Multiplicand (M): ") & to_string(M));
                writeline(visualization_file, line_out);
                write(line_out, string'("Multiplier (R): ") & to_string(R));
                writeline(visualization_file, line_out);
                
            elsif done = '0' then
                -- Display current step
                write(line_out, string'("Step ") & integer'image(step_counter));
                writeline(visualization_file, line_out);
                
                -- Display registers
                write(line_out, string'("A: ") & to_string(A));
                writeline(visualization_file, line_out);
                write(line_out, string'("Q: ") & to_string(Q));
                writeline(visualization_file, line_out);
                write(line_out, string'("Q-1: ") & std_logic'image(Q_1));
                writeline(visualization_file, line_out);
                
                -- Display current state
                case state is
                    when "00" => 
                        write(line_out, string'("State: IDLE"));
                    when "01" => 
                        write(line_out, string'("State: INITIALIZE"));
                    when "10" => 
                        write(line_out, string'("State: COMPUTE"));
                    when others => 
                        write(line_out, string'("State: DONE"));
                end case;
                writeline(visualization_file, line_out);
                
                -- Add separator
                write(line_out, string'("--------------------------"));
                writeline(visualization_file, line_out);
                
            elsif done = '1' then
                -- Display final result
                write(line_out, string'("=== Multiplication Complete ==="));
                writeline(visualization_file, line_out);
                write(line_out, string'("Final Result: ") & to_string(A) & to_string(Q));
                writeline(visualization_file, line_out);
                file_close(visualization_file);
            end if;
        end if;
    end process;

end Behavioral; 