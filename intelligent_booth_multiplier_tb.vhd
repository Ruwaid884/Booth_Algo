library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity intelligent_booth_multiplier_tb is
end intelligent_booth_multiplier_tb;

architecture Behavioral of intelligent_booth_multiplier_tb is
    -- Component Declaration
    component booth_multiplier
        generic (
            N : integer := 4
        );
        Port ( 
            clk     : in  STD_LOGIC;
            rst     : in  STD_LOGIC;
            start   : in  STD_LOGIC;
            M       : in  STD_LOGIC_VECTOR(N-1 downto 0);
            R       : in  STD_LOGIC_VECTOR(N-1 downto 0);
            done    : out STD_LOGIC;
            product : out STD_LOGIC_VECTOR((2*N)-1 downto 0);
            -- Visualization ports
            A_vis   : out STD_LOGIC_VECTOR(N-1 downto 0);
            Q_vis   : out STD_LOGIC_VECTOR(N-1 downto 0);
            Q_1_vis : out STD_LOGIC;
            state_vis : out STD_LOGIC_VECTOR(1 downto 0);
            step_counter_vis : out INTEGER
        );
    end component;
    
    -- Constants
    constant CLK_PERIOD : time := 10 ns;
    constant N : integer := 4;
    constant NUM_TESTS : integer := 16;
    
    -- Test signals
    signal clk     : STD_LOGIC := '0';
    signal rst     : STD_LOGIC := '1';
    signal start   : STD_LOGIC := '0';
    signal M       : STD_LOGIC_VECTOR(N-1 downto 0) := (others => '0');
    signal R       : STD_LOGIC_VECTOR(N-1 downto 0) := (others => '0');
    signal done    : STD_LOGIC;
    signal product : STD_LOGIC_VECTOR((2*N)-1 downto 0);
    
    -- Visualization signals
    signal A_vis   : STD_LOGIC_VECTOR(N-1 downto 0);
    signal Q_vis   : STD_LOGIC_VECTOR(N-1 downto 0);
    signal Q_1_vis : STD_LOGIC;
    signal state_vis : STD_LOGIC_VECTOR(1 downto 0);
    signal step_counter_vis : INTEGER;
    
    -- Test case record type
    type test_case_type is record
        M, R : STD_LOGIC_VECTOR(N-1 downto 0);
        expected_product : STD_LOGIC_VECTOR((2*N)-1 downto 0);
        description : string(1 to 30);
    end record;
    
    -- Array of test cases
    type test_case_array is array (0 to NUM_TESTS-1) of test_case_type;
    
    -- Test cases
    constant test_cases : test_case_array := (
        -- Basic multiplication
        (M => "0011", R => "0010", expected_product => "00000110", description => "3 x 2 = 6                    "),
        (M => "0100", R => "0011", expected_product => "00001100", description => "4 x 3 = 12                   "),
        
        -- Multiplication by 0 and 1
        (M => "1111", R => "0000", expected_product => "00000000", description => "-1 x 0 = 0                   "),
        (M => "0101", R => "0001", expected_product => "00000101", description => "5 x 1 = 5                    "),
        
        -- Negative numbers
        (M => "1110", R => "0011", expected_product => "11111010", description => "-2 x 3 = -6                  "),
        (M => "1101", R => "1100", expected_product => "00001100", description => "-3 x -4 = 12                 "),
        
        -- Edge cases
        (M => "1111", R => "1111", expected_product => "00000001", description => "-1 x -1 = 1                  "),
        (M => "1000", R => "1000", expected_product => "01000000", description => "-8 x -8 = 64                 "),
        
        -- Powers of 2
        (M => "0010", R => "0010", expected_product => "00000100", description => "2 x 2 = 4                    "),
        (M => "0100", R => "0100", expected_product => "00010000", description => "4 x 4 = 16                   "),
        
        -- Consecutive numbers
        (M => "0011", R => "0100", expected_product => "00001100", description => "3 x 4 = 12                   "),
        (M => "0101", R => "0110", expected_product => "00011110", description => "5 x 6 = 30                   "),
        
        -- Maximum positive numbers
        (M => "0111", R => "0111", expected_product => "00110001", description => "7 x 7 = 49                   "),
        
        -- Mixed signs with larger numbers
        (M => "0110", R => "1010", expected_product => "11111100", description => "6 x -6 = -36                 "),
        (M => "1010", R => "0110", expected_product => "11111100", description => "-6 x 6 = -36                 "),
        
        -- Minimum negative number
        (M => "1000", R => "0111", expected_product => "11100000", description => "-8 x 7 = -56                 ")
    );
    
    -- File handle for results
    file results_file: TEXT;
    
