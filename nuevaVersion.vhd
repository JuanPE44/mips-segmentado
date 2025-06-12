library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_SIGNED.all;

entity Processor is
  port(
  -- clock señales
  Clk : in std_logic;
  Reset : in std_logic;

  -- Instruction memory
  I_DataIn : in std_logic_vector(31 downto 0);
  I_Addr : out std_logic_vector(31 downto 0);
  I_RdStb : out std_logic;
  I_WrStb : out std_logic;
  I_DataOut : out std_logic_vector(31 downto 0);


  -- Data memory
  D_DataIn : in std_logic_vector(31 downto 0);
  D_Addr : out std_logic_vector(31 downto 0);
  D_RdStb : out std_logic;
  D_WrStb : out std_logic;
  D_DataOut : out std_logic_vector(31 downto 0));
end Processor;

architecture processor_arch of Processor is

-- componente de la ALU
component ALU
  port (
    a : in std_logic_vector(31 downto 0);
    b : in std_logic_vector(31 downto 0);
    control : in std_logic_vector(2 downto 0);
    zero : out std_logic;
    result : out std_logic_vector(31 downto 0));
end component;

-- componente de registro
component Registers
  port (
    clk : in std_logic;
    reset : in std_logic;
    wr : in std_logic;
    reg1_rd : in std_logic_vector(4 downto 0);
    reg2_rd : in std_logic_vector(4 downto 0);
    reg_wr : in std_logic_vector(4 downto 0);
    data_wr : in std_logic_vector(31 downto 0);
    data1_rd : out std_logic_vector(31 downto 0);
    data2_rd : out std_logic_vector(31 downto 0));
end component;

----------------------------------------------------------------------------------
-- SEÑALES ETAPA IF 
----------------------------------------------------------------------------------

signal pc_4 : std_logic_vector(31 downto 0); -- para incremento de PC
signal pc_branch : std_logic_vector(31 downto 0); -- salto por beq
signal pc_jump : std_logic_vector(31 downto 0); -- para salto incondicional
signal reg_pc, next_reg_pc : std_logic_vector(31 downto 0); -- correspondientes al registro del program counter

-------------------------------------------------------------------
-- SEÑALES SEGMENTADO IF/ID+EX
-------------------------------------------------------------------

signal if_idEx_DataIn : std_logic_vector(31 downto 0);
signal if_idEx_pc_4 : std_logic_vector(31 downto 0);

--_______________________________________________________________--

----------------------------------------------------------------------------------
-- SEÑALES ETAPA ID + EX 
----------------------------------------------------------------------------------


signal RegWrite, RegDst, Branch, MemRead, MemtoReg, MemWrite, ALUSrc, Jump : std_logic;
signal ALUOp: std_logic_vector(1 downto 0);

signal reg_wr : std_logic_vector(4 downto 0) ; -- direccion del registro de escritura
signal data1_reg, data2_reg : std_logic_vector(31 downto 0); -- registros leidos desde el banco de registro
signal inm_extended : std_logic_vector(31 downto 0); -- describe el operando inmediato de la instruccion extendido a 32 bits
signal ALU_oper_b : std_logic_vector(31 downto 0); -- corrspondiente al segundo operando de ALU
signal ALU_control : std_logic_vector(2 downto 0); -- señales de control de la ALU
signal ALU_zero : std_logic; -- flag zero de la ALU
signal ALU_result : std_logic_vector(31 downto 0); -- resultado de la ALU

-------------------------------------------------------------------
-- SEÑALES SEGMENTADO ID+EX/MEM+WB
-------------------------------------------------------------------

signal idEx_memWb_MemRead, idEx_memWb_MemWrite, idEx_memWb_MemtoReg, idEx_memWb_RegWrite : std_logic;
signal idEx_memWb_ALU_result, idEx_memWb_data2_reg : std_logic_vector(31 downto 0);
signal idEx_memWb_reg_wr : std_logic_vector(4 downto 0);

--_______________________________________________________________--


------------------------------------------------------------------------------------
-- SEÑALES ETAPA MEM + WB 
------------------------------------------------------------------------------------

