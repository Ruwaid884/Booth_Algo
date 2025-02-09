library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity intelligent_booth_multiplier_tb is
end intelligent_booth_multiplier_tb;

architecture Behavioral of intelligent_booth_multiplier_tb is
    -- Component Declaration
    component intelligent_booth_multiplier
        generic (
            N : integer := 16
        );
        Port ( 
            clk     : in  STD_LOGIC;
            rst     : in  STD_LOGIC;
            start   : in  STD_LOGIC;
            M       : in  STD_LOGIC_VECTOR(N-1 downto 0);
            R       : in  STD_LOGIC_VECTOR(N-1 downto 0);
            done    : out STD_LOGIC;
            product : out STD_LOGIC_VECTOR((2*N)-1 downto 0)
        );
    end component;
    
    -- Constants
    constant CLK_PERIOD : time := 10 ns;
    constant N : integer := 16;
    
    -- Test signals
    signal clk     : STD_LOGIC := '0';
    signal rst     : STD_LOGIC := '1';
    signal start   : STD_LOGIC := '0';
    signal M       : STD_LOGIC_VECTOR(N-1 downto 0) := (others => '0');
    signal R       : STD_LOGIC_VECTOR(N-1 downto 0) := (others => '0');
    signal done    : STD_LOGIC;
    signal product : STD_LOGIC_VECTOR((2*N)-1 downto 0);
    
    -- Helper function to check results
    function check_result(
        actual: STD_LOGIC_VECTOR;
        expected: integer
    ) return boolean is
        variable actual_int: integer;
    begin
        actual_int := to_integer(signed(actual));
        return actual_int = expected;
    end function;
    
begin
    -- Clock process
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    -- Instantiate the Unit Under Test (UUT)
    UUT: intelligent_booth_multiplier 
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
            product => product
        );
    
    -- Stimulus process
    stim_proc: process
        -- Procedure to perform multiplication and check result
        procedure test_multiply(
            m_val: integer;
            r_val: integer;
            expected: integer
        ) is
        begin
            -- Apply inputs
            M <= std_logic_vector(to_signed(m_val, N));
            R <= std_logic_vector(to_signed(r_val, N));
            start <= '1';
            wait for CLK_PERIOD;
            start <= '0';
            
            -- Wait for completion
            wait until done = '1';
            wait for CLK_PERIOD;
            
            -- Check result
            assert check_result(product, expected)
                report "Test failed for " & integer'image(m_val) & " x " & 
                       integer'image(r_val) & ". Expected " & integer'image(expected) &
                       " but got " & integer'image(to_integer(signed(product)))
                severity error;
            
            wait for CLK_PERIOD*2;
        end procedure;
        
    begin
        -- Reset
        wait for CLK_PERIOD*2;
        rst <= '0';
        wait for CLK_PERIOD;
        
        -- Test cases
        test_multiply(5, 3, 15);
        test_multiply(7, -4, -28);
        test_multiply(-6, 5, -30);
        test_multiply(-8, -7, 56);
        test_multiply(0, 123, 0);
        test_multiply(456, 0, 0);
        test_multiply(1000, 1000, 1000000);
        test_multiply(-1000, 1000, -1000000);
        test_multiply(32767, 2, 65534);
        test_multiply(-32768, 2, -65536);
        
        -- End simulation
        report "Simulation completed successfully!"
        severity note;
        wait;
    end process;
    
end Behavioral; 