/*
==================================================================================
Nome: Remoção de Duplicatas de Exames Laboratoriais em PROCEDIMENTO_PACIENTE
==================================================================================
Descrição: 
  Remove lançamentos duplicados do painel bioquímico de rotina pré-hemodiálise
  na tabela PROCEDIMENTO_PACIENTE, mantendo apenas uma ocorrência de cada exame
  por conta paciente, por dia. Identifica duplicatas usando ROW_NUMBER() com
  PARTITION BY (NR_INTERNO_CONTA, CD_PROCEDIMENTO, TRUNC(DT_PROCEDIMENTO)).

Autor: Sérgio Manoel
Data Criação: 2026-05-04
Versão: 1.0

Tabelas:
  - PROCEDIMENTO_PACIENTE (DELETE)
  - CSB_BKP_PROC_PAC_DUPL_2026_04 (CREATE TABLE - Backup)

Função Auxiliar:
  - obter_estab_atendimento(NR_ATENDIMENTO) → Retorna o CD_ESTABELECIMENTO

Critério de Identificação de Duplicatas:
  Mesma combinação de:
    1. NR_INTERNO_CONTA       (mesma conta paciente)
    2. CD_PROCEDIMENTO        (mesmo código de exame)
    3. TRUNC(DT_PROCEDIMENTO) (mesmo dia, ignorando hora)

Critério de Manutenção:
  Mantém a linha com menor DT_PROCEDIMENTO e menor NR_SEQUENCIA (RN = 1).
  Demais cópias (RN > 1) são deletadas.

Filtros Aplicados:
  - DT_PROCEDIMENTO entre 01/04/2026 e 30/04/2026
  - CD_CONVENIO = 4
  - obter_estab_atendimento(NR_ATENDIMENTO) = 1
  - CD_PROCEDIMENTO IN (8 exames do painel pré-hemodiálise)

Códigos de Exame Tratados (Painel Bioquímico Pré-Hemodiálise):
  202010210 - DOSAGEM DE CALCIO
  202010317 - DOSAGEM DE CREATININA
  202010430 - DOSAGEM DE FOSFORO
  202010473 - DOSAGEM DE GLICOSE
  202010600 - DOSAGEM DE POTASSIO
  202010635 - DOSAGEM DE SODIO
  202010651 - DOSAGEM DE TRANSAMINASE GLUTAMICO PIRUVICA
  202010694 - DOSAGEM DE UREIA

Impacto:
  ⚠️ ATENÇÃO: Este script realiza DELETE em dados clínicos/faturáveis
  - Sempre execute SELECTs de validação antes do DELETE
  - SEMPRE crie a tabela de backup antes do DELETE
  - Valide com o setor de Faturamento se as contas afetadas
    já não foram fechadas/enviadas ao convênio
  - Execute em ambiente de TESTE primeiro, se possível
  - A operação não é reversível após o COMMIT

Motivos Comuns de Uso:
  - Lançamento em duplicidade por importação automática que rodou 2x
  - Erro em rotina de geração de procedimentos
  - Lançamento manual duplicado por engano
  - Correção pós-importação de exames laboratoriais

Exemplo Atual:
  Removendo ~3610 duplicatas de exames laboratoriais de hemodiálise
  no período de abril/2026, estabelecimento 1, convênio 4
  (~451 contas afetadas, 8 exames cada).

Changelog:
  v1.0 (2026-05-04) - Versão inicial

==================================================================================
*/


-- ==================================================================================
-- PASSO 1: CONSULTAR REGISTROS (Execute ANTES do DELETE)
-- ==================================================================================

