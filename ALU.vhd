library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
  use IEEE.std_logic_unsigned.all;

entity ALU is
  port (a, b : in std_logic_vector(31 downto 0);
        control : in std_logic_vector(2 downto 0);
        result : out std_logic_vector(31 downto 0);
        zero : out std_logic
       );
end entity;

architecture Behavioral of ALU is
  signal result_internal : std_logic_vector(31 downto 0);
begin
  process(a,b,control)
  begin 

  case control is
    when "000" =>
      result_internal <= a and b;   
    when "001" =>
      result_internal <= a or b;
    when "010" =>
      result_internal <= a + b;
    when "100" =>
      result_internal <= b(15 downto 0) & x"0000";
    when "110" =>
      result_internal <= a - b;
    when "111" =>
      if a < b then 
        result_internal <= x"00000001";
      else 
        result_internal <= x"00000000";
      end if;          
    when others =>
      result_internal <= x"00000000";
    end case;
  end process;

  result <= result_internal;
  zero <= '1' when result_internal = x"00000000" else '0';
end architecture;
