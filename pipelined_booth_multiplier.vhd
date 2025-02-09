library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pipelined_booth_multiplier is
    generic (
        N : integer := 16
    );
    Port ( 
        clk         : in  STD_LOGIC;
        rst         : in  STD_LOGIC;
        -- Input interface
        data_valid  : in  STD_LOGIC;
        ready       : out STD_LOGIC;
        M           : in  STD_LOGIC_VECTOR(N-1 downto 0);    -- Multiplicand
        R           : in  STD_LOGIC_VECTOR(N-1 downto 0);    -- Multiplier
        -- Output interface
        valid       : out STD_LOGIC;
        product     : out STD_LOGIC_VECTOR((2*N)-1 downto 0) -- Product output
    );
end pipelined_booth_multiplier;

architecture Behavioral of pipelined_booth_multiplier is
    -- Pipeline stage signals
    type pipeline_stage_type is record
        valid   : STD_LOGIC;
        M       : STD_LOGIC_VECTOR(N-1 downto 0);
        R       : STD_LOGIC_VECTOR(N-1 downto 0);
        A       : STD_LOGIC_VECTOR(N downto 0);
        S       : STD_LOGIC_VECTOR(N downto 0);
        P       : STD_LOGIC_VECTOR(2*N+1 downto 0);
        count   : integer range 0 to N/4-1;  -- Four pipeline stages
    end record;
    
    type pipeline_array is array (0 to 3) of pipeline_stage_type;
    signal pipeline : pipeline_array;
    
    -- Control signals
    signal pipeline_ready : STD_LOGIC;
    
begin
    -- Pipeline control process
    process(clk, rst)
        variable temp_sum : STD_LOGIC_VECTOR(N downto 0);
    begin
        if rst = '1' then
            -- Reset all pipeline stages
            for i in 0 to 3 loop
                pipeline(i).valid <= '0';
                pipeline(i).M <= (others => '0');
                pipeline(i).R <= (others => '0');
                pipeline(i).A <= (others => '0');
                pipeline(i).S <= (others => '0');
                pipeline(i).P <= (others => '0');
                pipeline(i).count <= 0;
            end loop;
            
            valid <= '0';
            ready <= '1';
            product <= (others => '0');
            
        elsif rising_edge(clk) then
            -- Stage 0: Input and initialization
            if data_valid = '1' and pipeline_ready = '1' then
                pipeline(0).valid <= '1';
                pipeline(0).M <= M;
                pipeline(0).R <= R;
                pipeline(0).A <= M & '0';
                pipeline(0).S <= std_logic_vector(-signed(M & '0'));
                pipeline(0).P <= (others => '0');
                pipeline(0).P(N downto 1) <= R;
                pipeline(0).count <= N/4-1;
            else
                pipeline(0).valid <= '0';
            end if;
            
            -- Stage 1: First quarter of multiplication
            if pipeline(0).valid = '1' then
                pipeline(1).valid <= '1';
                pipeline(1).M <= pipeline(0).M;
                pipeline(1).R <= pipeline(0).R;
                pipeline(1).A <= pipeline(0).A;
                pipeline(1).S <= pipeline(0).S;
                
                -- Process first N/4 bits
                case pipeline(0).P(1 downto 0) is
                    when "01" =>
                        temp_sum := std_logic_vector(unsigned(pipeline(0).P(2*N+1 downto N+1)) + unsigned(pipeline(0).A));
                    when "10" =>
                        temp_sum := std_logic_vector(unsigned(pipeline(0).P(2*N+1 downto N+1)) + unsigned(pipeline(0).S));
                    when others =>
                        temp_sum := pipeline(0).P(2*N+1 downto N+1);
                end case;
                
                pipeline(1).P <= temp_sum & pipeline(0).P(N downto 0);
                pipeline(1).count <= pipeline(0).count;
            else
                pipeline(1).valid <= '0';
            end if;
            
            -- Stage 2: Second quarter of multiplication
            if pipeline(1).valid = '1' then
                pipeline(2).valid <= '1';
                pipeline(2).M <= pipeline(1).M;
                pipeline(2).R <= pipeline(1).R;
                pipeline(2).A <= pipeline(1).A;
                pipeline(2).S <= pipeline(1).S;
                
                -- Process second N/4 bits
                case pipeline(1).P(1 downto 0) is
                    when "01" =>
                        temp_sum := std_logic_vector(unsigned(pipeline(1).P(2*N+1 downto N+1)) + unsigned(pipeline(1).A));
                    when "10" =>
                        temp_sum := std_logic_vector(unsigned(pipeline(1).P(2*N+1 downto N+1)) + unsigned(pipeline(1).S));
                    when others =>
                        temp_sum := pipeline(1).P(2*N+1 downto N+1);
                end case;
                
                pipeline(2).P <= temp_sum & pipeline(1).P(N downto 0);
                pipeline(2).count <= pipeline(1).count;
            else
                pipeline(2).valid <= '0';
            end if;
            
            -- Stage 3: Final processing and output
            if pipeline(2).valid = '1' then
                pipeline(3).valid <= '1';
                
                -- Process final bits and prepare output
                case pipeline(2).P(1 downto 0) is
                    when "01" =>
                        temp_sum := std_logic_vector(unsigned(pipeline(2).P(2*N+1 downto N+1)) + unsigned(pipeline(2).A));
                    when "10" =>
                        temp_sum := std_logic_vector(unsigned(pipeline(2).P(2*N+1 downto N+1)) + unsigned(pipeline(2).S));
                    when others =>
                        temp_sum := pipeline(2).P(2*N+1 downto N+1);
                end case;
                
                pipeline(3).P <= temp_sum & pipeline(2).P(N downto 0);
            else
                pipeline(3).valid <= '0';
            end if;
            
            -- Output stage
            if pipeline(3).valid = '1' then
                valid <= '1';
                product <= pipeline(3).P(2*N downto 1);
            else
                valid <= '0';
            end if;
        end if;
    end process;
    
    -- Ready signal generation
    pipeline_ready <= '1' when pipeline(0).valid = '0' else '0';
    ready <= pipeline_ready;
    
end Behavioral; 