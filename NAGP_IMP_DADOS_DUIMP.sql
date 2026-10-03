CREATE OR REPLACE PROCEDURE NAGP_IMP_DADOS_DUIMP (psSeqPedido NUMBER, psNumDUIMP VARCHAR2) AS
  
BEGIN
  -- Primeiro - Atualiza a capa de acordo com nro DUIMP
  -- Valor Cambio
  
  UPDATE MAD_PIPEDIDOIMPORT X
     SET X.TXCAMBIO = (SELECT C.COTACAODOLAR FROM NAGT_DUIMP_CAPA C WHERE C.NUMERODUIMP = psNumDUIMP),
         X.USUINCLUSAO = 'AUTO'
   WHERE X.SEQPEDIDOIMPORT = psSeqPedido
     AND X.SITUACAOPED = 'S';
   
  IF SQL%ROWCOUNT > 0 THEN -- Se o seqpedido existe, esta com status "Em Simulacao" e foi atualizado, entao segue nos demais tratamentos
     
  -- Segundo - Insere os itens e respectivos valores no pedido, conforme SeqPedido e DUIMP
  
  FOR itens_duimp IN (
      SELECT SUM(D.QUANTIDADE) QUANTIDADE, D.VALORUNITARIODOLAR,
             P.SEQPRODUTO, P.SEQFAMILIA, FD.PADRAOEMBCOMPRA
        FROM NAGT_DUIMP_ITENS    D INNER JOIN MAD_PIPEDIDOIMPORT  A  ON A.SEQPEDIDOIMPORT = psSeqPedido
                                   INNER JOIN MAP_PRODUTO          P  ON TO_CHAR(P.SEQPRODUTO) = D.CODIGO
                                   INNER JOIN MAP_FAMFORNEC        F  ON F.SEQFAMILIA = P.SEQFAMILIA AND F.SEQFORNECEDOR = A.SEQFORNECEDOR
                                   INNER JOIN MAP_FAMDIVISAO       FD ON FD.SEQFAMILIA = P.SEQFAMILIA
       WHERE D.NUMERODUIMP = psNumDUIMP
       GROUP BY D.CODIGO, D.VALORUNITARIODOLAR, P.SEQPRODUTO, P.SEQFAMILIA, FD.PADRAOEMBCOMPRA
  )
  LOOP

    MERGE INTO MAD_PIPEDIMPORTPROD T
    USING DUAL
    ON (T.SEQPEDIDOIMPORT = psSeqPedido AND T.SEQPRODUTO = itens_duimp.SEQPRODUTO)
    WHEN MATCHED THEN
      UPDATE SET T.QTDSOLICITADA = itens_duimp.QUANTIDADE,
                 T.QTDEMBALAGEM  = itens_duimp.PADRAOEMBCOMPRA,
                 T.VLRITEM       = ROUND(itens_duimp.PADRAOEMBCOMPRA * itens_duimp.VALORUNITARIODOLAR, 8)
    WHEN NOT MATCHED THEN
      INSERT (SEQPEDIDOIMPORT, SEQITEMPEDIMP,           SEQPRODUTO,             SEQFAMILIA,             QTDSOLICITADA,          QTDEMBALAGEM,                VLRITEM)
      VALUES (psSeqPedido,     S_SEQITEMPEDIMP.NEXTVAL, itens_duimp.SEQPRODUTO, itens_duimp.SEQFAMILIA, itens_duimp.QUANTIDADE, itens_duimp.PADRAOEMBCOMPRA, ROUND(itens_duimp.PADRAOEMBCOMPRA * itens_duimp.VALORUNITARIODOLAR, 8));

  END LOOP;

  -- Terceiro - Atualiza Despesas do pedido conforme SeqPedido x DUIMP
  -- Precisa da CTE pois o seqTipoAdiant varia por empresa
  -- Atualmente o usuario nao atualiza impostos em despesas
  -- AFRMM: Nao esta vindo no XML, necessario digitar
  -- AFRMM: Se a importacao for Maritima, exigira na crítica posteriormente, ja que nao sera importado ira validar depois
  
       MERGE INTO MAD_PIPEDDESPESA D
    USING (
        WITH
        CAPA AS (
            SELECT C.FRETE, C.SEGURO, C.TAXASISCOMEX, C.II, C.IPI,
                   C.PIS, C.COFINS, C.ICMS, C.VMLE,
                   P.SEQPEDIDOIMPORT, P.NROEMPRESA
              FROM MAD_PIPEDIDOIMPORT P
              JOIN NAGT_DUIMP_CAPA    C ON 1=1
             WHERE P.SEQPEDIDOIMPORT = psSeqPedido AND C.NUMERODUIMP = psNumDUIMP
        ),
        MAPA AS (
            SELECT SEQPEDIDOIMPORT, NROEMPRESA, 'FRETE INTERNACIONAL' DESCR, FRETE        VALOR FROM CAPA UNION ALL
            SELECT SEQPEDIDOIMPORT, NROEMPRESA, 'SEGURO',                    SEGURO             FROM CAPA UNION ALL
            SELECT SEQPEDIDOIMPORT, NROEMPRESA, 'TAXA SISCOMEX',             TAXASISCOMEX       FROM CAPA
        --  SELECT SEQPEDIDOIMPORT, NROEMPRESA, 'IPI',                          IPI                FROM CAPA UNION ALL
        --  SELECT SEQPEDIDOIMPORT, NROEMPRESA, 'PIS',                          PIS                FROM CAPA UNION ALL
        --  SELECT SEQPEDIDOIMPORT, NROEMPRESA, 'COFINS',                       COFINS             FROM CAPA UNION ALL
        --  SELECT SEQPEDIDOIMPORT, NROEMPRESA, 'ICMS',                         ICMS               FROM CAPA UNION ALL
        --  SELECT SEQPEDIDOIMPORT, NROEMPRESA, 'VMLE (FOB) 1',                 VMLE               FROM CAPA
        )
        SELECT M.SEQPEDIDOIMPORT, T.SEQTIPOADIANT, M.NROEMPRESA, M.VALOR
          FROM MAPA M
          JOIN MAD_PITIPOADIANTAMENTO T ON T.NROEMPRESA    = M.NROEMPRESA
                                       AND T.DESCTIPOADIANT = M.DESCR
    ) SRC
    ON (    D.SEQPEDIDOIMPORT = SRC.SEQPEDIDOIMPORT
        AND D.SEQTIPOADIANT   = SRC.SEQTIPOADIANT
        AND D.NROEMPRESA      = SRC.NROEMPRESA
    )
    WHEN MATCHED THEN
        UPDATE SET D.VLRDESPESA = SRC.VALOR
    WHEN NOT MATCHED THEN
        INSERT (SEQPEDIDOIMPORT,     SEQTIPOADIANT,     NROEMPRESA,     DTAPREVPAGTO, VLRDESPESA)
        VALUES (SRC.SEQPEDIDOIMPORT, SRC.SEQTIPOADIANT, SRC.NROEMPRESA, DATE '2099-01-01',     SRC.VALOR);


  -- Quarto - Atualiza a tabela de controle

    UPDATE NAGT_DUIMP_CAPA X
       SET X.SEQPEDIDOIMPORT = psSeqPedido,
           X.IND_PROCESSADA = NVL(X.IND_PROCESSADA,0) +1,
           X.DTAPROCESSADA  = SYSDATE
      WHERE X.NUMERODUIMP = psNumDUIMP;
  
  COMMIT;
 
  END IF;
  
END;
