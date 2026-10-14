-- Este script da output da coluna do erro para debug

DECLARE
  v_bfile    BFILE;
  v_clob     CLOB;
  v_dest     INTEGER := 1;
  v_src      INTEGER := 1;
  v_lang     NUMBER  := DBMS_LOB.DEFAULT_LANG_CTX;
  v_warn     INTEGER;
  v_nrodi    VARCHAR2(20) := '26BR00020156066'; -- << altere aqui
  v_num      NUMBER;
  v_erros    NUMBER := 0;

  PROCEDURE chk(p_campo VARCHAR2, p_valor VARCHAR2) IS
  BEGIN
    IF p_valor IS NULL OR p_valor = '' THEN RETURN; END IF;
    v_num := TO_NUMBER(p_valor);
  EXCEPTION
    WHEN VALUE_ERROR THEN
      DBMS_OUTPUT.PUT_LINE('*** ERRO: ' || RPAD(p_campo, 30) || ' = [' || p_valor || ']');
      v_erros := v_erros + 1;
  END;

BEGIN
  DBMS_OUTPUT.ENABLE(1000000);

  -- Lê XML (idêntico à NAGP_IMP_DUIMP)
  v_bfile := BFILENAME('DUIMP_IMPORTAR', 'Duimp_' || v_nrodi || '.xml');
  DBMS_LOB.CREATETEMPORARY(v_clob, TRUE);
  DBMS_LOB.OPEN(v_bfile, DBMS_LOB.LOB_READONLY);
  DBMS_LOB.LOADCLOBFROMFILE(v_clob, v_bfile, DBMS_LOB.LOBMAXSIZE,
                             v_dest, v_src, 873, v_lang, v_warn); -- 873 = AL32UTF8
  DBMS_LOB.CLOSE(v_bfile);

  -- ── CAPA ────────────────────────────────────────────────
  DBMS_OUTPUT.PUT_LINE('=== CAPA ===');
  FOR r IN (
    SELECT X.*
      FROM XMLTABLE('/DUIMP'
             PASSING XMLTYPE(v_clob)
             COLUMNS
               VERSAODUIMP          VARCHAR2(30) PATH 'VERSAODUIMP',
               COTACAODOLAR         VARCHAR2(30) PATH 'COTACAODOLAR',
               TAXASISCOMEX         VARCHAR2(30) PATH 'TAXASISCOMEX',
               DESPESASADUANEIRAS   VARCHAR2(30) PATH 'DESPESASADUANEIRAS',
               FRETE                VARCHAR2(30) PATH 'FRETE',
               SEGURO               VARCHAR2(30) PATH 'SEGURO',
               IPI                  VARCHAR2(30) PATH 'IPI',
               PIS                  VARCHAR2(30) PATH 'PIS',
               COFINS               VARCHAR2(30) PATH 'COFINS',
               II                   VARCHAR2(30) PATH 'II',
               ICMS                 VARCHAR2(30) PATH 'ICMS',
               TOTALMATERIAISDOLAR  VARCHAR2(30) PATH 'TOTALMATERIAISDOLAR',
               VMLE                 VARCHAR2(30) PATH 'VMLE',
               VMLD                 VARCHAR2(30) PATH 'VMLD',
               VLQTDEEMB            VARCHAR2(30) PATH 'VLQTDEEMB'
           ) X
  ) LOOP
    chk('VERSAODUIMP',         r.VERSAODUIMP);
    chk('COTACAODOLAR',        r.COTACAODOLAR);
    chk('TAXASISCOMEX',        r.TAXASISCOMEX);
    chk('DESPESASADUANEIRAS',  r.DESPESASADUANEIRAS);
    chk('FRETE',               r.FRETE);
    chk('SEGURO',              r.SEGURO);
    chk('IPI',                 r.IPI);
    chk('PIS',                 r.PIS);
    chk('COFINS',              r.COFINS);
    chk('II',                  r.II);
    chk('ICMS',                r.ICMS);
    chk('TOTALMATERIAISDOLAR', r.TOTALMATERIAISDOLAR);
    chk('VMLE',                r.VMLE);
    chk('VMLD',                r.VMLD);
    chk('VLQTDEEMB',           r.VLQTDEEMB);
  END LOOP;

  -- ── ITENS ───────────────────────────────────────────────
  DBMS_OUTPUT.PUT_LINE('=== ITENS ===');
  FOR r IN (
    SELECT X.*
      FROM XMLTABLE('/DUIMP/PRODUTOS/ITEM'
             PASSING XMLTYPE(v_clob)
             COLUMNS
               IT                       VARCHAR2(10)  PATH '@IT',
               CODIGO                   VARCHAR2(30)  PATH 'CODIGO',
               QUANTIDADE               VARCHAR2(30)  PATH 'QUANTIDADE',
               VALORUNITARIODOLAR       VARCHAR2(30)  PATH 'VALORUNITARIODOLAR',
               PESO_LIQUIDO             VARCHAR2(30)  PATH 'PESO_LIQUIDO',
               PESO_BRUTO               VARCHAR2(30)  PATH 'PESO_BRUTO',
               ALIQUOTAPIS              VARCHAR2(30)  PATH 'ALIQUOTAPIS',
               ALIQUOTAPISREDUZIDA      VARCHAR2(30)  PATH 'ALIQUOTAPISREDUZIDA',
               BASECALCULOII            VARCHAR2(30)  PATH 'BASECALCULOII',
               BASECALCULOIPI           VARCHAR2(30)  PATH 'BASECALCULOIPI',
               BASECALCULOPISCOFINS     VARCHAR2(30)  PATH 'BASECALCULOPISCOFINS',
               BASECALCULOICMS          VARCHAR2(30)  PATH 'BASECALCULOICMS',
               VALORPIS                 VARCHAR2(30)  PATH 'VALORPIS',
               ALIQUOTACOFINS           VARCHAR2(30)  PATH 'ALIQUOTACOFINS',
               ALIQUOTACOFINSREDUZIDA   VARCHAR2(30)  PATH 'ALIQUOTACOFINSREDUZIDA',
               VALORCOFINS              VARCHAR2(30)  PATH 'VALORCOFINS',
               ALIQUOTAIPI              VARCHAR2(30)  PATH 'ALIQUOTAIPI',
               VALORIPI                 VARCHAR2(30)  PATH 'VALORIPI',
               ALIQUOTAII               VARCHAR2(30)  PATH 'ALIQUOTAII',
               VALORII                  VARCHAR2(30)  PATH 'VALORII',
               VALORALIQIBS             VARCHAR2(30)  PATH 'VALORALIQIBS',
               VALORALIQICBS            VARCHAR2(30)  PATH 'VALORALIQICBS',
               VALORIBSUF               VARCHAR2(30)  PATH 'VALORIBSUF',
               VALORIBSMUN              VARCHAR2(30)  PATH 'VALORIBSMUN',
               VALORCBS                 VARCHAR2(30)  PATH 'VALORCBS'
           ) X
  ) LOOP
    chk('IT='||r.IT||' CODIGO',                 r.CODIGO);
    chk('IT='||r.IT||' QUANTIDADE',             r.QUANTIDADE);
    chk('IT='||r.IT||' VALORUNITARIODOLAR',     r.VALORUNITARIODOLAR);
    chk('IT='||r.IT||' PESO_LIQUIDO',           r.PESO_LIQUIDO);
    chk('IT='||r.IT||' PESO_BRUTO',             r.PESO_BRUTO);
    chk('IT='||r.IT||' ALIQUOTAPIS',            r.ALIQUOTAPIS);
    chk('IT='||r.IT||' ALIQUOTAPISREDUZIDA',    r.ALIQUOTAPISREDUZIDA);
    chk('IT='||r.IT||' BASECALCULOII',          r.BASECALCULOII);
    chk('IT='||r.IT||' BASECALCULOIPI',         r.BASECALCULOIPI);
    chk('IT='||r.IT||' BASECALCULOPISCOFINS',   r.BASECALCULOPISCOFINS);
    chk('IT='||r.IT||' BASECALCULOICMS',        r.BASECALCULOICMS);
    chk('IT='||r.IT||' VALORPIS',               r.VALORPIS);
    chk('IT='||r.IT||' ALIQUOTACOFINS',         r.ALIQUOTACOFINS);
    chk('IT='||r.IT||' ALIQUOTACOFINSREDUZIDA', r.ALIQUOTACOFINSREDUZIDA);
    chk('IT='||r.IT||' VALORCOFINS',            r.VALORCOFINS);
    chk('IT='||r.IT||' ALIQUOTAIPI',            r.ALIQUOTAIPI);
    chk('IT='||r.IT||' VALORIPI',               r.VALORIPI);
    chk('IT='||r.IT||' ALIQUOTAII',             r.ALIQUOTAII);
    chk('IT='||r.IT||' VALORII',                r.VALORII);
    chk('IT='||r.IT||' VALORALIQIBS',           r.VALORALIQIBS);
    chk('IT='||r.IT||' VALORALIQICBS',          r.VALORALIQICBS);
    chk('IT='||r.IT||' VALORIBSUF',             r.VALORIBSUF);
    chk('IT='||r.IT||' VALORIBSMUN',            r.VALORIBSMUN);
    chk('IT='||r.IT||' VALORCBS',               r.VALORCBS);
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('=== Total de erros: ' || v_erros || ' ===');
  DBMS_LOB.FREETEMPORARY(v_clob);

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Erro geral: ' || SQLERRM);
    IF DBMS_LOB.ISTEMPORARY(v_clob) = 1 THEN
      DBMS_LOB.FREETEMPORARY(v_clob);
    END IF;
END;
