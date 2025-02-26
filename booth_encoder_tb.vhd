library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use work.booth_pkg.all;

entity booth_encoder_tb is
end booth_encoder_tb;

architecture behavior of booth_encoder_tb is
    -- Clock period definition
    constant CLK_PERIOD : time := 10 ns;
    
    -- Component signals
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal mode : BOOTH_MODE := RADIX4;
    signal multiplicand : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal multiplier : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal partial_products : PARTIAL_PRODUCT(0 to DATA_WIDTH/2);
    signal num_partial_products : integer range 0 to DATA_WIDTH/2;
    
    -- Test case record type
    type test_case_type is record
        multiplicand_val : integer;
        multiplier_val : integer;
        mode : BOOTH_MODE;
        description : string(1 to 30);
    end record;
    
    -- Test cases array
    type test_cases_array is array (natural range <>) of test_case_type;
    constant test_cases : test_cases_array := (
        -- Basic test cases
        (0, 0, RADIX4, "Zero multiplication           "),
        (1, 1, RADIX4, "One multiplication           "),
        (5, 7, RADIX4, "Small positive numbers       "),
        (15, -7, RADIX4, "Mixed signs - small         "),
        
        -- Power of two test cases
        (4, 8, RADIX4, "Powers of two               "),
        (16, 16, RADIX4, "Power of two squared        "),
        
        -- Radix-2 specific tests
        (5, 7, RADIX2, "Radix-2: Small numbers      "),
        (15, -7, RADIX2, "Radix-2: Mixed signs        "),
        
        -- Edge cases
        (2147483647, 1, RADIX4, "Max positive value          "),
        (-2147483648, 1, RADIX4, "Min negative value          ")
    );

begin
    -- Instantiate the Unit Under Test (UUT)
    uut: entity work.booth_encoder
        port map (
            clk => clk,
            rst => rst,
            mode => mode,
            multiplicand => multiplicand,
            multiplier => multiplier,
            partial_products => partial_products,
            num_partial_products => num_partial_products
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
        -- Function to convert integer to std_logic_vector
        function to_slv(val : integer; width : integer) return std_logic_vector is
        begin
            return std_logic_vector(to_signed(val, width));
        end function;
        
        -- Function to verify partial products
        procedure verify_partial_products(
            multiplicand_val : integer;
            multiplier_val : integer;
            test_mode : BOOTH_MODE;
            test_num : integer
        ) is
            variable expected_product : integer;
            variable actual_product : integer := 0;
            variable pp_val : integer;
        begin
            -- Calculate expected result
            expected_product := multiplicand_val * multiplier_val;
            
            -- Sum up partial products
            for i in 0 to num_partial_products-1 loop
                pp_val := to_integer(partial_products(i));
                if test_mode = RADIX4 then
                    actual_product := actual_product + (pp_val * 2**(2*i));
                else
                    actual_product := actual_product + (pp_val * 2**i);
                end if;
            end loop;
            
            -- Report results
            report "Test Case " & integer'image(test_num) & ": " & 
                   test_cases(test_num).description;
            report "Expected: " & integer'image(expected_product) & 
                   ", Actual: " & integer'image(actual_product);
            
            assert actual_product = expected_product
                report "Test failed! Expected " & integer'image(expected_product) &
                       " but got " & integer'image(actual_product)
                severity error;
        end procedure;

    begin
        -- Hold reset for 100 ns
        wait for 100 ns;
        rst <= '1';
        wait for CLK_PERIOD*2;
        rst <= '0';
        wait for CLK_PERIOD*2;
        
        -- Run test cases
        for i in test_cases'range loop
            -- Set inputs
            multiplicand <= to_slv(test_cases(i).multiplicand_val, DATA_WIDTH);
            multiplier <= to_slv(test_cases(i).multiplier_val, DATA_WIDTH);
            mode <= test_cases(i).mode;
            
            -- Wait for processing
            wait for CLK_PERIOD;
            
            -- Verify results
            verify_partial_products(
                test_cases(i).multiplicand_val,
                test_cases(i).multiplier_val,
                test_cases(i).mode,
                i
            );
            
            -- Wait between test cases
            wait for CLK_PERIOD*2;
        end process;
        
        -- End simulation
        wait for CLK_PERIOD*10;
        report "Simulation completed successfully!"
        severity note;
        wait;
    end process;

end behavior; 