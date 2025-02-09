library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity booth_multiplier_tb is
end booth_multiplier_tb;

architecture Behavioral of booth_multiplier_tb is
    -- Component Declaration for Booth Multiplier
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
            product : out STD_LOGIC_VECTOR((2*N)-1 downto 0)
        );
    end component;
    
    -- Constants
    constant CLK_PERIOD : time := 10 ns;
    constant N : integer := 4;
    
    -- Signals for Booth Multiplier
    signal clk     : STD_LOGIC := '0';
    signal rst     : STD_LOGIC := '1';
    signal start   : STD_LOGIC := '0';
    signal M       : STD_LOGIC_VECTOR(N-1 downto 0) := (others => '0');
    signal R       : STD_LOGIC_VECTOR(N-1 downto 0) := (others => '0');
    signal done    : STD_LOGIC;
    signal product : STD_LOGIC_VECTOR((2*N)-1 downto 0);
    
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
            product => product
        );
    
    -- Stimulus process
    stim_proc: process
    begin
        -- Reset
        wait for CLK_PERIOD*2;
        rst <= '0';
        wait for CLK_PERIOD;
        
        -- Test Case 1: 3 x 2
        M <= "0011";  -- 3
        R <= "0010";  -- 2
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        wait until done = '1';
        wait for CLK_PERIOD*2;
        
        -- Test Case 2: -2 x 3
        M <= "1110";  -- -2
        R <= "0011";  -- 3
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        wait until done = '1';
        wait for CLK_PERIOD*2;
        
        -- Test Case 3: -3 x -4
        M <= "1101";  -- -3
        R <= "1100";  -- -4
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        wait until done = '1';
        wait for CLK_PERIOD*2;
        
        -- End simulation
        report "Simulation completed successfully!"
        severity note;
        wait;
    end process;
    
end Behavioral; 