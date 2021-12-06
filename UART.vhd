library ieee;
use ieee.std_logic_1164.all;
entity UART is
	port (
	SCI_sel, R_W, clk, rst_b, RxD : in std_logic;
	ADDR2: in std_logic_vector(1 downto 0);
	DBUS : inout std_logic_vector(7 downto 0);
	SCI_IRQ, TxD : out std_logic;
	
	str : out string(1 to 5 );
	
	GReset : in std_logic;
	SSCS : in std_logic;
	MSTL : out std_logic_vector(2 downto 0); 
	SSTL : out std_logic_vector(2 downto 0)); 
end UART;

architecture uart1 of UART is

component UART_Receiver
	port (RxD, BclkX8, sysclk, rst_b, RDRF: in std_logic;
	RDR: out std_logic_vector(7 downto 0);
	setRDRF, setOE, setFE: out std_logic);
end component;

component UART_Transmitter
	port (Bclk, sysclk, rst_b, TDRE, loadTDR: in std_logic;
	DBUS: in std_logic_vector(7 downto 0);
	setTDRE, TxD: out std_logic);
end component;

component baud
	port (Sysclk, rst_b: in std_logic;
	Sel: in std_logic_vector(2 downto 0);
	BclkX8: buffer std_logic;
	Bclk: out std_logic);
end component;


component trafficLightController
port( 
 SSCS  : in std_logic;
 Gclock : in std_logic;
 Greset : in std_logic;
 MSTL  : out std_logic_vector(2 downto 0);
 SSTL  : out std_logic_vector(2 downto 0));
end component;

	
signal newTxd : std_logic;	

signal RDR : std_logic_vector(7 downto 0); -- Receive Data Register
signal SCSR : std_logic_vector(7 downto 0); -- Status Register
signal SCCR : std_logic_vector(7 downto 0); -- Control Register
signal TDRE, RDRF, OE, FE, TIE, RIE : std_logic;
signal BaudSel : std_logic_vector(2 downto 0);
signal setTDRE, setRDRF, setOE, setFE, loadTDR, loadSCCR : std_logic;
signal clrRDRF, Bclk, BclkX8, SCI_Read, SCI_Write : std_logic;

signal sigMSTL, sigSSTL : std_logic_vector(2 downto 0);


begin



RCVR: UART_Receiver port map(SSCS, BclkX8, clk, rst_b, RDRF, RDR, setRDRF,setOE, setFE);

XMIT: UART_Transmitter port map(Bclk, clk, rst_b, TDRE, loadTDR, DBUS,setTDRE, newTxD);

CLKDIV: baud port map(clk, rst_b, BaudSel, BclkX8, Bclk);

TxD<=newTxD;

trafficlight : TrafficLightController port map (newTxD, Bclk, GReset, sigMSTL, sigSSTL);


MSTL <= sigMSTL;
SSTL <= sigSSTL; 


-- This process updates the control and status registers
process (clk, rst_b)
begin
if (rst_b = '0') then
TDRE <= '1'; RDRF <= '0'; OE<= '0'; FE <= '0';
TIE <= '0'; RIE <= '0';
elsif (rising_edge(clk)) then
TDRE <= (setTDRE and not TDRE) or (not loadTDR and TDRE);
RDRF <= (setRDRF and not RDRF) or (not clrRDRF and RDRF);
OE <= (setOE and not OE) or (not clrRDRF and OE);
FE <= (setFE and not FE) or (not clrRDRF and FE);

	if (loadSCCR = '1') then TIE <= DBUS(7); RIE <= DBUS(6);
	BaudSel <= DBUS(2 downto 0);
	end if;
end if;
end process;

-- IRQ generation logic
SCI_IRQ <= '1' when ((RIE = '1' and (RDRF = '1' or OE = '1'))
or (TIE = '1' and TDRE = '1'))
else '0';


-- Bus Interface
SCSR <= TDRE & RDRF & "0000" & OE & FE;
SCCR <= TIE & RIE & "000" & BaudSel;
SCI_Read <= '1' when (SCI_sel = '1' and R_W = '0') else '0';
SCI_Write <= '1' when (SCI_sel = '1' and R_W = '1') else '0';
clrRDRF <= '1' when (SCI_Read = '1' and ADDR2 = "00") else '0';
loadTDR <= '1' when (SCI_Write = '1' and ADDR2 = "00") else '0';
loadSCCR <= '1' when (SCI_Write = '1' and ADDR2 = "10") else '0';
DBUS <= "ZZZZZZZZ" when (SCI_Read = '0') -- tristate bus when not reading
else RDR when (ADDR2 = "00") -- write appropriate register to the bus
else SCSR when (ADDR2 = "01")
else SCCR; -- dbus = sccr, if ADDR2 is "10" or "11"


--message outputs based on states
process(Bclk)
begin

if sigMSTL = "100" and sigSSTL ="001" then

str <= "Mg_Sr";

elsif sigMSTL = "010" and sigSSTL ="001" then
str <="My_Sr";

elsif sigMSTL = "001" and sigSSTL ="100" then
str <="Mr_Sg";

elsif sigMSTL = "001" and sigSSTL ="010" then
str <="Mr_Sy";


end if;

end process;




end uart1;