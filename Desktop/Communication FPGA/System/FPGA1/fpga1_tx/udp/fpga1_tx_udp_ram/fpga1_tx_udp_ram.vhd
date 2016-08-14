LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
ENTITY ram IS
   PORT
   (
      clk,rst: 			IN   std_logic;
      data_in_ram:  		IN   std_logic_vector (7 downto 0);
      w_addr_ram:  		IN   unsigned (10 downto 0);
      r_addr_ram:   		IN   unsigned (10 downto 0);
      we_ram:    			IN   std_logic;
      data_out_ram:     OUT  std_logic_vector (15 DOWNTO 0)
   );
END ram;
ARCHITECTURE rtl OF ram IS
   TYPE mem IS ARRAY (1499 downto 0) OF std_logic_vector(7 DOWNTO 0);
   SIGNAL ram_block : mem:=(others=>(others=>'0'));
BEGIN
   PROCESS (clk)
   BEGIN
		
      if rising_edge(clk) THEN
         IF (we_ram = '1') THEN
            ram_block(to_integer(w_addr_ram)) <= data_in_ram;
         END IF;
         data_out_ram(15 downto 8) <= ram_block(to_integer(r_addr_ram)+1);
			data_out_ram(7 downto 0) <= ram_block(to_integer(r_addr_ram));
      END IF;
   END PROCESS;
END rtl;
