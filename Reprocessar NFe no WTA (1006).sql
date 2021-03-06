--############## Deverá ser informado o número da transação
DECLARE

BEGIN
  FOR DADOS IN (select numtransvenda from pcnfsaidprefat where NUMTRANSVENDA = &NUMTRANSVENDA) LOOP
  

DECLARE
  PTRANSACAO NUMBER;
  VSMSGEST   VARCHAR2(100);

  PRETORNO NUMBER(10);

  PROCEDURE FASTCONSOLIDATE(VSTABLE IN VARCHAR2, VNNUMTRANSVENDA IN NUMBER) IS
    VSSCRIPT VARCHAR2(32767);
  BEGIN
    --VNNUMTRANSVENDA := &TRANSV;
    --VSTABLE         := &TB;
    VSSCRIPT := 'INSERT INTO ' || UPPER(VSTABLE) || ' (';
  
    FOR COLUNAS IN (SELECT A.COLUMN_NAME, ROWNUM IDR
                      FROM ALL_TAB_COLUMNS A
                     WHERE A.TABLE_NAME = UPPER(VSTABLE)
                       AND EXISTS
                     (SELECT 1
                              FROM ALL_TAB_COLUMNS C
                             WHERE C.COLUMN_NAME = A.COLUMN_NAME
                               AND C.TABLE_NAME = UPPER(VSTABLE) || 'PREFAT'
                               AND C.OWNER = 'DUNORTE')
                       AND A.OWNER = 'DUNORTE'
                     ORDER BY ROWNUM)
    LOOP
    
      IF COLUNAS.IDR = 1
      THEN
        VSSCRIPT := VSSCRIPT || --'SELECT ''PREFAT'' TABELA,' ||
                    COLUNAS.COLUMN_NAME || CHR(13);
      ELSE
        VSSCRIPT := VSSCRIPT || ',' || COLUNAS.COLUMN_NAME || CHR(13);
      END IF;
    END LOOP;
    --   VSSCRIPT := VSSCRIPT ||
    --                'FROM PCMOVPREFAT WHERE NUMTRANSVENDA = :NUMTRANSVENDAPREFAT';
    VSSCRIPT := VSSCRIPT || ' ) SELECT   ';
  
    FOR COLUNAS IN (SELECT A.COLUMN_NAME, A.TABLE_NAME, ROWNUM IDR
                      FROM ALL_TAB_COLUMNS A
                     WHERE A.TABLE_NAME = UPPER(VSTABLE)
                       AND EXISTS
                     (SELECT 1
                              FROM ALL_TAB_COLUMNS C
                             WHERE C.COLUMN_NAME = A.COLUMN_NAME
                               AND C.TABLE_NAME = UPPER(VSTABLE) || 'PREFAT'
                               AND C.OWNER = 'DUNORTE')
                       AND A.OWNER = 'DUNORTE'
                     ORDER BY ROWNUM)
    LOOP
    
      IF COLUNAS.IDR = 1
      THEN
        VSSCRIPT := VSSCRIPT || --'SELECT ''PCMOV'' TABELA,' ||
                    UPPER(VSTABLE) || 'PREFAT' || '.' ||
                    COLUNAS.COLUMN_NAME || CHR(13);
      ELSE
        VSSCRIPT := VSSCRIPT || ',' || UPPER(VSTABLE) || 'PREFAT' || '.' ||
                    COLUNAS.COLUMN_NAME || CHR(13);
      END IF;
    
    END LOOP;
  
    IF INSTR(UPPER(VSTABLE), 'PCMOVCOMPLE') > 0
    THEN
      VSSCRIPT := VSSCRIPT ||
                  'FROM PCMOVPREFAT, PCMOVCOMPLEPREFAT WHERE PCMOVPREFAT.NUMTRANSITEM = PCMOVCOMPLEPREFAT.NUMTRANSITEM' ||
                  ' AND PCMOVPREFAT.NUMTRANSVENDA = ' || VNNUMTRANSVENDA;
    ELSE
      VSSCRIPT := VSSCRIPT || 'FROM ' || UPPER(VSTABLE) ||
                  'PREFAT WHERE NUMTRANSVENDA = ' || VNNUMTRANSVENDA;
    END IF;
  
    EXECUTE IMMEDIATE VSSCRIPT;
    --DBMS_OUTPUT.PUT_LINE(VSSCRIPT);
  END;
BEGIN
  PTRANSACAO := dados.numtransvenda;

  FASTCONSOLIDATE('PCMOV', PTRANSACAO);
  FASTCONSOLIDATE('PCMOVCOMPLE', PTRANSACAO);
  FASTCONSOLIDATE('PCNFSAID', PTRANSACAO);
  FASTCONSOLIDATE('PCNFBASE', PTRANSACAO);
  FASTCONSOLIDATE('PCPREST', PTRANSACAO);
  FASTCONSOLIDATE('PCLANC', PTRANSACAO);

  UPDATE PCNFSAID
     SET SITUACAONFE = '100'
        ,ESPECIE     = 'NF'
        ,TIPOEMISSAO = '1'
        ,ENVIADA     = 'S'
        ,AMBIENTENFE = 'P'
        ,NUMVIAS     = '0'
   WHERE numtransvenda = dados.numtransvenda;

  PRETORNO := PKG_ESTOQUE.VENDAS_SAIDA(PTRANSACAO, 'N', VSMSGEST);

END;


  END LOOP;

END;

--############## após consolidação das notas através do script, realizar o delete das tabelas:
--############## pcnfsaidprefat, pcmovprefat, pcmovcompleprefat e pcprestprefat

/*delete*/
begin
delete from pcnfsaidprefat t where t.numcar = &numcar;
delete from pcmovcompleprefat t where t.numtransitem in (select numtransitem from pcmov where numcar in (&numcar));
delete from pcmovprefat t where t.numtransitem in (select numtransitem from pcmov where numcar in (&numcar));
delete from pcprestprefat t where t.numtransvenda in (select numtransvenda from pcmov where numcar in (&numcar));
end;
/*fim*/