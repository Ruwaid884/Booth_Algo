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
    
    -- Component interfaces
    type PARTIAL_PRODUCT is array (natural range <>) of signed(DATA_WIDTH-1 downto 0);
    
    -- Function declarations
    function select_optimal_mode(
        multiplicand_value : std_logic_vector(DATA_WIDTH-1 downto 0);
        multiplier_value : std_logic_vector(DATA_WIDTH-1 downto 0)
    ) return MULTIPLIER_CONFIG;
    
end package booth_pkg;

package body booth_pkg is
    -- Implementation of the mode selection function
    function select_optimal_mode(
        multiplicand_value : std_logic_vector(DATA_WIDTH-1 downto 0);
        multiplier_value : std_logic_vector(DATA_WIDTH-1 downto 0)
    ) return MULTIPLIER_CONFIG is
        variable config : MULTIPLIER_CONFIG;
        variable zero_count : integer := 0;
    begin
        -- Count number of zeros to determine sparsity
        for i in multiplier_value'range loop
            if multiplier_value(i) = '0' then
                zero_count := zero_count + 1;
            end if;
        end loop;
        
        -- Select mode based on sparsity
        if zero_count > DATA_WIDTH/2 then
            config.mode := RADIX4; -- Use Radix-4 for sparse numbers
        else
            config.mode := RADIX2; -- Use Radix-2 for dense numbers
        end if;
        
        -- Select adder type based on timing requirements
        config.adder_type := CARRY_LOOKAHEAD;
        
        -- Default pipeline stages
        config.pipeline_stages := 2;
        
        return config;
    end function;
end package body; 