begin
    -- Clock generation
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    -- Instantiate the Unit Under Test (UUT)
    UUT: booth_multiplier 
        generic map (
            N => N
        )
        port map (
            clk     => clk,
            rst     => rst,
            start   => start,
            M       => M,
            R       => R,
            done    => done,
            product => product,
            A_vis   => A_vis,
            Q_vis   => Q_vis,
            Q_1_vis => Q_1_vis,
            state_vis => state_vis,
            step_counter_vis => step_counter_vis
        );
    
    -- Stimulus and verification process
    stim_proc: process
        variable line_out : LINE;
        variable errors : integer := 0;
        variable warnings : integer := 0;
        
        -- Helper function to convert std_logic_vector to integer
        function to_int(input: std_logic_vector) return integer is
        begin
            return to_integer(signed(input));
        end function;
        
        -- Helper procedure to write test results
        procedure write_test_result(
            test_num : in integer;
            test_case : in test_case_type;
            actual_product : in std_logic_vector;
            is_correct : in boolean) is
            variable line_out : LINE;
        begin
            write(line_out, string'("Test "));
            write(line_out, test_num);
            write(line_out, string'(": "));
            write(line_out, test_case.description);
            write(line_out, string'(" Expected: "));
            write(line_out, to_int(test_case.expected_product));
            write(line_out, string'(" Got: "));
            write(line_out, to_int(actual_product));
            if is_correct then
                write(line_out, string'(" [PASS]"));
            else
                write(line_out, string'(" [FAIL]"));
            end if;
            writeline(results_file, line_out);
        end procedure;
        
    begin
        -- Open results file
        file_open(results_file, "booth_multiplier_test_results.txt", WRITE_MODE);
        
        -- Write header
        write(line_out, string'("=== Booth Multiplier Test Results ==="));
        writeline(results_file, line_out);
        write(line_out, string'("Testing " & integer'image(NUM_TESTS) & " cases"));
        writeline(results_file, line_out);
        writeline(results_file, line_out);  -- Empty line
        
        -- Initial reset
        rst <= '1';
        wait for CLK_PERIOD*2;
        rst <= '0';
        wait for CLK_PERIOD;
        
        -- Run all test cases
        for i in 0 to NUM_TESTS-1 loop
            -- Apply test inputs
            M <= test_cases(i).M;
            R <= test_cases(i).R;
            start <= '1';
            wait for CLK_PERIOD;
            start <= '0';
            
            -- Wait for multiplication to complete
            wait until done = '1';
            wait for CLK_PERIOD;
            
            -- Verify result
            if product = test_cases(i).expected_product then
                write_test_result(i, test_cases(i), product, true);
            else
                write_test_result(i, test_cases(i), product, false);
                errors := errors + 1;
            end if;
            
            -- Add delay between tests
            wait for CLK_PERIOD*2;
        end loop;
        
        -- Write summary
        writeline(results_file, line_out);  -- Empty line
        write(line_out, string'("=== Test Summary ==="));
        writeline(results_file, line_out);
        write(line_out, string'("Total Tests: " & integer'image(NUM_TESTS)));
        writeline(results_file, line_out);
        write(line_out, string'("Passed: " & integer'image(NUM_TESTS - errors)));
        writeline(results_file, line_out);
        write(line_out, string'("Failed: " & integer'image(errors)));
        writeline(results_file, line_out);
        
        -- Close results file
        file_close(results_file);
        
        -- End simulation
        wait;
    end process;
    
end Behavioral; 