signal data_w_reg : std_logic_vector(31 downto 0); -- dato a escribir en el banco de registros (determinado en WB)

------------------------------------------------------------------------------------

begin

------------------------------------------------------------------------------------
--------------------------------- ETAPA IF -----------------------------------------
------------------------------------------------------------------------------------

-- Interfaz con memoria de Instrucciones
I_Addr <= reg_pc;
I_RdStb <= '1';
I_WrStb <= '0';
I_DataOut <= (others => '0'); -- PORQUE???

-- Proceso para el registro del Program Counter (PC)
-- Actualiza el PC con el valor de 'next_reg_pc' en cada flanco de reloj
E_PC_Register: process(Clk, Reset)
begin
  if Reset = '1' then
    reg_pc <= (others => '0');
  elsif rising_edge(Clk) then
    reg_pc <= next_reg_pc;
  end if;
end process;

-- incremento de PC
pc_4 <= reg_pc + 4;

-- mux que maneja carga de PC o jump
next_reg_pc <= pc_jump when (Jump = '1') else pc_branch when ((ALU_zero='1') and (Branch='1')) else pc_4;


--------------------------- SEGMENTADO IF/ID+EX -----------------------------------

IF_ID_PIPELINE_REGISTER: process(Clk, Reset)
begin
  if Reset = '1' then
    if_idEx_DataIn <= (others => '0');
    if_idEx_pc_4   <= (others => '0');
  elsif rising_edge(Clk) then
    if_idEx_DataIn <= I_DataIn;
    if_idEx_pc_4   <= pc_4;
  end if;
end process;

--________________________________________________________________________________--



------------------------------------------------------------------------------------
--------------------------------- ETAPA ID + EX ------------------------------------
------------------------------------------------------------------------------------


------------------------------ CONTROL UNIT ----------------------------------------

    E_UC: process (if_idEx_DataIn) 
    begin
        case (if_idEx_DataIn(31 downto 26)) is
            -- R-type
            when "000000" =>
                RegWrite <= '1';
                RegDst <= '1';
                Branch <= '0';
                MemRead <= '0';
                MemtoReg <= '0';
                MemWrite <= '0';
                ALUSrc <= '0';
                Jump <= '0';
                ALUOp <= "10";
            
            -- lw
            when "100011" => 
                RegWrite <= '1';
                RegDst <= '0';
                Branch <= '0';
                MemRead <= '1';
                MemtoReg <= '1';
                MemWrite <= '0';
                ALUSrc <= '1';
                Jump <= '0';
                ALUOp <= "00";
                
            -- sw 
            when "101011" => 
                RegWrite <= '0';
                RegDst <= '0';
                Branch <= '0';
                MemRead <= '0';
                MemtoReg <= '0';
                MemWrite <= '1';
                ALUSrc <= '1';
                Jump <= '0';
                ALUOp <= "00";

            -- beq 
            when "000100" => 
                RegWrite <= '0';
                RegDst <= '0';
                Branch <= '1';
                MemRead <= '0';
                MemtoReg <= '0';
                MemWrite <= '0';
                ALUSrc <= '0';
                Jump <= '0';
                ALUOp <= "01";
          
            -- jump
            when "000010" =>
                RegWrite <= '0';
                RegDst <= '0';
                Branch <= '0';
                MemRead <= '0';
                MemtoReg <= '0';
                MemWrite <= '0';
                ALUSrc <= '0';
                Jump <= '1';
                ALUOp <= "00";        
		
            -- otros
            when others =>		
                RegWrite <= '0';
                RegDst <= '0';
                Branch <= '0';
                MemRead <= '0';
                MemtoReg <= '0';
                MemWrite <= '0';
                ALUSrc <= '0';
                Jump <= '0';
                ALUOp <= "00";		
        end case;
    end process;
  

------------------------------- REGISTROS ------------------------------------------

E_Regs: Registers
Port map (
  clk => clk,
  reset => reset,
  wr => RegWrite,
  reg1_rd => if_idEx_DataIn(25 downto 21),
  reg2_rd => if_idEx_DataIn(20 downto 16),
  reg_wr => reg_wr,
  data_wr => data_w_reg,
  data1_rd => data1_reg,
  data2_rd => data2_reg);

