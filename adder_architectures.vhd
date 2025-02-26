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
        variable temp_a, temp_b : std_logic_vector(DATA_WIDTH-1 downto 0);
        variable temp_pp : std_logic_vector(2*DATA_WIDTH-1 downto 0);
        variable prev_sum, prev_carry : std_logic_vector(2*DATA_WIDTH-1 downto 0);
        variable temp_result : std_logic_vector(2*DATA_WIDTH-1 downto 0);
        
        -- Function for carry lookahead logic - optimized implementation
        function generate_carries(a, b : std_logic_vector(DATA_WIDTH-1 downto 0)) return std_logic_vector is
            variable g, p, c : std_logic_vector(DATA_WIDTH-1 downto 0);
        begin
            -- Generate and propagate terms
            for i in a'range loop
                g(i) := a(i) and b(i);
                p(i) := a(i) or b(i);
            end loop;
            
            -- Calculate carries
            c(0) := '0';
            for i in 1 to DATA_WIDTH-1 loop
                c(i) := g(i-1) or (p(i-1) and c(i-1));
            end loop;
            
            return c;
        end function;
        
    begin
        if rst = '1' then
            result <= (others => '0');
            -- Initialize CSA arrays
            for i in csa_sums'range loop
                csa_sums(i) <= (others => '0');
                csa_carries(i) <= (others => '0');
            end loop;
            
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
                        -- Convert current sum and partial product to proper width
                        temp_a := std_logic_vector(temp_sum(DATA_WIDTH-1 downto 0));
                        temp_b := std_logic_vector(partial_products(i)(DATA_WIDTH-1 downto 0));
                        
                        -- Generate carries using properly sized vectors
                        carries(DATA_WIDTH-1 downto 0) <= generate_carries(temp_a, temp_b);
                        carries(DATA_WIDTH) <= '0';  -- Clear the last carry
                        
                        -- Add the partial product
                        temp_sum := temp_sum + partial_products(i);
                    end loop;
                    result <= std_logic_vector(temp_sum);
                    
                when CARRY_SAVE =>
                    -- Handle special cases first
                    if num_products = 0 then
                        result <= (others => '0');
                    elsif num_products = 1 then
                        -- Only one partial product, no need for CSA
                        temp_pp := std_logic_vector(resize(partial_products(0), 2*DATA_WIDTH));
                        result <= temp_pp;
                    else
                        -- Initialize with first partial product
                        temp_pp := std_logic_vector(resize(partial_products(0), 2*DATA_WIDTH));
                        csa_sums(0) <= temp_pp;
                        csa_carries(0) <= (others => '0');
                        
                        -- Store initial values
                        prev_sum := temp_pp;
                        prev_carry := (others => '0');
                        
                        -- Perform CSA addition for remaining products
                        for i in 1 to num_products-1 loop
                            -- Convert current partial product
                            temp_pp := std_logic_vector(resize(partial_products(i), 2*DATA_WIDTH));
                            
                            -- Optimized CSA addition
                            for j in 0 to 2*DATA_WIDTH-1 loop
                                -- Full adder logic
                                temp_result(j) := prev_sum(j) xor prev_carry(j) xor temp_pp(j);
                                
                                -- Generate carry for next bit
                                if j < 2*DATA_WIDTH-1 then
                                    prev_carry(j+1) := (prev_sum(j) and prev_carry(j)) or
                                                      (prev_sum(j) and temp_pp(j)) or
                                                      (prev_carry(j) and temp_pp(j));
                                end if;
                            end loop;
                            
                            -- Update for next iteration
                            prev_sum := temp_result;
                            csa_sums(i) <= temp_result;
                            csa_carries(i) <= prev_carry;
                        end loop;
                        
                        -- Final addition
                        result <= std_logic_vector(unsigned(prev_sum) + 
                                 shift_left(unsigned(prev_carry), 1));
                    end if;
            end case;
        end if;
    end process;
end rtl; 