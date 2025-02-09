library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity radix4_booth_multiplier is
    generic (
        N : integer := 16
    );
    Port ( 
        clk     : in  STD_LOGIC;
        rst     : in  STD_LOGIC;
        start   : in  STD_LOGIC;
        M       : in  STD_LOGIC_VECTOR(N-1 downto 0);    -- Multiplicand
        R       : in  STD_LOGIC_VECTOR(N-1 downto 0);    -- Multiplier
        done    : out STD_LOGIC;
        product : out STD_LOGIC_VECTOR((2*N)-1 downto 0) -- Product output
    );
end radix4_booth_multiplier;

architecture Behavioral of radix4_booth_multiplier is
    -- Internal signals for Radix-4 Booth Algorithm
    signal A           : STD_LOGIC_VECTOR(N+1 downto 0);     -- Extended Accumulator
    signal S           : STD_LOGIC_VECTOR(N+1 downto 0);     -- Negative of Multiplicand
    signal P           : STD_LOGIC_VECTOR(2*N+2 downto 0);   -- Product register
    signal count       : integer range 0 to N/2;             -- Counter for iterations (half of regular Booth)
    
    -- Booth encoding signals
    signal booth_encoding : STD_LOGIC_VECTOR(2 downto 0);    -- 3 bits for Radix-4 encoding
    
    type state_type is (IDLE, INITIALIZE, ENCODE, CALCULATE, SHIFT, FINALIZE);
    signal state : state_type;
    
begin
    process(clk, rst)
        variable temp_sum : STD_LOGIC_VECTOR(N+1 downto 0);
    begin
        if rst = '1' then
            state <= IDLE;
            done <= '0';
            product <= (others => '0');
            A <= (others => '0');
            S <= (others => '0');
            P <= (others => '0');
            count <= 0;
            
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if start = '1' then
                        state <= INITIALIZE;
                        done <= '0';
                    end if;
                    
                when INITIALIZE =>
                    -- Initialize for Radix-4 Booth
                    A <= M & "00";  -- Extended multiplicand
                    S <= std_logic_vector(-signed(M & "00"));  -- Two's complement of multiplicand
                    P <= (others => '0');
                    P(N downto 1) <= R;  -- Load multiplier
                    P(0) <= '0';  -- Extra bit for Booth encoding
                    count <= N/2;  -- Half the iterations due to Radix-4
                    state <= ENCODE;
                    
                when ENCODE =>
                    -- Radix-4 Booth encoding
                    booth_encoding <= P(2 downto 0);
                    state <= CALCULATE;
                    
                when CALCULATE =>
                    -- Perform operation based on encoding
                    case booth_encoding is
                        when "000" | "111" => -- 0
                            temp_sum := (others => '0');
                            
                        when "001" | "010" => -- +1
                            temp_sum := A;
                            
                        when "011" => -- +2
                            temp_sum := A(N downto 0) & '0';
                            
                        when "100" => -- -2
                            temp_sum := S(N downto 0) & '0';
                            
                        when "101" | "110" => -- -1
                            temp_sum := S;
                            
                        when others =>
                            temp_sum := (others => '0');
                    end case;
                    
                    -- Add to partial product
                    P(2*N+2 downto N+1) <= std_logic_vector(unsigned(P(2*N+2 downto N+1)) + unsigned(temp_sum));
                    state <= SHIFT;
                    
                when SHIFT =>
                    -- Arithmetic right shift by 2 positions (Radix-4)
                    P <= P(2*N+2) & P(2*N+2) & P(2*N+2 downto 2);
                    
                    if count = 0 then
                        state <= FINALIZE;
                    else
                        count <= count - 1;
                        state <= ENCODE;
                    end if;
                    
                when FINALIZE =>
                    product <= P(2*N downto 1);
                    done <= '1';
                    state <= IDLE;
            end case;
        end if;
    end process;
    
end Behavioral; 