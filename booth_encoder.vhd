library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.booth_pkg.all;

entity booth_encoder is
    port (
        clk : in std_logic;
        rst : in std_logic;
        mode : in BOOTH_MODE;
        multiplicand : in std_logic_vector(DATA_WIDTH-1 downto 0);
        multiplier : in std_logic_vector(DATA_WIDTH-1 downto 0);
        partial_products : out PARTIAL_PRODUCT(0 to DATA_WIDTH/2);
        num_partial_products : out integer range 0 to DATA_WIDTH/2
    );
end booth_encoder;

architecture rtl of booth_encoder is
    signal extended_multiplier : std_logic_vector(DATA_WIDTH+1 downto 0);
begin
    process(clk, rst)
        variable pp_count : integer := 0;
        variable temp_product : signed(DATA_WIDTH-1 downto 0);
        variable multiplicand_signed : signed(DATA_WIDTH-1 downto 0);
    begin
        if rst = '1' then
            for i in partial_products'range loop
                partial_products(i) <= (others => '0');
            end loop;
            num_partial_products <= 0;
            
        elsif rising_edge(clk) then
            multiplicand_signed := signed(multiplicand);
            extended_multiplier <= multiplier & "00";  -- Append two zeros for Radix-4
            pp_count := 0;
            
            case mode is
                when RADIX4 =>
                    -- Radix-4 Booth encoding
                    for i in 0 to DATA_WIDTH/2-1 loop
                        case extended_multiplier(2*i+2 downto 2*i) is
                            when "000" | "111" =>
                                temp_product := (others => '0');
                            when "001" | "010" =>
                                temp_product := multiplicand_signed;
                            when "011" =>
                                temp_product := shift_left(multiplicand_signed, 1);
                            when "100" =>
                                temp_product := -shift_left(multiplicand_signed, 1);
                            when "101" | "110" =>
                                temp_product := -multiplicand_signed;
                            when others =>
                                temp_product := (others => '0');
                        end case;
                        
                        -- Shift based on position
                        partial_products(pp_count) <= shift_left(temp_product, 2*i);
                        pp_count := pp_count + 1;
                    end loop;
                    
                when RADIX2 =>
                    -- Traditional Radix-2 Booth encoding
                    for i in 0 to DATA_WIDTH-1 loop
                        if multiplier(i) = '1' then
                            partial_products(pp_count) <= shift_left(multiplicand_signed, i);
                            pp_count := pp_count + 1;
                        end if;
                    end loop;
            end case;
            
            num_partial_products <= pp_count;
        end if;
    end process;
end rtl; 