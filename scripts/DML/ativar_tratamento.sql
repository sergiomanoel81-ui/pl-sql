/*==============================================================================
 Script.......: fix_duplic_pf_cod_ext_dialise_pac18173.sql
 Autor........: Sergio Cerqueira (sergio.cerqueir)
 Data.........: 2026-04-22
 Ambiente.....: TASY Producao - Grupo CSB
 Modulo.......: Hemodialise / Integracao TDMS (PF_CODIGO_EXTERNO)
 Ticket.......: <preencher se abrir chamado Philips>

-------------------------------------------------------------------------------
 CONTEXTO
-------------------------------------------------------------------------------
 Ao tentar salvar registro em PACIENTE_TRATAMENTO para o paciente
 CD_PESSOA_FISICA = 18173, o TASY dispara a cadeia:

   PACIENTE_TRATAMENTO_BEFINSUPD  (line 18)
     -> HD_PAC_RENAL_CRON_AFT_UPDATE  (line 3)
        -> TASY.GERAR_PF_COD_EXT_DIALISE  (line 12)
           -> ORA-01422: exact fetch returns more than requested number of rows

 O SELECT INTO da linha 12 da procedure GERAR_PF_COD_EXT_DIALISE busca o
 par (PF_CODIGO_EXTERNO x PF_CODIGO_EXTERNO_DIALISE) para o paciente na
 unidade de dialise, esperando um unico registro. O bloco so trata
 NO_DATA_FOUND, entao qualquer duplicidade estoura em producao.

-------------------------------------------------------------------------------
 CAUSA RAIZ
-------------------------------------------------------------------------------
 O paciente 18173, na unidade HD_UNIDADE_DIALISE NR_SEQUENCIA = 10, tem
 DOIS codigos TDMS ativos:

   +------------------+--------------+-------------+----------------------+
   | PF_CODIGO_EXTERNO| CD_EXTERNO   | DIALISE_SEQ | Criado em / por      |
   +------------------+--------------+-------------+----------------------+
   | 1244             | 377          | 1236        | 08/12/25 - flavia.b. |
   | 1574             | 450          | 6716        | 20/04/26 - flavia.b. |
   +------------------+--------------+-------------+----------------------+

 O par 1244/1236 existe ha 4 meses e e o codigo efetivamente usado/sincronizado
 com o equipamento externo (TDMS). O par 1574/6716 foi criado hoje, muito
 provavelmente porque o SELECT INTO da procedure falhou em encontrar o par
 original em alguma janela de concorrencia ou estado transitorio, gerando
 novo codigo. Dai em diante toda nova tentativa de INSERT/UPDATE em
 PACIENTE_TRATAMENTO desse paciente explode.

-------------------------------------------------------------------------------
 DECISAO
-------------------------------------------------------------------------------
 Remover o par mais recente (1574 em PF_CODIGO_EXTERNO e 6716 em
 PF_CODIGO_EXTERNO_DIALISE), preservando o par 1244/1236.

 Justificativas:
   1. Par 1244/1236 tem 4 meses de vida -> provavelmente ja sincronizado
      com o TDMS externo.
   2. Par 1574/6716 nasceu travado no mesmo instante do erro -> nunca foi
      usado em cadastro valido.
   3. Nao existem FKs externas para PF_CODIGO_EXTERNO / PF_CODIGO_EXTERNO_DIALISE
      fora do proprio vinculo interno (unica FK: PFCOEXTDIA_PFCOEXT_FK).
   4. Busca em tabelas HD_* por colunas tipo COD_EXT/EXTERNO/TDMS/PF_COD
      retornou apenas flags S/N, sem armazenamento de valor de codigo externo.

-------------------------------------------------------------------------------
 OBJETOS AFETADOS (somente DELETE)
-------------------------------------------------------------------------------
   - PF_CODIGO_EXTERNO_DIALISE  (NR_SEQUENCIA = 6716)   -> filho, deletar 1o
   - PF_CODIGO_EXTERNO          (NR_SEQUENCIA = 1574)   -> pai,   deletar 2o

 Nenhum objeto de codigo (package/procedure/trigger) e alterado por este
 script. O bug estrutural da procedure GERAR_PF_COD_EXT_DIALISE (falta de
 tratamento de TOO_MANY_ROWS e ausencia de unique constraint) deve ser
 reportado no Suporte Philips em chamado separado.

-------------------------------------------------------------------------------
 IMPACTO E RISCOS
-------------------------------------------------------------------------------
   - Risco: baixo. A duplicidade e isolada (apenas paciente 18173/unidade 10).
   - Janela: pode ser executado em horario comercial.
   - Usuario impactado: apenas atendentes que tentem salvar tratamento
     deste paciente (atualmente BLOQUEADOS pelo ORA-01422).
   - Nao ha impacto em integracoes externas porque o codigo removido (450)
     nunca foi usado com sucesso.

-------------------------------------------------------------------------------
 PLANO DE EXECUCAO
-------------------------------------------------------------------------------
   Passo 1 - Validacao PRE    : exibir as 2 linhas que serao afetadas.
   Passo 2 - SAVEPOINT        : criar ponto de retorno.
   Passo 3 - DELETE filho     : PF_CODIGO_EXTERNO_DIALISE NR_SEQ = 6716.
   Passo 4 - DELETE pai       : PF_CODIGO_EXTERNO        NR_SEQ = 1574.
   Passo 5 - Validacao POS    : confirmar que so restou 1 linha (377).
   Passo 6 - Teste regressao  : simular o SELECT INTO da procedure e
                                confirmar retorno de linha unica.
   Passo 7 - COMMIT / ROLLBACK: decisao manual com base no passo 5 e 6.

-------------------------------------------------------------------------------
 PLANO DE ROLLBACK
-------------------------------------------------------------------------------
   Enquanto a transacao nao for comitada:
       ROLLBACK TO SAVEPOINT sp_antes_delete_tdms_dup;
   Se ja comitado:
       Reaplicar os 2 registros originais a partir deste script (valores
       preservados nos blocos de validacao PRE abaixo) ou a partir de backup
       logico/flashback query:
       SELECT * FROM pf_codigo_externo         AS OF TIMESTAMP <ts>
        WHERE nr_sequencia = 1574;
       SELECT * FROM pf_codigo_externo_dialise AS OF TIMESTAMP <ts>
        WHERE nr_sequencia = 6716;

==============================================================================*/


