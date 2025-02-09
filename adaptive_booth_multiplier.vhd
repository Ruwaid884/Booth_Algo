library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.booth_pkg.all;

entity adaptive_booth_multiplier is
    port (
        clk : in std_logic;
        rst : in std_logic;
        -- Input operands
        multiplicand : in std_logic_vector(DATA_WIDTH-1 downto 0);
        multiplier : in std_logic_vector(DATA_WIDTH-1 downto 0);
        -- Control signals
        start : in std_logic;
        force_mode : in BOOTH_MODE := RADIX4;  -- Optional mode override
        force_adder : in ADDER_TYPE := CARRY_LOOKAHEAD;  -- Optional adder override
        pipeline_stages : in integer range 1 to 4 := 2;  -- Configurable pipeline depth
        -- Output signals
        result : out std_logic_vector(2*DATA_WIDTH-1 downto 0);
        done : out std_logic;
        busy : out std_logic
    );
end adaptive_booth_multiplier;

architecture rtl of adaptive_booth_multiplier is
    -- Configuration signals
    signal current_config : MULTIPLIER_CONFIG;
    signal selected_mode : BOOTH_MODE;
    signal selected_adder : ADDER_TYPE;
    
    -- Pipeline registers
    type pipeline_stage_type is record
        valid : std_logic;
        partial_products : PARTIAL_PRODUCT(0 to DATA_WIDTH/2);
        num_products : integer range 0 to DATA_WIDTH/2;
        result : std_logic_vector(2*DATA_WIDTH-1 downto 0);
    end record;
    
    type pipeline_array is array (0 to 3) of pipeline_stage_type;
    signal pipeline : pipeline_array;
    
    -- Component signals
    signal encoder_partial_products : PARTIAL_PRODUCT(0 to DATA_WIDTH/2);
    signal encoder_num_products : integer range 0 to DATA_WIDTH/2;
    signal adder_result : std_logic_vector(2*DATA_WIDTH-1 downto 0);
    
    -- Intermediate signals for adder connection
    signal adder_partial_products : PARTIAL_PRODUCT(0 to DATA_WIDTH/2);
    signal adder_num_products : integer range 0 to DATA_WIDTH/2;
    
    -- State machine
    type state_type is (IDLE, CONFIGURE, ENCODE, ADD, PIPELINE_FORWARD, COMPLETE);
    signal state : state_type;
    
begin
    -- Booth encoder instance
    encoder: entity work.booth_encoder
        port map (
            clk => clk,
            rst => rst,
            mode => selected_mode,
            multiplicand => multiplicand,
            multiplier => multiplier,
            partial_products => encoder_partial_products,
            num_partial_products => encoder_num_products
        );
    
    -- Update intermediate signals for adder
    process(clk)
    begin
        if rising_edge(clk) then
            adder_partial_products <= pipeline(pipeline_stages-1).partial_products;
            adder_num_products <= pipeline(pipeline_stages-1).num_products;
        end if;
    end process;
    
    -- Adder unit instance
    adder: entity work.adder_unit
        port map (
            clk => clk,
            rst => rst,
            adder_type => selected_adder,
            partial_products => adder_partial_products,
            num_products => adder_num_products,
            result => adder_result
        );
    
    -- Main control process
    process(clk, rst)
        variable stage_counter : integer range 0 to 4;
    begin
        if rst = '1' then
            state <= IDLE;
            busy <= '0';
            done <= '0';
            result <= (others => '0');
            stage_counter := 0;
            selected_mode <= RADIX4;
            selected_adder <= CARRY_LOOKAHEAD;
            
            -- Reset pipeline
            for i in pipeline'range loop
                pipeline(i).valid <= '0';
                pipeline(i).num_products <= 0;
                pipeline(i).result <= (others => '0');
            end loop;
            
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if start = '1' then
                        -- Determine optimal configuration
                        current_config <= select_optimal_mode(multiplicand, multiplier);
                        state <= CONFIGURE;
                        busy <= '1';
                        done <= '0';
                    end if;
                    
                when CONFIGURE =>
                    -- Apply configuration (with optional overrides)
                    if force_mode /= RADIX4 then
                        selected_mode <= force_mode;
                    else
                        selected_mode <= current_config.mode;
                    end if;
                    
                    if force_adder /= CARRY_LOOKAHEAD then
                        selected_adder <= force_adder;
                    else
                        selected_adder <= current_config.adder_type;
                    end if;
                    
                    stage_counter := 0;
                    state <= ENCODE;
                    
                when ENCODE =>
                    -- Store encoder results in first pipeline stage
                    pipeline(0).partial_products <= encoder_partial_products;
                    pipeline(0).num_products <= encoder_num_products;
                    pipeline(0).valid <= '1';
                    state <= PIPELINE_FORWARD;
                    
                when PIPELINE_FORWARD =>
                    -- Forward data through pipeline stages
                    for i in pipeline'range loop
                        if i < pipeline_stages-1 then
                            pipeline(i+1) <= pipeline(i);
                        end if;
                    end loop;
                    
                    stage_counter := stage_counter + 1;
                    if stage_counter = pipeline_stages then
                        state <= ADD;
                    end if;
                    
                when ADD =>
                    -- Final addition stage
                    result <= adder_result;
                    state <= COMPLETE;
                    
                when COMPLETE =>
                    busy <= '0';
                    done <= '1';
                    state <= IDLE;
            end case;
        end if;
    end process;
    
end rtl; 