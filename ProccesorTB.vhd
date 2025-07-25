
-- ====== Arquitectura de Computadoras I, 2025
-- =======
-- === Memorias Harvard de Programa y Datos.
-- == El parámetro genérico C_FUNC_CLK indica si la memoria funciona en flanco ascendente o descendente 
-- =======

library ieee;
use ieee.std_logic_1164.all; 
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ProcessorTB is
end ProcessorTB;

architecture processorTB_arch  of ProcessorTB is
	-- Component declaration of the tested unit
	component Processor
   port(
   	  Clk         : in  std_logic;
	   Reset       : in  std_logic;
      -- Instruction memory
	   I_Addr      : out std_logic_vector(31 downto 0);
	   I_RdStb     : out std_logic;
	   I_WrStb     : out std_logic;
	   I_DataOut   : out std_logic_vector(31 downto 0);
	   I_DataIn    : in  std_logic_vector(31 downto 0);
	  
	-- Data memory
	   D_Addr      : out std_logic_vector(31 downto 0);
	   D_RdStb     : out std_logic;
	   D_WrStb   : out std_logic;
	   D_DataOut   : out std_logic_vector(31 downto 0);
	   D_DataIn    : in  std_logic_vector(31 downto 0)
   );
	end component;

	component Memory
	generic (
	   C_FUNC_CLK : std_logic := '0';
     	C_ELF_FILENAME     : string;
     	 C_MEM_SIZE         : integer
   );
	port (
		Clk                : in std_logic;
		Reset                : in std_logic;  			 
		Addr               : in std_logic_vector(31 downto 0);
		RdStb              : in std_logic;
		WrStb              : in std_logic;
		DataIn             : in std_logic_vector(31 downto 0);
		DataOut            : out std_logic_vector(31 downto 0)
	);
   end component;



	signal Clk         : std_logic;
	signal Reset       : std_logic;
                 
	-- Instruction memory
	signal I_Addr      : std_logic_vector(31 downto 0);
	signal I_RdStb     : std_logic;
	signal I_WrStb     : std_logic;
	signal I_DataOut   : std_logic_vector(31 downto 0);
	signal I_DataIn    : std_logic_vector(31 downto 0);

	-- Data memory
	signal D_Addr      : std_logic_vector(31 downto 0);
	signal D_RdStb     : std_logic;
	signal D_WrStb     : std_logic;
	signal D_DataOut   : std_logic_vector(31 downto 0);
	signal D_DataIn    : std_logic_vector(31 downto 0);		  
	
	constant tper_clk  : time := 50 ns;
	constant tdelay    : time := 120 ns; -- antes 150, sino no entra direccion 0

begin
	  
	-- Unit Under Test port map
	UUT : Processor
		port map (
			Clk             => Clk,
			Reset           => Reset,
			-- Instruction memory
	      I_Addr          => I_Addr,
  	      I_RdStb         => I_RdStb,
	      I_WrStb         => I_WrStb,
	      I_DataOut       => I_DataOut,
	      I_DataIn        => I_DataIn,
	      -- Data memory
	      D_Addr          => D_Addr,
  	      D_RdStb         => D_RdStb,
	      D_WrStb         => D_WrStb,
	      D_DataOut       => D_DataOut,
	      D_DataIn        => D_DataIn
		);

	-- memoria de programa
	Instruction_Mem : Memory
	generic map (
	   C_FUNC_CLK  => '0',
	   C_ELF_FILENAME     => "program1",
      C_MEM_SIZE         => 1024
   )
   port map(
	Clk                => Clk,
	Reset              => Reset,			 
	Addr               => D_Addr,
	RdStb              => D_RdStb,
	WrStb              => D_WrStb,
	DataIn             => D_DataOut,
	DataOut            => D_DataIn
);


	--memoria de datos
	Data_Mem : Memory
	generic map (
    	C_FUNC_CLK  => '0',
	   C_ELF_FILENAME     => "data",
      C_MEM_SIZE         => 1024
   )	
	port map(
		Clk                => Clk,
		Reset              => Reset,			 
		Addr               => D_Addr,
		RdStb              => D_RdStb,
		WrStb              => D_WrStb,
		DataIn             => D_DataOut,
		DataOut            => D_DataIn
	);

	-- clock
	process	
	begin		
	   Clk <= '0';
		wait for tper_clk/2;
		Clk <= '1';
		wait for tper_clk/2; 		
	end process;
	
	-- reset del comienso
	process
	begin
		Reset <= '1';
		wait for tdelay;
		Reset <= '0';	   
		wait;
	end process;  	 

end ProcessorTB_arch;