-- ============================================================================
-- PASSO 1 - VALIDACAO PRE-EXECUCAO
-- ============================================================================
-- Confirmar que existem exatamente 2 linhas para o paciente 18173 na
-- unidade 10 com IE_TIPO_CODIGO_EXTERNO = 'TDMS'. Rodar e conferir antes
-- de seguir.

PROMPT ==== PRE: duplicidade atual ====

SELECT  a.nr_sequencia              nr_seq_pf_cod_ext,
        a.cd_pessoa_fisica,
        a.cd_pessoa_fisica_externo  cd_externo,
        a.ie_tipo_codigo_externo    ie_tipo,
        a.dt_atualizacao_nrec       dt_criacao_pf,
        a.nm_usuario_nrec           usuario_pf,
        b.nr_sequencia              nr_seq_dialise,
        b.nr_seq_hd_unidade_dialise nr_seq_unid,
        b.dt_atualizacao_nrec       dt_criacao_dial,
        b.nm_usuario_nrec           usuario_dial
FROM    pf_codigo_externo          a,
        pf_codigo_externo_dialise  b
WHERE   a.cd_pessoa_fisica          = '18173'
AND     a.ie_tipo_codigo_externo    = 'TDMS'
AND     a.nr_sequencia              = b.nr_seq_pf_codigo_externo
AND     b.nr_seq_hd_unidade_dialise = 10
ORDER BY a.nr_sequencia;

-- Esperado: 2 linhas -> (1244/1236 CD=377) e (1574/6716 CD=450).
-- Se o retorno for diferente, PARAR e reinvestigar.


-- ============================================================================
-- PASSO 2 - SAVEPOINT
-- ============================================================================
SAVEPOINT sp_antes_delete_tdms_dup;


-- ============================================================================
-- PASSO 3 - DELETE FILHO (PF_CODIGO_EXTERNO_DIALISE)
-- ============================================================================
-- Remove primeiro o lado filho por causa da FK PFCOEXTDIA_PFCOEXT_FK.

