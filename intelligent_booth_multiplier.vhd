library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity intelligent_booth_multiplier is
    generic (
        N : integer := 16  -- Increased bit width for more practical applications
    );
    Port ( 
        -- Clock and Control
        clk         : in  STD_LOGIC;
        rst         : in  STD_LOGIC;
        start       : in  STD_LOGIC;
        -- Configuration
        mode        : in  STD_LOGIC_VECTOR(1 downto 0);  -- 00: Regular, 01: Radix-4, 10: Pipelined, 11: Ultra-Fast
        adder_sel   : in  STD_LOGIC_VECTOR(1 downto 0);  -- 00: RCA, 01: CLA, 10: CSA, 11: Auto-select
        -- Data ports
        M           : in  STD_LOGIC_VECTOR(N-1 downto 0);    -- Multiplicand
        R           : in  STD_LOGIC_VECTOR(N-1 downto 0);    -- Multiplier
        -- Output ports
        done        : out STD_LOGIC;
        busy        : out STD_LOGIC;
        valid       : out STD_LOGIC;
        error       : out STD_LOGIC;
        product     : out STD_LOGIC_VECTOR((2*N)-1 downto 0);-- Product output
        -- Performance monitoring
        perf_cycles : out STD_LOGIC_VECTOR(7 downto 0);      -- Cycles taken
        power_mode  : out STD_LOGIC_VECTOR(1 downto 0)       -- Current power mode
    );
end intelligent_booth_multiplier;

architecture Behavioral of intelligent_booth_multiplier is
    -- Mode constants
    constant MODE_REGULAR   : STD_LOGIC_VECTOR(1 downto 0) := "00";
    constant MODE_RADIX4    : STD_LOGIC_VECTOR(1 downto 0) := "01";
    constant MODE_PIPELINED : STD_LOGIC_VECTOR(1 downto 0) := "10";
    constant MODE_ULTRAFAST : STD_LOGIC_VECTOR(1 downto 0) := "11";
    
    -- Adder type constants
    constant ADDER_RCA     : STD_LOGIC_VECTOR(1 downto 0) := "00";
    constant ADDER_CLA     : STD_LOGIC_VECTOR(1 downto 0) := "01";
    constant ADDER_CSA     : STD_LOGIC_VECTOR(1 downto 0) := "10";
    constant ADDER_AUTO    : STD_LOGIC_VECTOR(1 downto 0) := "11";
    
    -- FSM States
    type state_type is (IDLE, ANALYZE, CONFIGURE, INITIALIZE, PROCESS, PIPELINE_LOAD, 
                       PIPELINE_COMPUTE, PIPELINE_FLUSH, FINALIZE, ERROR_STATE);
    signal state : state_type;
    
    -- Internal control signals
    signal active_mode     : STD_LOGIC_VECTOR(1 downto 0);
    signal active_adder    : STD_LOGIC_VECTOR(1 downto 0);
    signal cycle_count     : unsigned(7 downto 0);
    signal pipeline_stage  : integer range 0 to 4;
    
    -- Performance monitoring
    signal power_level     : unsigned(1 downto 0);
    signal operation_error : STD_LOGIC;
    
begin
    -- Main control process
    process(clk, rst)
    begin
        if rst = '1' then
            state <= IDLE;
            active_mode <= MODE_REGULAR;
            active_adder <= ADDER_RCA;
            cycle_count <= (others => '0');
            pipeline_stage <= 0;
            power_level <= "00";
            operation_error <= '0';
            busy <= '0';
            done <= '0';
            valid <= '0';
            error <= '0';
            product <= (others => '0');
            
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if start = '1' then
                        state <= ANALYZE;
                        busy <= '1';
                        valid <= '0';
                        cycle_count <= (others => '0');
                    end if;
                    
                when ANALYZE =>
                    -- Analyze input operands and select optimal mode
                    if unsigned(M) < 256 and unsigned(R) < 256 then
                        active_mode <= MODE_REGULAR;  -- Small numbers, use simple mode
                    else
                        active_mode <= mode;  -- Use requested mode
                    end if;
                    state <= CONFIGURE;
                    
                when CONFIGURE =>
                    -- Select adder based on mode and operand size
                    if adder_sel = ADDER_AUTO then
                        if unsigned(M) > 65535 or unsigned(R) > 65535 then
                            active_adder <= ADDER_CSA;  -- Use CSA for large numbers
                        elsif unsigned(M) > 4096 or unsigned(R) > 4096 then
                            active_adder <= ADDER_CLA;  -- Use CLA for medium numbers
                        else
                            active_adder <= ADDER_RCA;  -- Use RCA for small numbers
                        end if;
                    else
                        active_adder <= adder_sel;
                    end if;
                    state <= INITIALIZE;
                    
                when INITIALIZE =>
                    -- Initialize based on selected mode
                    case active_mode is
                        when MODE_REGULAR =>
                            state <= PROCESS;
                        when MODE_RADIX4 =>
                            state <= PROCESS;
                        when MODE_PIPELINED =>
                            state <= PIPELINE_LOAD;
                            pipeline_stage <= 0;
                        when others =>
                            state <= ERROR_STATE;
                            operation_error <= '1';
                    end case;
                    
                when PROCESS =>
                    -- Main processing state
                    -- Implementation will be added in subsequent modules
                    state <= FINALIZE;
                    
                when PIPELINE_LOAD =>
                    -- Pipeline loading state
                    if pipeline_stage < 4 then
                        pipeline_stage <= pipeline_stage + 1;
                    else
                        state <= PIPELINE_COMPUTE;
                    end if;
                    
                when PIPELINE_COMPUTE =>
                    -- Pipeline computation state
                    state <= PIPELINE_FLUSH;
                    
                when PIPELINE_FLUSH =>
                    -- Flush pipeline state
                    state <= FINALIZE;
                    
                when FINALIZE =>
                    -- Complete operation
                    done <= '1';
                    busy <= '0';
                    valid <= '1';
                    state <= IDLE;
                    
                when ERROR_STATE =>
                    -- Handle error condition
                    error <= '1';
                    busy <= '0';
                    state <= IDLE;
            end case;
            
            -- Update performance monitoring
            if state /= IDLE then
                cycle_count <= cycle_count + 1;
            end if;
        end if;
    end process;
    
    -- Output assignments
    perf_cycles <= std_logic_vector(cycle_count);
    power_mode <= std_logic_vector(power_level);
    
end Behavioral; 