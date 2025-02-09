library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use work.booth_pkg.all;

entity adaptive_booth_multiplier_tb is
end adaptive_booth_multiplier_tb;

architecture behavior of adaptive_booth_multiplier_tb is
    -- Clock period definitions
    constant CLK_PERIOD : time := 10 ns;
    
    -- Component signals
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal multiplicand : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal multiplier : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal start : std_logic := '0';
    signal force_mode : BOOTH_MODE := RADIX4;
    signal force_adder : ADDER_TYPE := CARRY_LOOKAHEAD;
    signal pipeline_stages : integer range 1 to 4 := 2;
    signal result : std_logic_vector(2*DATA_WIDTH-1 downto 0);
    signal done : std_logic;
    signal busy : std_logic;
    
    -- Test case record type
    type test_case_type is record
        multiplicand : integer;
        multiplier : integer;
        mode : BOOTH_MODE;
        adder : ADDER_TYPE;
        stages : integer;
    end record;
    
    -- Test cases array
    type test_cases_array is array (natural range <>) of test_case_type;
    constant test_cases : test_cases_array := (
        -- Test case 1: Small numbers, Radix-2, Ripple Carry
        (multiplicand => 5, multiplier => 7, mode => RADIX2, 
         adder => RIPPLE_CARRY, stages => 1),
         
        -- Test case 2: Medium numbers, Radix-4, Carry Lookahead
        (multiplicand => 1234, multiplier => 5678, mode => RADIX4,
         adder => CARRY_LOOKAHEAD, stages => 2),
         
        -- Test case 3: Large numbers, Radix-4, Carry Save
        (multiplicand => 65535, multiplier => 32768, mode => RADIX4,
         adder => CARRY_SAVE, stages => 3),
         
        -- Test case 4: Sparse number multiplication
        (multiplicand => 2048, multiplier => 4096, mode => RADIX4,
         adder => CARRY_LOOKAHEAD, stages => 2),
         
        -- Test case 5: Dense number multiplication
        (multiplicand => 65535, multiplier => 65535, mode => RADIX2,
         adder => CARRY_SAVE, stages => 4)
    );
    
    -- Function to convert integer to std_logic_vector
    function to_slv(val : integer; width : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(val, width));
    end function;
    
begin
    -- Instantiate the Unit Under Test (UUT)
    uut: entity work.adaptive_booth_multiplier
        port map (
            clk => clk,
            rst => rst,
            multiplicand => multiplicand,
            multiplier => multiplier,
            start => start,
            force_mode => force_mode,
            force_adder => force_adder,
            pipeline_stages => pipeline_stages,
            result => result,
            done => done,
            busy => busy
        );
        
    -- Clock process
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    -- Stimulus process
    stim_proc: process
        variable expected_result : unsigned(2*DATA_WIDTH-1 downto 0);
        variable actual_result : unsigned(2*DATA_WIDTH-1 downto 0);
        variable error_count : integer := 0;
    begin
        -- Hold reset state for 100 ns
        wait for 100 ns;
        rst <= '0';
        wait for CLK_PERIOD*2;
        
        -- Test each case
        for i in test_cases'range loop
            report "Running test case " & integer'image(i+1);
            
            -- Set up test case
            multiplicand <= to_slv(test_cases(i).multiplicand, DATA_WIDTH);
            multiplier <= to_slv(test_cases(i).multiplier, DATA_WIDTH);
            force_mode <= test_cases(i).mode;
            force_adder <= test_cases(i).adder;
            pipeline_stages <= test_cases(i).stages;
            
            -- Calculate expected result
            expected_result := to_unsigned(test_cases(i).multiplicand * 
                                        test_cases(i).multiplier, 2*DATA_WIDTH);
            
            -- Start multiplication
            wait for CLK_PERIOD;
            start <= '1';
            wait for CLK_PERIOD;
            start <= '0';
            
            -- Wait for completion
            wait until done = '1';
            wait for CLK_PERIOD;
            
            -- Check result
            actual_result := unsigned(result);
            if actual_result /= expected_result then
                report "Test case " & integer'image(i+1) & " failed!" severity error;
                report "Expected: " & integer'image(to_integer(expected_result));
                report "Got: " & integer'image(to_integer(actual_result));
                error_count := error_count + 1;
            else
                report "Test case " & integer'image(i+1) & " passed!" severity note;
            end if;
            
            -- Wait between test cases
            wait for CLK_PERIOD*5;
        end loop;
        
        -- Report final results
        if error_count = 0 then
            report "All test cases passed!" severity note;
        else
            report integer'image(error_count) & " test cases failed!" severity error;
        end if;
        
        -- End simulation
        wait for CLK_PERIOD*10;
        report "Simulation completed" severity note;
        wait;
    end process;
    
    -- Monitor process for debugging
    monitor_proc: process(clk)
    begin
        if rising_edge(clk) then
            if busy = '1' then
                report "State: Busy, Processing multiplication...";
            end if;
            if done = '1' then
                report "Multiplication completed";
            end if;
        end if;
    end process;
    
end behavior; 