DELETE FROM pf_codigo_externo_dialise
 WHERE nr_sequencia              = 6716
   AND nr_seq_pf_codigo_externo  = 1574        -- dupla verificacao
   AND nr_seq_hd_unidade_dialise = 10;

-- Esperado: 1 row deleted.


-- ============================================================================
-- PASSO 4 - DELETE PAI (PF_CODIGO_EXTERNO)
-- ============================================================================
DELETE FROM pf_codigo_externo
 WHERE nr_sequencia             = 1574
   AND cd_pessoa_fisica          = '18173'     -- dupla verificacao
   AND ie_tipo_codigo_externo    = 'TDMS'
   AND cd_pessoa_fisica_externo  = '450';

-- Esperado: 1 row deleted.


-- ============================================================================
-- PASSO 5 - VALIDACAO POS-EXECUCAO
-- ============================================================================
-- Deve retornar EXATAMENTE 1 linha: a do codigo 377 (par 1244/1236).

PROMPT ==== POS: situacao apos DELETEs ====

SELECT  a.nr_sequencia              nr_seq_pf_cod_ext,
        a.cd_pessoa_fisica,
        a.cd_pessoa_fisica_externo  cd_externo,
        b.nr_sequencia              nr_seq_dialise,
        b.nr_seq_hd_unidade_dialise nr_seq_unid
FROM    pf_codigo_externo          a,
        pf_codigo_externo_dialise  b
WHERE   a.cd_pessoa_fisica          = '18173'
AND     a.ie_tipo_codigo_externo    = 'TDMS'
AND     a.nr_sequencia              = b.nr_seq_pf_codigo_externo
AND     b.nr_seq_hd_unidade_dialise = 10
ORDER BY a.nr_sequencia;


-- ============================================================================
-- PASSO 6 - TESTE DE NAO-REGRESSAO
-- ============================================================================
-- Simula exatamente o SELECT INTO da procedure GERAR_PF_COD_EXT_DIALISE
-- (linha 12). Deve retornar 1 linha. Se retornar 0 ou 2+, NAO COMMITAR.

PROMPT ==== TESTE: simulando SELECT INTO da procedure ====

SELECT  a.nr_sequencia            nr_seq_pf_cod_ext_w_simulado,
        COUNT(*) OVER ()          qt_linhas
FROM    pf_codigo_externo          a,
        pf_codigo_externo_dialise  b
WHERE   a.cd_pessoa_fisica          = '18173'
AND     a.ie_tipo_codigo_externo    = 'TDMS'
AND     a.nr_sequencia              = b.nr_seq_pf_codigo_externo
AND     b.nr_seq_hd_unidade_dialise = 10;

-- Esperado: 1 linha com qt_linhas = 1.


-- ============================================================================
-- PASSO 7 - DECISAO FINAL
-- ============================================================================
-- Revisar os resultados dos passos 5 e 6:
--   * Passo 5 com 1 linha (CD_EXTERNO = 377)  -> OK
--   * Passo 6 com qt_linhas = 1               -> OK
-- Se os dois OK, efetivar com COMMIT. Caso contrario, ROLLBACK.

-- COMMIT;

-- ROLLBACK TO SAVEPOINT sp_antes_delete_tdms_dup;
-- ROLLBACK;


-- ============================================================================
-- POS-DEPLOY (opcional, apos COMMIT)
-- ============================================================================
-- Orientar atendente Flavia Bastos a reabrir a tela de tratamento do
-- paciente 18173 e salvar novamente. O erro ORA-01422 nao deve mais ocorrer.
--
-- Abrir chamado no Suporte Philips com os seguintes pontos:
--   1. Procedure TASY.GERAR_PF_COD_EXT_DIALISE nao trata TOO_MANY_ROWS
--      (linha 12 do corpo: SELECT a.nr_sequencia INTO nr_seq_pf_cod_ext_w).
--   2. Nao existe unique constraint que previna duplicidade na combinacao
--      (CD_PESSOA_FISICA, IE_TIPO_CODIGO_EXTERNO='TDMS', NR_SEQ_HD_UNIDADE_DIALISE).
--   3. A falta de tratamento da excecao permite que a base acumule
--      duplicidades silenciosas e gere bloqueio posterior em qualquer
--      INSERT/UPDATE sobre PACIENTE_TRATAMENTO do paciente afetado.
-- ============================================================================