-- Consulta principal — visualiza todas as linhas no escopo, com numeração de duplicata
-- (linhas com RN > 1 serão as candidatas à exclusão)
SELECT a.NR_INTERNO_CONTA,
       a.NR_ATENDIMENTO,
       obter_estab_atendimento(a.NR_ATENDIMENTO) AS CD_ESTABELECIMENTO,
       a.CD_CONVENIO,
       a.CD_PROCEDIMENTO,
       a.DT_PROCEDIMENTO,
       a.NR_SEQUENCIA,
       a.NR_SEQ_PROC_INTERNO,
       ROW_NUMBER() OVER (
           PARTITION BY a.NR_INTERNO_CONTA, a.CD_PROCEDIMENTO, TRUNC(a.DT_PROCEDIMENTO)
           ORDER BY a.DT_PROCEDIMENTO, a.NR_SEQUENCIA
       ) AS RN
  FROM PROCEDIMENTO_PACIENTE a
 WHERE a.DT_PROCEDIMENTO >= TO_DATE('01/04/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS')
   AND a.DT_PROCEDIMENTO <= TO_DATE('30/04/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
   AND a.CD_CONVENIO = 4
   AND obter_estab_atendimento(a.NR_ATENDIMENTO) = 1
   AND a.CD_PROCEDIMENTO IN (
       202010210, 202010317, 202010430, 202010473,
       202010600, 202010635, 202010651, 202010694
   )
 ORDER BY a.NR_INTERNO_CONTA, a.CD_PROCEDIMENTO, RN;


-- Resumo: total de linhas a deletar por exame
SELECT a.CD_PROCEDIMENTO,
       COUNT(*) AS LINHAS_A_DELETAR,
       COUNT(DISTINCT a.NR_INTERNO_CONTA) AS QT_CONTAS,
       ROUND(COUNT(*) / COUNT(DISTINCT a.NR_INTERNO_CONTA), 2) AS DUPL_POR_CONTA
  FROM (
       SELECT a.CD_PROCEDIMENTO, a.NR_INTERNO_CONTA,
              ROW_NUMBER() OVER (
                  PARTITION BY a.NR_INTERNO_CONTA, a.CD_PROCEDIMENTO, TRUNC(a.DT_PROCEDIMENTO)
                  ORDER BY a.DT_PROCEDIMENTO, a.NR_SEQUENCIA
              ) AS RN
         FROM PROCEDIMENTO_PACIENTE a
        WHERE a.DT_PROCEDIMENTO >= TO_DATE('01/04/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS')
          AND a.DT_PROCEDIMENTO <= TO_DATE('30/04/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
          AND a.CD_CONVENIO = 4
          AND obter_estab_atendimento(a.NR_ATENDIMENTO) = 1
          AND a.CD_PROCEDIMENTO IN (202010210, 202010317, 202010430, 202010473,
                                     202010600, 202010635, 202010651, 202010694)
  ) a
 WHERE RN > 1
 GROUP BY a.CD_PROCEDIMENTO
 ORDER BY a.CD_PROCEDIMENTO;


-- Resumo: distribuição de duplicatas por conta (verificar consistência do padrão)
SELECT LINHAS_DUPLICADAS_NA_CONTA, COUNT(*) AS QT_CONTAS
  FROM (
       SELECT NR_INTERNO_CONTA, COUNT(*) AS LINHAS_DUPLICADAS_NA_CONTA
         FROM (
              SELECT a.NR_INTERNO_CONTA,
                     ROW_NUMBER() OVER (
                         PARTITION BY a.NR_INTERNO_CONTA, a.CD_PROCEDIMENTO, TRUNC(a.DT_PROCEDIMENTO)
                         ORDER BY a.DT_PROCEDIMENTO, a.NR_SEQUENCIA
                     ) AS RN
                FROM PROCEDIMENTO_PACIENTE a
               WHERE a.DT_PROCEDIMENTO >= TO_DATE('01/04/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS')
                 AND a.DT_PROCEDIMENTO <= TO_DATE('30/04/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
                 AND a.CD_CONVENIO = 4
                 AND obter_estab_atendimento(a.NR_ATENDIMENTO) = 1
                 AND a.CD_PROCEDIMENTO IN (202010210, 202010317, 202010430, 202010473,
                                            202010600, 202010635, 202010651, 202010694)
         )
        WHERE RN > 1
        GROUP BY NR_INTERNO_CONTA
  )
 GROUP BY LINHAS_DUPLICADAS_NA_CONTA
 ORDER BY LINHAS_DUPLICADAS_NA_CONTA;


-- ==================================================================================
-- PASSO 2: CRIAR BACKUP (OBRIGATÓRIO antes do DELETE)
-- ==================================================================================

-- Cria tabela de backup com todas as linhas que serão excluídas
CREATE TABLE CSB_BKP_PROC_PAC_DUPL_2026_04 AS
SELECT a.*
  FROM PROCEDIMENTO_PACIENTE a
 WHERE a.ROWID IN (
       SELECT rid FROM (
              SELECT a.ROWID AS rid,
                     ROW_NUMBER() OVER (
                         PARTITION BY a.NR_INTERNO_CONTA, a.CD_PROCEDIMENTO, TRUNC(a.DT_PROCEDIMENTO)
                         ORDER BY a.DT_PROCEDIMENTO, a.NR_SEQUENCIA
                     ) AS RN
                FROM PROCEDIMENTO_PACIENTE a
               WHERE a.DT_PROCEDIMENTO >= TO_DATE('01/04/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS')
                 AND a.DT_PROCEDIMENTO <= TO_DATE('30/04/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
                 AND a.CD_CONVENIO = 4
                 AND obter_estab_atendimento(a.NR_ATENDIMENTO) = 1
                 AND a.CD_PROCEDIMENTO IN (202010210, 202010317, 202010430, 202010473,
                                            202010600, 202010635, 202010651, 202010694)
       )
       WHERE RN > 1
 );

-- Confirma quantidade de linhas no backup (deve bater com a contagem do PASSO 1)
SELECT COUNT(*) AS QT_BACKUP FROM CSB_BKP_PROC_PAC_DUPL_2026_04;
-- Resultado esperado: ~3610 linhas


-- ==================================================================================
-- PASSO 3: EXECUTAR EXCLUSÃO (Só execute após validar PASSO 1 e gerar backup PASSO 2)
-- ==================================================================================

DELETE FROM PROCEDIMENTO_PACIENTE
 WHERE ROWID IN (
       SELECT rid FROM (
              SELECT a.ROWID AS rid,
                     ROW_NUMBER() OVER (
                         PARTITION BY a.NR_INTERNO_CONTA, a.CD_PROCEDIMENTO, TRUNC(a.DT_PROCEDIMENTO)
                         ORDER BY a.DT_PROCEDIMENTO, a.NR_SEQUENCIA
                     ) AS RN
                FROM PROCEDIMENTO_PACIENTE a
               WHERE a.DT_PROCEDIMENTO >= TO_DATE('01/04/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS')
                 AND a.DT_PROCEDIMENTO <= TO_DATE('30/04/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
                 AND a.CD_CONVENIO = 4
                 AND obter_estab_atendimento(a.NR_ATENDIMENTO) = 1
                 AND a.CD_PROCEDIMENTO IN (202010210, 202010317, 202010430, 202010473,
                                            202010600, 202010635, 202010651, 202010694)
       )
       WHERE RN > 1
 );

-- Resultado esperado: ~3610 linhas excluídas


-- ==================================================================================
-- PASSO 4: VALIDAR EXCLUSÃO (Execute ANTES do COMMIT)
-- ==================================================================================

-- Verifica se ainda existem duplicatas no escopo (deve retornar 0)
SELECT COUNT(*) AS DUPL_RESTANTES
  FROM (
       SELECT ROW_NUMBER() OVER (
                  PARTITION BY a.NR_INTERNO_CONTA, a.CD_PROCEDIMENTO, TRUNC(a.DT_PROCEDIMENTO)
                  ORDER BY a.NR_SEQUENCIA
              ) AS RN
         FROM PROCEDIMENTO_PACIENTE a
        WHERE a.DT_PROCEDIMENTO >= TO_DATE('01/04/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS')
          AND a.DT_PROCEDIMENTO <= TO_DATE('30/04/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
          AND a.CD_CONVENIO = 4
          AND obter_estab_atendimento(a.NR_ATENDIMENTO) = 1
          AND a.CD_PROCEDIMENTO IN (202010210, 202010317, 202010430, 202010473,
                                     202010600, 202010635, 202010651, 202010694)
  )
 WHERE RN > 1;
-- Resultado esperado: 0


-- Verifica se cada conta ficou com no máximo 1 ocorrência de cada exame por dia
SELECT a.NR_INTERNO_CONTA, a.CD_PROCEDIMENTO, TRUNC(a.DT_PROCEDIMENTO) AS DIA, COUNT(*) AS QT
  FROM PROCEDIMENTO_PACIENTE a
 WHERE a.DT_PROCEDIMENTO >= TO_DATE('01/04/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS')
   AND a.DT_PROCEDIMENTO <= TO_DATE('30/04/2026 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
   AND a.CD_CONVENIO = 4
   AND obter_estab_atendimento(a.NR_ATENDIMENTO) = 1
   AND a.CD_PROCEDIMENTO IN (202010210, 202010317, 202010430, 202010473,
                              202010600, 202010635, 202010651, 202010694)
 GROUP BY a.NR_INTERNO_CONTA, a.CD_PROCEDIMENTO, TRUNC(a.DT_PROCEDIMENTO)
HAVING COUNT(*) > 1
 ORDER BY a.NR_INTERNO_CONTA, a.CD_PROCEDIMENTO;
-- Resultado esperado: nenhuma linha


-- ==================================================================================
-- IMPORTANTE: Confirme a transação após validar
-- ==================================================================================
-- COMMIT;     -- ✅ Executar para confirmar a exclusão
-- ROLLBACK;   -- ❌ Executar para desfazer a exclusão


-- ==================================================================================
-- PASSO 5: LIMPEZA (Após dias de operação confirmada, drop do backup)
-- ==================================================================================

-- Após confirmar que tudo está correto e estável (recomendado: aguardar 30 dias),
-- a tabela de backup pode ser removida.

-- DROP TABLE CSB_BKP_PROC_PAC_DUPL_2026_04;


/*
==================================================================================
CHECKLIST DE EXECUÇÃO:
  [ ] 1. Executar PASSO 1 (Consultar) e validar:
        - Contagem total de duplicatas
        - Distribuição consistente entre exames
        - Padrão esperado de ~1 duplicata por conta/exame
  [ ] 2. Validar com setor de Faturamento que as contas afetadas
        ainda não foram faturadas/enviadas ao convênio
  [ ] 3. Executar PASSO 2 (Backup) e confirmar contagem da tabela
        CSB_BKP_PROC_PAC_DUPL_2026_04
  [ ] 4. Executar PASSO 3 (DELETE) e conferir nº de linhas excluídas
  [ ] 5. Executar PASSO 4 (Validar) - todas as queries devem retornar 0
  [ ] 6. Se OK: executar COMMIT / Se erro: executar ROLLBACK
  [ ] 7. Documentar a operação (motivo, contagem, data, responsável)
  [ ] 8. Investigar a causa-raiz da duplicação para evitar recorrência
  [ ] 9. Após período de monitoramento, executar PASSO 5 (DROP backup)

TROUBLESHOOTING:
  - Se erro ORA-02292 (constraint violada):
    → Alguma duplicata tem registros filhos (ex: PROCEDIMENTO_PACIENTE_GUIA,
      LOTE_FATURAMENTO, autorização TISS, laudo)
    → Use a query de análise de constraints abaixo
    → Pode ser necessário tratar caso a caso, mantendo a duplicata vinculada

  - Se contagem do DELETE diferente do esperado (~3610):
    → Faça ROLLBACK imediatamente
    → Reanalise os filtros e o critério de PARTITION BY
    → Verifique se algum lançamento legítimo entrou no escopo

  - Se as contas estiverem fechadas/faturadas:
    → ATENÇÃO: a exclusão pode gerar divergência com convênio
    → Avalie criar um IE_SITUACAO de cancelamento em vez de DELETE físico
    → Consulte o setor de Faturamento

OBSERVAÇÕES IMPORTANTES:
  - O critério PARTITION BY usa TRUNC(DT_PROCEDIMENTO) para considerar
    duplicatas apenas no MESMO DIA. Isso preserva exames legítimos
    realizados em dias diferentes do mesmo paciente/conta.
  - O ORDER BY do ROW_NUMBER mantém a linha mais ANTIGA. Para manter
    a mais recente, use: ORDER BY DT_PROCEDIMENTO DESC, NR_SEQUENCIA DESC
  - A função obter_estab_atendimento é chamada por linha; em volumes
    muito grandes pode impactar performance. Os filtros de data, convênio
    e código atuam como pré-filtros e mitigam esse impacto.

==================================================================================
*/


-- ==================================================================================
-- BONUS: Query para Identificar TODAS as Tabelas Filhas de PROCEDIMENTO_PACIENTE
-- ==================================================================================

-- Use esta query caso encontre erro de constraint (ORA-02292) durante o DELETE
SELECT C.CONSTRAINT_NAME AS NOME_CONSTRAINT,
       C.TABLE_NAME      AS TABELA_FILHA,
       CC.COLUMN_NAME    AS COLUNA_FILHA,
       RC.TABLE_NAME     AS TABELA_PAI,
       RCC.COLUMN_NAME   AS COLUNA_PAI
  FROM ALL_CONSTRAINTS C
 INNER JOIN ALL_CONS_COLUMNS CC
         ON C.CONSTRAINT_NAME = CC.CONSTRAINT_NAME
 INNER JOIN ALL_CONSTRAINTS RC
         ON C.R_CONSTRAINT_NAME = RC.CONSTRAINT_NAME
 INNER JOIN ALL_CONS_COLUMNS RCC
         ON RC.CONSTRAINT_NAME = RCC.CONSTRAINT_NAME
 WHERE RC.TABLE_NAME = 'PROCEDIMENTO_PACIENTE'
   AND C.CONSTRAINT_TYPE = 'R'
   AND C.OWNER = 'TASY'
 ORDER BY C.TABLE_NAME;
