library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity booth_multiplier is
    generic (
        N : integer := 4  -- Number of bits for inputs
    );
    Port ( 
        clk     : in  STD_LOGIC;
        rst     : in  STD_LOGIC;
        start   : in  STD_LOGIC;
        M       : in  STD_LOGIC_VECTOR(N-1 downto 0);    -- Multiplicand
        R       : in  STD_LOGIC_VECTOR(N-1 downto 0);    -- Multiplier
        done    : out STD_LOGIC;
        product : out STD_LOGIC_VECTOR((2*N)-1 downto 0); -- Product output
        -- Additional ports for visualization
        A_vis   : out STD_LOGIC_VECTOR(N-1 downto 0);
        Q_vis   : out STD_LOGIC_VECTOR(N-1 downto 0);
        Q_1_vis : out STD_LOGIC;
        state_vis : out STD_LOGIC_VECTOR(1 downto 0);
        step_counter_vis : out INTEGER
    );
end booth_multiplier;

architecture Behavioral of booth_multiplier is
    type state_type is (IDLE, INITIALIZE, COMPUTE, DONE_STATE);
    signal current_state, next_state : state_type;
    
    signal A    : STD_LOGIC_VECTOR(N-1 downto 0);
    signal Q    : STD_LOGIC_VECTOR(N-1 downto 0);
    signal Q_1  : STD_LOGIC;
    signal count : INTEGER range 0 to N;
    
begin
    -- State encoding for visualization
    state_vis <= "00" when current_state = IDLE else
                "01" when current_state = INITIALIZE else
                "10" when current_state = COMPUTE else
                "11";
                
    -- Expose internal signals for visualization
    A_vis <= A;
    Q_vis <= Q;
    Q_1_vis <= Q_1;
    step_counter_vis <= count;
    
    -- State register process
    process(clk, rst)
    begin
        if rst = '1' then
            current_state <= IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;
    
    -- Next state and output logic
    process(current_state, start, count)
    begin
        case current_state is
            when IDLE =>
                if start = '1' then
                    next_state <= INITIALIZE;
                else
                    next_state <= IDLE;
                end if;
                
            when INITIALIZE =>
                next_state <= COMPUTE;
                
            when COMPUTE =>
                if count = 0 then
                    next_state <= DONE_STATE;
                else
                    next_state <= COMPUTE;
                end if;
                
            when DONE_STATE =>
                if start = '0' then
                    next_state <= IDLE;
                else
                    next_state <= DONE_STATE;
                end if;
        end case;
    end process;
    
    -- Datapath process
    process(clk, rst)
    begin
        if rst = '1' then
            A <= (others => '0');
            Q <= (others => '0');
            Q_1 <= '0';
            count <= 0;
            done <= '0';
            product <= (others => '0');
            
        elsif rising_edge(clk) then
            case current_state is
                when IDLE =>
                    done <= '0';
                    
                when INITIALIZE =>
                    A <= (others => '0');
                    Q <= R;
                    Q_1 <= '0';
                    count <= N;
                    
                when COMPUTE =>
                    -- Booth algorithm logic
                    if Q(0) = '0' and Q_1 = '1' then
                        -- Add
                        A <= std_logic_vector(unsigned(A) + unsigned(M));
                    elsif Q(0) = '1' and Q_1 = '0' then
                        -- Subtract
                        A <= std_logic_vector(unsigned(A) - unsigned(M));
                    end if;
                    
                    -- Arithmetic right shift
                    Q_1 <= Q(0);
                    Q <= A(0) & Q(N-1 downto 1);
                    A <= A(N-1) & A(N-1 downto 1);
                    count <= count - 1;
                    
                when DONE_STATE =>
                    done <= '1';
                    product <= A & Q;
            end case;
        end if;
    end process;
    
end Behavioral; 