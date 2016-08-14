LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
ENTITY ram_ip IS
   PORT
   (
      clk,rst: 			IN   std_logic;
      data_in_ram:  		IN   std_logic_vector (15 downto 0);
      w_addr_ram:  		IN   unsigned (3 downto 0);
      r_addr_ram:   		IN   unsigned (3 downto 0);
      we_ram:    			IN   std_logic;
      data_out_ram:     OUT  std_logic_vector (15 DOWNTO 0)
   );
END ram_ip;
ARCHITECTURE rtl_ip OF ram_ip IS
   TYPE mem IS ARRAY (9 downto 0) OF std_logic_vector(15 DOWNTO 0);
   SIGNAL ram_block : mem:=(others=>(others=>'0'));
BEGIN
   PROCESS (clk)
   BEGIN
      if rising_edge(clk) THEN
         IF (we_ram = '1') THEN
            ram_block(to_integer(w_addr_ram)) <= data_in_ram;
         END IF;
         data_out_ram(15 downto 0) <= ram_block(to_integer(r_addr_ram));
      END IF;
   END PROCESS;
END rtl_ip;


