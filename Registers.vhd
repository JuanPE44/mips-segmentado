
-- ====== Arquitectura de Computadoras I, 2025
-- =======
-- === Realizado por Juan Peñalba, Lautaro Bettini, Oliverio Papuccio  ===

-- === Registers.
-- =======


library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use IEEE.std_logic_unsigned.all;

entity Registers is
  port (clk, reset, wr : in  std_logic;
        reg1_rd, reg2_rd, reg_wr: in std_logic_vector(4 downto 0);
        data_wr : in std_logic_vector(31 downto 0);
        data1_rd, data2_rd : out std_logic_vector(31 downto 0)
       );
end entity;

architecture Behavioral of Registers is
  type reg_array is array(0 to 31) of std_logic_vector(31 downto 0);
  signal regs : reg_array;
begin

  process(clk, reset)
  begin

    if reset = '1' then
      regs <= (others => (others => '0'));
      
    elsif falling_edge(clk) then
    
      if wr = '1' and reg_wr /= "00000" then
        regs(conv_integer(reg_wr)) <= data_wr;
      end if;
      
    end if;
    
  end process;

  data1_rd <= regs(conv_integer(reg1_rd)) when reg1_rd /= "00000" else x"00000000";
  data2_rd <= regs(conv_integer(reg2_rd)) when reg2_rd /= "00000" else x"00000000";
end architecture;