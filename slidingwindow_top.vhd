------------------------------------------------
-- Design: Sliding Window
-- Entity: slidingwindow_top
-- Author: Douglas Santos
-- Rev.  : 1.0
-- Date  : 21/05/2020
------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity slidingwindow_top is
  generic (
    IMAGE_WIDTH   : integer;
    IMAGE_HEIGHT  : integer;
    WINDOW_WIDTH  : integer;
    WINDOW_HEIGHT : integer;
    PIXEL_WIDTH   : integer
  );
  port (
    i_VALID : in std_logic;
    i_PIX   : in std_logic_vector(PIXEL_WIDTH-1 downto 0);

    i_RSTN  : in std_logic;
    i_CLK   : in std_logic;

    o_VALID : out std_logic;
    o_PIX   : out std_logic_vector(PIXEL_WIDTH-1 downto 0)
  );
end entity;

architecture arch of slidingwindow_top is
  ---- TYPES DECLARATION ----
  -- cria um tipo array 2D para atribuir os sinais da janela
  type t_WINDOW is array(WINDOW_WIDTH-1 downto 0, WINDOW_HEIGHT-1 downto 0) of std_logic_vector(PIXEL_WIDTH-1 downto 0);
  -- cria um tipo array 1D para atribuir os sinais de saida dos buffers de linha
  type t_ROWBUF_OUTS is array(WINDOW_HEIGHT-2 downto 0) of std_logic_vector(PIXEL_WIDTH-1 downto 0);
  
  ---- SIGNALS DECLARATION ----
  signal w_WINDOW      : t_WINDOW;
  signal w_ROWBUF_OUTS : t_ROWBUF_OUTS;
  signal w_VALID       : std_logic;
  signal calculo : std_ulogic_vector(15 downto 0);
  signal w_rst_acumulador : std_logic := '0';
  signal w_dado : std_ulogic_vector(7 downto 0);
  signal w_clk_acumulador : std_logic;
  signal w_saida_acumulador : std_ulogic_vector(7 downto 0);
  signal w_pix_central_flag : std_logic := '0';
  constant pausa : time := 4 ns;

  ---- COMPONENTS DECLARATION ----
  component slidingwindow_valid
    generic (
      IMAGE_WIDTH   : integer;
      IMAGE_HEIGHT  : integer;
      WINDOW_WIDTH  : integer;
      WINDOW_HEIGHT : integer
    );
    port (
      i_VALID : in std_logic;
      i_RSTN  : in std_logic;
      i_CLK   : in std_logic;
      o_VALID : out std_logic
    );
  end component;

  component rowbuffer
    generic (
      IMAGE_WIDTH : integer;
      PIXEL_WIDTH : integer
    );
    port (
      i_VALID : in std_logic;
      i_PIX   : in std_logic_vector(PIXEL_WIDTH-1 downto 0);
  
      i_CLK   : in std_logic;
  
      o_PIX   : out std_logic_vector(PIXEL_WIDTH-1 downto 0)
    );
  end component rowbuffer;
  
  component pixreg
    generic (
      PIXEL_WIDTH : integer
    );
    port (
      i_VALID : in std_logic;
      i_PIX   : in std_logic_vector(PIXEL_WIDTH-1 downto 0);
      i_CLK   : in std_logic;
      o_PIX   : out std_logic_vector(PIXEL_WIDTH-1 downto 0)
    );
  end component;
  
begin

  ----------------------------------------------------------------
  -------------------- VALIDACAO DAS JANELAS ---------------------
  ----------------------------------------------------------------

  -- instancia entidade responsavel por definicao da validade da janela
  u_SLIDINGWINDOW_VALID : slidingwindow_valid
  generic map (
    IMAGE_WIDTH   => IMAGE_WIDTH,
    IMAGE_HEIGHT  => IMAGE_HEIGHT,
    WINDOW_WIDTH  => WINDOW_WIDTH,
    WINDOW_HEIGHT => WINDOW_HEIGHT
  )
  port map (
    i_VALID => i_VALID,
    i_RSTN  => i_RSTN,
    i_CLK   => i_CLK,
    o_VALID => w_VALID
  );
  
  ----------------------------------------------------------------
  ----------------------- BUFFERS DE LINHA -----------------------
  ----------------------------------------------------------------
  
  -- instancia o primeiro buffer de linha, que tem como entrada i_PIX
  -- a saida do buffer de linha vai para um array que possui todas as saidas de buffers
  u_FIRST_ROWBUFFER : rowbuffer
  generic map (
    IMAGE_WIDTH => IMAGE_WIDTH,
    PIXEL_WIDTH => PIXEL_WIDTH
  )
  port map (
    i_VALID => i_VALID,
    i_PIX   => i_PIX,
    i_CLK   => i_CLK,
    o_PIX   => w_ROWBUF_OUTS(WINDOW_HEIGHT-2)
  );
  
  -- gera as instancias dos proximos buffers de linha
  gen_ROWBUFFERS : for i in WINDOW_HEIGHT-3 downto 0 generate
    -- cada buffer de linha possui como entrada a saida do buffer anterior
    -- a saida do buffer de linha vai para um array que possui todas as saidas de buffers, em sua respectiva posicao
    u_ROWBUFFER : rowbuffer
    generic map (
      IMAGE_WIDTH => IMAGE_WIDTH,
      PIXEL_WIDTH => PIXEL_WIDTH
    )
    port map (
      i_VALID => i_VALID,
      i_PIX   => w_ROWBUF_OUTS(i+1),
      i_CLK   => i_CLK,
      o_PIX   => w_ROWBUF_OUTS(i)
    );
  end generate;
  
  ----------------------------------------------------------------
  -------------------- REGISTRADORES DA JANELA -------------------
  ----------------------------------------------------------------
  
  -- instancia um registrador para o pixel de entrada do sistema
  -- esse pixel e o equivalente a posicao mais superior a esquerda da janela
  -- a saida e atribuida para o array 2D que armazena a janela (w_WINDOW)
  u_PIXREG_INPUT : pixreg
  generic map ( PIXEL_WIDTH => PIXEL_WIDTH )
  port map (
    i_VALID => i_VALID,
    i_PIX   => i_PIX,
    i_CLK   => i_CLK,
    o_PIX   => w_WINDOW(WINDOW_HEIGHT-1, WINDOW_WIDTH-1)
  );
  
