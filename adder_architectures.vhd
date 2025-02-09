library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.booth_pkg.all;

entity adder_unit is
    port (
        clk : in std_logic;
        rst : in std_logic;
        adder_type : in ADDER_TYPE;
        partial_products : in PARTIAL_PRODUCT(0 to DATA_WIDTH/2);
        num_products : in integer range 0 to DATA_WIDTH/2;
        result : out std_logic_vector(2*DATA_WIDTH-1 downto 0)
    );
end adder_unit;

architecture rtl of adder_unit is
    -- Carry signals for CLA
    signal carries : std_logic_vector(DATA_WIDTH downto 0);
    -- CSA signals
    type CSA_SUM_ARRAY is array (natural range <>) of std_logic_vector(2*DATA_WIDTH-1 downto 0);
    signal csa_sums : CSA_SUM_ARRAY(0 to DATA_WIDTH/2);
    signal csa_carries : CSA_SUM_ARRAY(0 to DATA_WIDTH/2);
    
begin
    process(clk, rst)
        variable temp_sum : signed(2*DATA_WIDTH-1 downto 0);
        variable carry : std_logic;
        
        -- Function for carry lookahead logic
        function generate_carries(a, b : std_logic_vector) return std_logic_vector is
            variable g, p, c : std_logic_vector(a'range);
        begin
            -- Generate and propagate terms
            for i in a'range loop
                g(i) := a(i) and b(i);
                p(i) := a(i) or b(i);
            end loop;
            
            -- Calculate carries
            c(0) := '0';
            for i in 1 to a'length-1 loop
                c(i) := g(i-1) or (p(i-1) and c(i-1));
            end loop;
            
            return c;
        end function;
        
    begin
        if rst = '1' then
            result <= (others => '0');
            
        elsif rising_edge(clk) then
            case adder_type is
                when RIPPLE_CARRY =>
                    -- Simple ripple carry addition
                    temp_sum := (others => '0');
                    for i in 0 to num_products-1 loop
                        temp_sum := temp_sum + partial_products(i);
                    end loop;
                    result <= std_logic_vector(temp_sum);
                    
                when CARRY_LOOKAHEAD =>
                    -- Carry Lookahead addition
                    temp_sum := (others => '0');
                    for i in 0 to num_products-1 loop
                        carries <= generate_carries(
                            std_logic_vector(temp_sum(DATA_WIDTH-1 downto 0)),
                            std_logic_vector(partial_products(i)(DATA_WIDTH-1 downto 0))
                        );
                        temp_sum := temp_sum + partial_products(i);
                    end loop;
                    result <= std_logic_vector(temp_sum);
                    
                when CARRY_SAVE =>
                    -- Carry Save addition
                    -- Initialize CSA arrays
                    csa_sums(0) <= std_logic_vector(partial_products(0));
                    csa_carries(0) <= (others => '0');
                    
                    -- Perform CSA addition
                    for i in 1 to num_products-1 loop
                        for j in 0 to 2*DATA_WIDTH-1 loop
                            -- Full adder logic for each bit
                            csa_sums(i)(j) <= csa_sums(i-1)(j) xor csa_carries(i-1)(j) xor 
                                            std_logic_vector(partial_products(i))(j);
                            csa_carries(i)(j+1) <= (csa_sums(i-1)(j) and csa_carries(i-1)(j)) or
                                                 (csa_sums(i-1)(j) and std_logic_vector(partial_products(i))(j)) or
                                                 (csa_carries(i-1)(j) and std_logic_vector(partial_products(i))(j));
                        end loop;
                    end loop;
                    
                    -- Final addition of sum and carry
                    result <= std_logic_vector(unsigned(csa_sums(num_products-1)) + 
                             shift_left(unsigned(csa_carries(num_products-1)), 1));
            end case;
        end if;
    end process;
end rtl; 