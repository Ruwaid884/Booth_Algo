library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package booth_pkg is
    -- Constants for configuration
    constant DATA_WIDTH : integer := 32;
    
    -- Multiplier modes
    type BOOTH_MODE is (RADIX2, RADIX4);
    type ADDER_TYPE is (RIPPLE_CARRY, CARRY_LOOKAHEAD, CARRY_SAVE);
    
    -- Configuration record
    type MULTIPLIER_CONFIG is record
        mode : BOOTH_MODE;
        adder_type : ADDER_TYPE;
        pipeline_stages : integer range 1 to 4;
    end record;
    
    -- Component interfaces with optimized width
    type PARTIAL_PRODUCT is array (natural range <>) of signed(DATA_WIDTH-1 downto 0);
    
    -- Function declarations
    function select_optimal_mode(
        multiplicand_value : std_logic_vector(DATA_WIDTH-1 downto 0);
        multiplier_value : std_logic_vector(DATA_WIDTH-1 downto 0)
    ) return MULTIPLIER_CONFIG;
    
end package booth_pkg;

package body booth_pkg is
    -- Enhanced implementation of the mode selection function
    function select_optimal_mode(
        multiplicand_value : std_logic_vector(DATA_WIDTH-1 downto 0);
        multiplier_value : std_logic_vector(DATA_WIDTH-1 downto 0)
    ) return MULTIPLIER_CONFIG is
        variable config : MULTIPLIER_CONFIG;
        variable zero_count, one_count, consecutive_zeros : integer := 0;
        variable prev_bit : std_logic := '0';
    begin
        -- Count numbers of zeros and consecutive zero patterns
        zero_count := 0;
        consecutive_zeros := 0;
        
        for i in multiplier_value'range loop
            if multiplier_value(i) = '0' then
                zero_count := zero_count + 1;
                if prev_bit = '0' then
                    consecutive_zeros := consecutive_zeros + 1;
                end if;
            else
                one_count := one_count + 1;
            end if;
            prev_bit := multiplier_value(i);
        end loop;
        
        -- Intelligent mode selection based on bit patterns
        if zero_count > 3*DATA_WIDTH/4 or consecutive_zeros > DATA_WIDTH/3 then
            -- Very sparse, definitely use Radix-4
            config.mode := RADIX4;
            config.adder_type := CARRY_SAVE; -- CSA works well with sparse products
        elsif zero_count > DATA_WIDTH/2 then
            -- Moderately sparse, use Radix-4
            config.mode := RADIX4;
            config.adder_type := CARRY_LOOKAHEAD;
        else
            -- Dense bit pattern, Radix-2 might work better
            config.mode := RADIX2;
            
            -- For very dense patterns, Carry Save Adder is most efficient
            if one_count > 3*DATA_WIDTH/4 then
                config.adder_type := CARRY_SAVE;
            else
                config.adder_type := CARRY_LOOKAHEAD;
            end if;
        end if;
        
        -- Choose pipeline stages based on multiplication complexity
        if zero_count > 3*DATA_WIDTH/4 then
            config.pipeline_stages := 1; -- Simple multiplication, minimal pipeline
        elsif zero_count > DATA_WIDTH/2 then
            config.pipeline_stages := 2; -- Medium complexity
        else
            config.pipeline_stages := 3; -- Complex multiplication, deeper pipeline
        end if;
        
        return config;
    end function;
end package body; 