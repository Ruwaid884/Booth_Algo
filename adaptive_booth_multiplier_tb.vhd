library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use work.booth_pkg.all;

entity adaptive_booth_multiplier_tb is
    -- Generic to control simulation parameters
    generic (
        ENABLE_RANDOM_TESTS : boolean := true;   -- Enable random test cases
        NUM_RANDOM_TESTS : integer := 10;        -- Number of random tests to run
        VERBOSE_OUTPUT : boolean := true;        -- Enable detailed console output
        TIMEOUT_CYCLES : integer := 100          -- Maximum cycles to wait for completion
    );
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
    
    -- Statistics tracking
    signal total_tests : integer := 0;
    signal passed_tests : integer := 0;
    signal failed_tests : integer := 0;
    
    -- Performance metrics
    signal cycles_sum : integer := 0;
    signal max_cycles : integer := 0;
    signal min_cycles : integer := 1000;
    
    -- Test case record type with expected result
    type test_case_type is record
        id : integer;                         -- Unique test case ID
        multiplicand_val : integer;           -- Multiplicand value
        multiplier_val : integer;             -- Multiplier value
        expected_result : integer;            -- Expected result
        mode : BOOTH_MODE;                    -- Booth mode to use
        adder : ADDER_TYPE;                   -- Adder type to use
        stages : integer range 1 to 4;        -- Pipeline stages
    end record;
    
    -- Test cases array - predefined test vectors
    type test_cases_array is array (natural range <>) of test_case_type;
    constant predefined_tests : test_cases_array := (
        -- Basic test cases
        (1, 0, 0, 0, RADIX4, CARRY_LOOKAHEAD, 2),
        (2, 1, 1, 1, RADIX4, CARRY_LOOKAHEAD, 2),
        (3, 5, 7, 35, RADIX2, RIPPLE_CARRY, 1),
        
        -- Power of two test cases
        (4, 4, 8, 32, RADIX4, CARRY_LOOKAHEAD, 2),
        (5, 16, 16, 256, RADIX4, CARRY_SAVE, 3),
        
        -- Negative number tests
        (6, -5, 7, -35, RADIX4, CARRY_LOOKAHEAD, 2),
        (7, 12, -6, -72, RADIX2, CARRY_SAVE, 2),
        (8, -25, -4, 100, RADIX4, CARRY_LOOKAHEAD, 3),
        
        -- Edge cases
        (9, 2147483647, 1, 2147483647, RADIX4, CARRY_SAVE, 4),
        (10, -2147483648, 1, -2147483648, RADIX4, CARRY_SAVE, 4),
        
        -- Specific bit pattern tests
        (11, 65535, 65535, 4294836225, RADIX2, CARRY_SAVE, 3),
        (12, 43690, 21845, 954437050, RADIX4, CARRY_LOOKAHEAD, 2),
        
        -- Testing different adder configurations
        (13, 1234, 5678, 7006652, RADIX4, RIPPLE_CARRY, 2),
        (14, 1234, 5678, 7006652, RADIX4, CARRY_LOOKAHEAD, 2),
        (15, 1234, 5678, 7006652, RADIX4, CARRY_SAVE, 2)
    );
    
    -- Random test case generation
    impure function random_integer(min_val, max_val : integer) return integer is
        variable r : real;
        variable seed1, seed2 : positive := 1;
    begin
        uniform(seed1, seed2, r);
        return integer(r * real(max_val - min_val) + real(min_val));
    end function;
    
    -- Signal for tracking cycles
    signal cycle_counter : integer := 0;
    signal test_cycles : integer := 0;
    signal test_running : boolean := false;
    
    -- Function to convert integer to std_logic_vector
    function to_slv(val : integer; width : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(val, width));
    end function;
    
    -- Function to convert to printable string (with proper alignment)
    function int_to_str(val : integer; width : integer := 12) return string is
        variable temp : string(1 to width) := (others => ' ');
        variable str : string(1 to 12);
        variable val_str : string(1 to 12);
        variable pos : integer;
    begin
        -- Convert integer to string
        val_str := integer'image(val);
        
        -- Skip initial space for positive numbers
        if val >= 0 then
            pos := 2;
        else
            pos := 1;
        end if;
        
        -- Copy the string with right alignment
        for i in 1 to width loop
            if i <= width - (val_str'length - pos + 1) then
                temp(i) := ' ';
            else
                temp(i) := val_str(pos + (i - (width - (val_str'length - pos + 1))));
            end if;
        end loop;
        
        return temp;
    end function;
    
    -- Function to convert BOOTH_MODE to string
    function mode_to_str(mode : BOOTH_MODE) return string is
    begin
        case mode is
            when RADIX2 => return "RADIX2        ";
            when RADIX4 => return "RADIX4        ";
        end case;
    end function;
    
    -- Function to convert ADDER_TYPE to string
    function adder_to_str(adder : ADDER_TYPE) return string is
    begin
        case adder is
            when RIPPLE_CARRY => return "RIPPLE_CARRY  ";
            when CARRY_LOOKAHEAD => return "CARRY_LOOKAHD ";
            when CARRY_SAVE => return "CARRY_SAVE    ";
        end case;
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
    
    -- Cycle counter process
    cycle_count_proc: process(clk, rst)
    begin
        if rst = '1' then
            cycle_counter <= 0;
            test_cycles <= 0;
        elsif rising_edge(clk) then
            cycle_counter <= cycle_counter + 1;
            
            if test_running then
                test_cycles <= test_cycles + 1;
            else
                test_cycles <= 0;  -- Reset test_cycles when not running a test
            end if;
        end if;
    end process;
    
    -- Stimulus process
    stim_proc: process
        variable expected_result_slv : std_logic_vector(2*DATA_WIDTH-1 downto 0);
        variable actual_result_slv : std_logic_vector(2*DATA_WIDTH-1 downto 0);
        variable expected_result_int, actual_result_int : integer;
        variable timeout_reached : boolean;
        variable random_test_case : test_case_type;
        variable op1, op2, exp_result : integer;
    begin
        -- Print test header
        report "=========================================================================" severity note;
        report "                  ADAPTIVE BOOTH MULTIPLIER TESTBENCH                    " severity note;
        report "=========================================================================" severity note;
        
        -- Initial reset
        rst <= '1';
        wait for CLK_PERIOD*5;
        rst <= '0';
        wait for CLK_PERIOD*2;
        
        -- Run all predefined test cases
        report "STARTING PREDEFINED TEST CASES..." severity note;
        report "-------------------------------------------------------------------------" severity note;
        if VERBOSE_OUTPUT then
            report "TEST ID | MULTIPLICAND |  MULTIPLIER  |    RESULT    |   EXPECTED   | BOOTH MODE  | ADDER TYPE   | STATUS" severity note;
            report "-------------------------------------------------------------------------" severity note;
        end if;
        
        for i in predefined_tests'range loop
            -- Initialize test
            test_running <= false;
            wait for CLK_PERIOD;  -- Wait for test_cycles to be reset
            total_tests <= total_tests + 1;
            
            -- Set up test parameters
            multiplicand <= to_slv(predefined_tests(i).multiplicand_val, DATA_WIDTH);
            multiplier <= to_slv(predefined_tests(i).multiplier_val, DATA_WIDTH);
            force_mode <= predefined_tests(i).mode;
            force_adder <= predefined_tests(i).adder;
            pipeline_stages <= predefined_tests(i).stages;
            expected_result_int := predefined_tests(i).expected_result;
            expected_result_slv := to_slv(expected_result_int, 2*DATA_WIDTH);
            
            -- Start multiplication
            test_running <= true;
            start <= '1';
            wait for CLK_PERIOD;
            start <= '0';
            
            -- Wait for completion or timeout
            timeout_reached := false;
            for j in 1 to TIMEOUT_CYCLES loop
                if done = '1' then
                    exit;
                end if;
                
                if j = TIMEOUT_CYCLES then
                    timeout_reached := true;
                end if;
                
                wait for CLK_PERIOD;
            end loop;
            
            -- Check result
            test_running <= false;
            wait for CLK_PERIOD;  -- Wait for test_cycles to update
            actual_result_slv := result;
            actual_result_int := to_integer(signed(actual_result_slv));
            
            -- Update performance metrics
            if test_cycles > max_cycles then
                max_cycles <= test_cycles;
            end if;
            
            if test_cycles < min_cycles then
                min_cycles <= test_cycles;
            end if;
            
            cycles_sum <= cycles_sum + test_cycles;
            
            -- Output test results
            if timeout_reached then
                if VERBOSE_OUTPUT then
                    report int_to_str(predefined_tests(i).id, 7) & " | " &
                           int_to_str(predefined_tests(i).multiplicand_val) & " | " &
                           int_to_str(predefined_tests(i).multiplier_val) & " | " &
                           "TIMEOUT      | " &
                           int_to_str(expected_result_int) & " | " &
                           mode_to_str(predefined_tests(i).mode) & " | " &
                           adder_to_str(predefined_tests(i).adder) & " | " &
                           "FAILED - TIMEOUT" severity error;
                else
                    report "Test case " & integer'image(predefined_tests(i).id) & 
                           " FAILED: TIMEOUT" severity error;
                end if;
                failed_tests <= failed_tests + 1;
            elsif actual_result_int = expected_result_int then
                if VERBOSE_OUTPUT then
                    report int_to_str(predefined_tests(i).id, 7) & " | " &
                           int_to_str(predefined_tests(i).multiplicand_val) & " | " &
                           int_to_str(predefined_tests(i).multiplier_val) & " | " &
                           int_to_str(actual_result_int) & " | " &
                           int_to_str(expected_result_int) & " | " &
                           mode_to_str(predefined_tests(i).mode) & " | " &
                           adder_to_str(predefined_tests(i).adder) & " | " &
                           "PASSED (" & integer'image(test_cycles) & " cycles)" severity note;
                else
                    report "Test case " & integer'image(predefined_tests(i).id) & 
                           " PASSED in " & integer'image(test_cycles) & " cycles" severity note;
                end if;
                passed_tests <= passed_tests + 1;
            else
                if VERBOSE_OUTPUT then
                    report int_to_str(predefined_tests(i).id, 7) & " | " &
                           int_to_str(predefined_tests(i).multiplicand_val) & " | " &
                           int_to_str(predefined_tests(i).multiplier_val) & " | " &
                           int_to_str(actual_result_int) & " | " &
                           int_to_str(expected_result_int) & " | " &
                           mode_to_str(predefined_tests(i).mode) & " | " &
                           adder_to_str(predefined_tests(i).adder) & " | " &
                           "FAILED" severity error;
                else
                    report "Test case " & integer'image(predefined_tests(i).id) & 
                           " FAILED: Expected " & integer'image(expected_result_int) & 
                           " but got " & integer'image(actual_result_int) severity error;
                end if;
                failed_tests <= failed_tests + 1;
            end if;
            
            -- Wait between test cases
            wait for CLK_PERIOD*5;
        end loop;
        
        -- Run random test cases if enabled
        if ENABLE_RANDOM_TESTS then
            report "-------------------------------------------------------------------------" severity note;
            report "STARTING RANDOM TEST CASES..." severity note;
            report "-------------------------------------------------------------------------" severity note;
            
            if VERBOSE_OUTPUT then
                report "TEST ID | MULTIPLICAND |  MULTIPLIER  |    RESULT    |   EXPECTED   | BOOTH MODE  | ADDER TYPE   | STATUS" severity note;
                report "-------------------------------------------------------------------------" severity note;
            end if;
            
            -- Run specified number of random tests
            for i in 1 to NUM_RANDOM_TESTS loop
                -- Initialize test
                test_running <= false;
                wait for CLK_PERIOD;  -- Wait for test_cycles to be reset
                total_tests <= total_tests + 1;
                
                -- Generate random test case
                op1 := random_integer(-2147483648, 2147483647);
                op2 := random_integer(-2147483648, 2147483647);
                
                -- Calculate expected result (handle overflow for demonstration)
                -- In real world this needs careful consideration of 32x32=64 bit math
                exp_result := op1 * op2;
                
                -- Randomly select mode and adder
                if random_integer(0, 1) = 0 then
                    random_test_case.mode := RADIX2;
                else
                    random_test_case.mode := RADIX4;
                end if;
                
                case random_integer(0, 2) is
                    when 0 => random_test_case.adder := RIPPLE_CARRY;
                    when 1 => random_test_case.adder := CARRY_LOOKAHEAD;
                    when others => random_test_case.adder := CARRY_SAVE;
                end case;
                
                random_test_case.stages := random_integer(1, 4);
                random_test_case.id := predefined_tests'length + i;
                random_test_case.multiplicand_val := op1;
                random_test_case.multiplier_val := op2;
                random_test_case.expected_result := exp_result;
                
                -- Set up test parameters
                multiplicand <= to_slv(random_test_case.multiplicand_val, DATA_WIDTH);
                multiplier <= to_slv(random_test_case.multiplier_val, DATA_WIDTH);
                force_mode <= random_test_case.mode;
                force_adder <= random_test_case.adder;
                pipeline_stages <= random_test_case.stages;
                expected_result_int := random_test_case.expected_result;
                expected_result_slv := to_slv(expected_result_int, 2*DATA_WIDTH);
                
                -- Start multiplication
                test_running <= true;
                start <= '1';
                wait for CLK_PERIOD;
                start <= '0';
                
                -- Wait for completion or timeout
                timeout_reached := false;
                for j in 1 to TIMEOUT_CYCLES loop
                    if done = '1' then
                        exit;
                    end if;
                    
                    if j = TIMEOUT_CYCLES then
                        timeout_reached := true;
                    end if;
                    
                    wait for CLK_PERIOD;
                end loop;
                
                -- Check result
                test_running <= false;
                wait for CLK_PERIOD;  -- Wait for test_cycles to update
                actual_result_slv := result;
                actual_result_int := to_integer(signed(actual_result_slv));
                
                -- Update performance metrics
                if test_cycles > max_cycles then
                    max_cycles <= test_cycles;
                end if;
                
                if test_cycles < min_cycles then
                    min_cycles <= test_cycles;
                end if;
                
                cycles_sum <= cycles_sum + test_cycles;
                
                -- Output test results
                if timeout_reached then
                    report "Random test case " & integer'image(random_test_case.id) & 
                           " FAILED: TIMEOUT" severity error;
                    failed_tests <= failed_tests + 1;
                elsif actual_result_int = expected_result_int then
                    report "Random test case " & integer'image(random_test_case.id) & 
                           " PASSED in " & integer'image(test_cycles) & " cycles" severity note;
                    passed_tests <= passed_tests + 1;
                else
                    report "Random test case " & integer'image(random_test_case.id) & 
                           " FAILED: Expected " & integer'image(expected_result_int) & 
                           " but got " & integer'image(actual_result_int) severity error;
                    failed_tests <= failed_tests + 1;
                end if;
                
                -- Wait between test cases
                wait for CLK_PERIOD*5;
            end loop;
        end if;
        
        -- Report final results
        report "=========================================================================" severity note;
        report "                          TEST SUMMARY                                   " severity note;
        report "=========================================================================" severity note;
        report "Total tests run    : " & integer'image(total_tests) severity note;
        report "Tests passed       : " & integer'image(passed_tests) severity note;
        report "Tests failed       : " & integer'image(failed_tests) severity note;
        report "Pass rate          : " & integer'image(100 * passed_tests / total_tests) & "%" severity note;
        report "-------------------------------------------------------------------------" severity note;
        report "Performance Metrics:" severity note;
        report "Minimum cycles     : " & integer'image(min_cycles) severity note;
        report "Maximum cycles     : " & integer'image(max_cycles) severity note;
        report "Average cycles     : " & integer'image(cycles_sum / total_tests) severity note;
        report "=========================================================================" severity note;
        
        if failed_tests = 0 then
            report "ALL TESTS PASSED SUCCESSFULLY!" severity note;
        else
            report integer'image(failed_tests) & " TESTS FAILED!" severity error;
        end if;
        
        -- End simulation
        wait;
    end process;
    
end behavior; 