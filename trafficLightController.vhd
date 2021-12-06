library ieee;
use ieee.std_logic_1164.all;



entity trafficLightController is
	port( 
				 SSCS  : in std_logic;
				 Gclock : in std_logic;
				 Greset : in std_logic;
				 MSTL  : out std_logic_vector(2 downto 0);
				 SSTL  : out std_logic_vector(2 downto 0));

end trafficLightController;


architecture struct of trafficLightController is

	component dff 
		port(d,clk : in std_logic;
				q : out std_logic);
	end component;
	

	
	signal dffs_out : std_logic_vector(1 downto 0);
	signal dffs_in : std_logic_vector(1 downto 0);
	--signal newclock : std_logic;

	
	signal mainlight : std_logic_vector(2 downto 0);
	signal sidelight : std_logic_vector(2 downto 0);


begin

	--x1 = dffs_out(1)
	--x0 = dffs_out(0)
	

	dffs_in(1) <= ((not dffs_out(1)) and dffs_out(0)) or (dffs_out(1) and (not dffs_out(0)));
	dffs_in(0) <= ((not dffs_out(0)) and SSCS) or (dffs_out(1) and (not dffs_out(0)));
	
	--slowing down the clock
	
	D1 :dff port map (d=>dffs_in(1) , clk =>Gclock, q=>dffs_out(1));
	D0 :dff port map (d=>dffs_in(0) , clk =>Gclock, q=>dffs_out(0));
	
	process (Greset, Gclock, mainlight, sidelight )
	begin
	

		mainlight(0) <= dffs_out(1);
		mainlight(1) <= (not dffs_out(1)) and dffs_out(0);
		mainlight(2) <= (not dffs_out(1)) and (not dffs_out(0));
		
		sidelight(0) <= (not dffs_out(1));
		sidelight(1) <= dffs_out(1) and dffs_out(0);
		sidelight(2) <= dffs_out(1) and (not dffs_out(0));
		
		--delaying the yellow light (green light should be longer then yellow light)
		if mainlight = "010" and sidelight = "001" then
			MSTL <= mainlight after 10us;
			SSTL <= sidelight;
			
		--delaying the yellow light (green light should be longer then yellow light)
		elsif mainlight = "001" and sidelight = "010" then
			MSTL <= mainlight;
			SSTL <= sidelight after 10us;
			
		else
			MSTL <= mainlight;
			SSTL <= sidelight;
		end if;
			
		
--Greset
		if Greset = '1' then  --reset light to initial state
			MSTL <= "100"; --green
			SSTL <= "001"; --red
		end if;
	end process;
	
	
	


end struct;