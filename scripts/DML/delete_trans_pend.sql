/*
==================================================================================
Nome: Exclusão de Movimento Financeiro e Conciliação Bancária Pendente
==================================================================================
Descrição: 
  Exclui um movimento financeiro e sua respectiva conciliação bancária pendente,
  respeitando a ordem de dependência (primeiro filho, depois pai) para evitar
  violação de constraint de integridade referencial.

Autor: Sérgio Manoel
Data Criação: 2025-11-27
Versão: 1.0

Tabelas:
  - CONCIL_BANC_PEND_TASY (DELETE) - Tabela Filha
  - MOVTO_TRANS_FINANC (DELETE) - Tabela Pai

Relacionamento:
  CONCIL_BANC_PEND_TASY.NR_SEQ_MOVTO_TRANS → MOVTO_TRANS_FINANC.NR_SEQUENCIA
  Constraint: CONBAPT_MOVTRFI_FK

Campos Principais:
  NR_SEQUENCIA:
    Identificador único do movimento financeiro
  
  NR_SEQ_MOVTO_TRANS:
    Chave estrangeira que referencia o movimento financeiro

Impacto:
  ⚠️ ATENÇÃO: Este script realiza DELETE em dados financeiros
  - Sempre execute SELECT antes do DELETE
  - Valide os registros que serão excluídos
  - Execute em ambiente de TESTE primeiro
  - Confirme com o setor financeiro antes de executar
  - A ordem de exclusão é CRÍTICA: primeiro filho, depois pai

Motivos Comuns de Uso:
  - Movimento financeiro lançado incorretamente
  - Duplicidade de lançamento
  - Conciliação bancária com erro
  - Estorno de operação

Exemplo Atual:
  Excluindo movimento financeiro sequência 42128

Changelog:
  v1.0 (2025-11-27) - Versão inicial

==================================================================================
*/

-- ==================================================================================
-- PASSO 1: CONSULTAR REGISTROS (Execute ANTES do DELETE)
-- ==================================================================================

-- Consultar movimento financeiro
SELECT 
    NR_SEQUENCIA,
    NR_SEQ_TRANS_FINANC,
    VL_MOVIMENTO,
    DT_MOVIMENTO,
    NR_DOCUMENTO
FROM MOVTO_TRANS_FINANC
WHERE NR_SEQUENCIA = 42128;  -- ⚠️ AJUSTAR: Sequência do movimento

-- Consultar conciliação bancária vinculada
SELECT 
    NR_SEQ_MOVTO_TRANS,
    DT_CONCILIACAO,
    VL_CONCILIADO,
    NR_SEQ_CONTA_BANC
FROM CONCIL_BANC_PEND_TASY
WHERE NR_SEQ_MOVTO_TRANS = 42128;  -- ⚠️ AJUSTAR: Sequência do movimento

-- Contar registros que serão excluídos
SELECT 
    (SELECT COUNT(*) FROM MOVTO_TRANS_FINANC WHERE NR_SEQUENCIA = 42128) AS QTD_MOVIMENTO,
    (SELECT COUNT(*) FROM CONCIL_BANC_PEND_TASY WHERE NR_SEQ_MOVTO_TRANS = 42128) AS QTD_CONCILIACAO
FROM DUAL;


-- ==================================================================================
-- PASSO 2: EXECUTAR EXCLUSÃO (Só execute após validar o PASSO 1)
-- ⚠️ ORDEM CRÍTICA: Sempre delete FILHO antes do PAI
-- ==================================================================================

-- 1º DELETE: Excluir conciliação bancária (FILHO)
DELETE FROM CONCIL_BANC_PEND_TASY
WHERE NR_SEQ_MOVTO_TRANS = 42128;  -- ⚠️ AJUSTAR: Sequência do movimento

-- 2º DELETE: Excluir movimento financeiro (PAI)
DELETE FROM MOVTO_TRANS_FINANC
WHERE NR_SEQUENCIA = 42128;  -- ⚠️ AJUSTAR: Sequência do movimento


-- ==================================================================================
-- PASSO 3: VALIDAR EXCLUSÃO (Execute para confirmar)
-- ==================================================================================

-- Verificar se movimento foi excluído
SELECT COUNT(*) AS MOVIMENTO_EXISTE
FROM MOVTO_TRANS_FINANC
WHERE NR_SEQUENCIA = 42128;
-- Resultado esperado: 0

-- Verificar se conciliação foi excluída
SELECT COUNT(*) AS CONCILIACAO_EXISTE
FROM CONCIL_BANC_PEND_TASY
WHERE NR_SEQ_MOVTO_TRANS = 42128;
-- Resultado esperado: 0


-- ==================================================================================
-- IMPORTANTE: Confirme a transação após validar
-- ==================================================================================
-- COMMIT;     -- ✅ Executar para confirmar as exclusões
-- ROLLBACK;   -- ❌ Executar para desfazer as exclusões

/*
==================================================================================
CHECKLIST DE EXECUÇÃO:
  [ ] 1. Executar PASSO 1 (Consultar) e anotar dados dos registros
  [ ] 2. Validar com setor financeiro se a exclusão está correta
  [ ] 3. Confirmar que não há outras dependências (outras tabelas filhas)
  [ ] 4. Executar PASSO 2 (Excluir) - RESPEITAR A ORDEM!
  [ ] 5. Executar PASSO 3 (Validar) - Ambos devem retornar 0
  [ ] 6. Se OK: executar COMMIT / Se erro: executar ROLLBACK
  [ ] 7. Documentar o motivo da exclusão

TROUBLESHOOTING:
  - Se erro ORA-02292 (constraint violada):
    → Há outras tabelas filhas vinculadas
    → Execute a query de análise de constraints abaixo
  
  - Se erro ORA-02291 (constraint pai não encontrada):
    → Registro já foi excluído ou não existe

==================================================================================
*/

-- ==================================================================================
-- BONUS: Query para Identificar TODAS as Tabelas Filhas
-- ==================================================================================

-- Use esta query caso encontre outro erro de constraint
SELECT 
    C.CONSTRAINT_NAME AS NOME_CONSTRAINT,
    C.TABLE_NAME AS TABELA_FILHA,
    CC.COLUMN_NAME AS COLUNA_FILHA,
    RC.TABLE_NAME AS TABELA_PAI,
    RCC.COLUMN_NAME AS COLUNA_PAI
FROM ALL_CONSTRAINTS C
    INNER JOIN ALL_CONS_COLUMNS CC 
        ON C.CONSTRAINT_NAME = CC.CONSTRAINT_NAME
    INNER JOIN ALL_CONSTRAINTS RC 
        ON C.R_CONSTRAINT_NAME = RC.CONSTRAINT_NAME
    INNER JOIN ALL_CONS_COLUMNS RCC 
        ON RC.CONSTRAINT_NAME = RCC.CONSTRAINT_NAME
WHERE RC.TABLE_NAME = 'MOVTO_TRANS_FINANC'
  AND C.CONSTRAINT_TYPE = 'R'
  AND C.OWNER = 'TASY'
ORDER BY C.TABLE_NAME;