-- mux de para destino de escritura en banco de registros
reg_wr <= if_idEx_DataIn(20 downto 16) when (RegDst='0') else if_idEx_DataIn(15 downto 11);

-- extension de signo del operando inmediato de la instruccion
inm_extended(31 downto 16) <= x"FFFF" when (if_idEx_DataIn(15)='1') else x"0000";
inm_extended(15 downto 0) <= if_idEx_DataIn(15 downto 0);

-- mux correspondiente a segundo operando de ALU
ALU_oper_b <= data2_reg when (ALUSrc='0') else inm_extended;

----------------------------- SALTOS PC/jump ---------------------------------------

-- determina salto incondicional
pc_jump <= (if_idEx_pc_4(31 downto 28)&inm_extended(25 downto 0)&"00"); -- FUNCIONA??

-- determina salto condicional por iguales
pc_branch <= if_idEx_pc_4 + (inm_extended(29 downto 0)&"00"); -- FUNCIONA??

---------------------------------- ALU ---------------------------------------------

E_ALU: ALU
port map(
  a => data1_reg,
  b => ALU_oper_b,
  control => ALU_control,
  zero => ALU_zero,
  result => ALU_result
);

-- Control de la ALU
  E_CtlALU: process (ALUOp, if_idEx_DataIn)
    begin 
      
        case ALUOp is
            -- lw o sw
            when "00" => 
                ALU_control <= "010"; 
           
            -- R-type
            when "10" =>
                if (if_idEx_DataIn(5 downto 0) = "100000") then
                    ALU_control <= "010"; --add 
                elsif (if_idEx_DataIn(5 downto 0) = "100010") then
                    ALU_control <= "110"; --sub
                elsif (if_idEx_DataIn(5 downto 0) = "100100") then
                    ALU_control <= "000"; --and
                elsif (if_idEx_DataIn(5 downto 0) = "100101") then
                    ALU_control <= "001"; --or
                elsif (if_idEx_DataIn(5 downto 0) = "101010") then
                    ALU_control <= "111"; --slt
                else
                    ALU_control <= "000";
                end if;
                         
            -- beq
            when "01" =>
                ALU_control <= "110";        
            when others => 
                ALU_control <= "000"; 
        end case;
    end process;


---------------------------------------------------------------------------------------
-- SEGMENTADO ID+EX/MEM+WB
---------------------------------------------------------------------------------------

EX_MEM_PIPELINE_REGISTER: process(Clk, Reset)
begin
    if Reset = '1' then
        idEx_memWb_ALU_result <= (others => '0');
        idEx_memWb_data2_reg  <= (others => '0');
        idEx_memWb_MemRead    <= '0';
        idEx_memWb_MemWrite   <= '0';
        idEx_memWb_MemtoReg   <= '0';
        idEx_memWb_RegWrite   <= '0';
        idEx_memWb_reg_wr     <= (others => '0');
    elsif rising_edge(Clk) then
        idEx_memWb_ALU_result <= ALU_result;
        idEx_memWb_data2_reg  <= data2_reg;
        idEx_memWb_MemRead    <= MemRead;
        idEx_memWb_MemWrite   <= MemWrite;
        idEx_memWb_MemtoReg   <= MemtoReg;
        idEx_memWb_RegWrite   <= RegWrite;
        idEx_memWb_reg_wr     <= reg_wr;
    end if;
end process;

--________________________________________________________________________________--



------------------------------------------------------------------------------------
--------------------------------- ETAPA MEM + WB -----------------------------------
------------------------------------------------------------------------------------

-- mux que maneja escritura en banco de registros
data_w_reg <= idEx_memWb_ALU_result when (idEx_memWb_MemtoReg = '0') else D_DataIn;

-- Manejo de memorias de Datos
D_Addr <= idEx_memWb_ALU_result;
D_RdStb <= idEx_memWb_MemRead;
D_WrStb <= idEx_memWb_MemWrite;
D_DataOut <= idEx_memWb_data2_reg;

end processor_arch; 