--  Acumulador : entity work.acumulador
--	port map(
--    	i_val => w_dado,
--        i_clk => w_clk_acumulador,
--        i_rst => w_rst_acumulador,
--        i_pix_central => w_pix_central_flag,
--        o_D => w_saida_acumulador);
  
  -- instancia os primeiros registradores para as colunas iniciais das outras linhas da janela
  -- a origem dos pixels dessas linhas da janela sao do buffer de suas respectivas posicoes
  -- a saida desses registradores vai para a sua respectiva posicao na janela
  gen_WINDOW_FROM_BUFFERS : for i in WINDOW_HEIGHT-2 downto 0 generate
    
    u_PIXREG_INPUT : pixreg
    generic map ( PIXEL_WIDTH => PIXEL_WIDTH )
    port map (
      i_VALID => i_VALID,
      i_PIX   => w_ROWBUF_OUTS(i),
      i_CLK   => i_CLK,
      o_PIX   => w_WINDOW(i, WINDOW_WIDTH-1)
    );
  end generate;
  
  -- gera os outros registradores da janela
  -- esse for generate percorre todas as linhas
  gen_REGISTERS_IN_WINDOW : for i in WINDOW_HEIGHT-1 downto 0 generate
    -- esse for generate percorre todas as colunas
    -- somente as colunas iniciais (que ja foram instanciadas anteriormente) nao sao inclusas
    gen_WINDOW_COLS : for j in WINDOW_WIDTH-2 downto 0 generate
      -- o registrador instanciado armazena o pixel a sua esquerda da janela quando dado o sinal valid
      -- o pixel de saida e atribuido para sua posicao na janela
      u_PIXREG_INPUT : pixreg
      generic map ( PIXEL_WIDTH => PIXEL_WIDTH )
      port map (
        i_VALID => i_VALID,
        i_PIX   => w_WINDOW(i, j+1),
        i_CLK   => i_CLK,
        o_PIX   => w_WINDOW(i, j)
      );
      
    end generate;
  end generate;
  
  -- Implemente aqui a operação desejada, utilizando o array 2D w_WINDOW e o sinal de janela valida w_VALID

--calcula_windown : process
--  begin
--   		wait for pausa/4;
--        w_rst_acumulador <= '1';
--        wait until w_VALID = '1';
--        w_rst_acumulador <= '0';
--        wait for pausa/4;
--        for m in 0 to 2 loop
--          for n in 0 to 2 loop
--          	 if m = 1 and n = 1 then
--               w_pix_central_flag <= '1';
--               w_dado <= w_WINDOW(m,n);
--               wait for pausa/4;
--               w_clk_acumulador <= '1';
--               wait for pausa/4;
--               w_clk_acumulador <= '0';
--               wait for pausa/4;
--               w_pix_central_flag <= '0';
--             else
--               w_dado <= w_WINDOW(m,n);
--               wait for pausa/4;
--               w_clk_acumulador <= '1';
--               wait for pausa/4;
--               w_clk_acumulador <= '0';
--               wait for pausa/4;
--             end if;
--          end loop;
--        end loop;
--         
--         w_dado <= "00000000";
--         wait for pausa/4;
--         w_clk_acumulador <= '1';
--         wait for pausa/4;
--         w_clk_acumulador <= '0';
--         
--         calculo <= STD_ULOGIC_VECTOR( unsigned(w_saida_acumulador) + unsigned(w_WINDOW(1,1)) );   
--  end process;
 
  calculo <= STD_ULOGIC_VECTOR(unsigned(w_WINDOW(0,0))+unsigned(w_WINDOW(0,1))+unsigned(w_WINDOW(0,2))+unsigned(w_WINDOW(1,0))+unsigned(w_WINDOW(1,2))+unsigned(w_WINDOW(2,0)) +unsigned(w_WINDOW(2,1))+unsigned(w_WINDOW(2,2)) - 8*unsigned( w_WINDOW(1,1)));
  
    
  o_PIX   <= calculo(7 downto 0);
  o_VALID <= w_VALID;
  
  
end architecture;
