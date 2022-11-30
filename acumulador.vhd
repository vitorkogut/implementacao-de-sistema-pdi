library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity acumulador is
generic(
	   DATA_WIDTH : natural := 8);
port ( 
       i_val : in  std_ulogic_vector(DATA_WIDTH-1 downto 0); -- valor a adicionar 
       i_clk : in  std_logic; -- clock
       i_rst : in std_logic; -- reset
       i_pix_central : in std_logic;
       o_D : out std_ulogic_vector(DATA_WIDTH-1 downto 0)); -- data output
end acumulador;


architecture arch_1 of acumulador is
	signal w_ADDER : std_ulogic_vector(63 downto 0);
    signal contador : std_ulogic_vector(DATA_WIDTH-1 downto 0) := "00000000";
    signal valor_um : std_ulogic_vector(DATA_WIDTH-1 downto 0) := "00000001";
    signal valor_pix_central : std_ulogic_vector(63 downto 0);
begin
  process(i_rst,i_clk, i_pix_central,o_D)
  begin
  
	if (i_rst='1') then
      w_ADDER <= "0000000000000000000000000000000000000000000000000000000000000000";
      contador <= "00000000";
      valor_pix_central <= "0000000000000000000000000000000000000000000000000000000000000000";
	end if;
    
    if (rising_edge(i_clk) ) then
      contador <= contador + valor_um;
      if i_pix_central = '1' then
      	valor_pix_central(9 downto 2) <= i_val;
      else
      	w_ADDER <= STD_ULOGIC_VECTOR(unsigned(i_val) + unsigned(w_ADDER));
      end if;
      
      if contador = "00001001" then
        if unsigned(w_ADDER) < unsigned(valor_pix_central) then
        	w_ADDER <= "0000000000000000000000000000000000000000000000000000000000000000";
        else
      		w_ADDER <= STD_ULOGIC_VECTOR(unsigned(w_ADDER) - unsigned(valor_pix_central));
        end if;
        
      end if;
      o_D <= w_ADDER(DATA_WIDTH-1 downto 0);
    end if;
   
  end process;
  
  
end arch_1;