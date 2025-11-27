/*
==================================================================================
Nome: Correção de Transação Financeira em Recebimentos de Convênio
==================================================================================
Descrição: 
  Corrige o código de transação financeira vinculado a recebimentos de convênio
  quando há erro no lançamento da transação, atualizando tanto o registro do
  recebimento quanto o movimento financeiro associado.

Autor: Sérgio Manoel
Data Criação: 2025-11-27
Versão: 1.0

Tabelas:
  - CONVENIO_RECEB (UPDATE)
  - MOVTO_TRANS_FINANC (UPDATE)

Campos Principais:
  NR_SEQ_TRANS_FIN / NR_SEQ_TRANS_FINANC:
    Código da transação financeira a ser corrigida
    Exemplo: 339 = [Descrição da transação conforme seu sistema]
  
  VL_DEPOSITO:
    Valor do recebimento usado como filtro de identificação
  
  DT_RECEBIMENTO:
    Data do recebimento usado como filtro de identificação
  
  NR_SEQUENCIA:
    Identificador único do movimento financeiro

Impacto:
  ⚠️ ATENÇÃO: Este script realiza UPDATE em dados financeiros
  - Sempre execute SELECT antes do UPDATE
  - Valide os registros que serão alterados
  - Execute em ambiente de TESTE primeiro
  - Confirme com o setor financeiro antes de executar

Exemplo Atual:
  Corrigindo transação para código 339
  Recebimento: R$ 995.065,05 em 07/11/2025
  Movimento: Sequência 40842

Changelog:
  v1.0 (2025-11-27) - Versão inicial

==================================================================================
*/

-- ==================================================================================
-- PASSO 1: CONSULTAR REGISTROS (Execute ANTES do UPDATE)
-- ==================================================================================

-- Consultar CONVENIO_RECEB
SELECT 
    NR_SEQ_TRANS_FIN AS TRANSACAO_ATUAL,
    VL_DEPOSITO,
    DT_RECEBIMENTO
FROM CONVENIO_RECEB
WHERE VL_DEPOSITO = '995065,05'      -- ⚠️ AJUSTAR: Valor do recebimento
  AND DT_RECEBIMENTO = '07/11/2025'; -- ⚠️ AJUSTAR: Data do recebimento

-- Consultar MOVTO_TRANS_FINANC
SELECT 
    NR_SEQUENCIA,
    NR_SEQ_TRANS_FINANC AS TRANSACAO_ATUAL
FROM MOVTO_TRANS_FINANC
WHERE NR_SEQUENCIA = 40842;          -- ⚠️ AJUSTAR: Sequência do movimento


-- ==================================================================================
-- PASSO 2: EXECUTAR ATUALIZAÇÃO (Só execute após validar o PASSO 1)
-- ==================================================================================

-- Atualizar CONVENIO_RECEB
UPDATE CONVENIO_RECEB 
SET NR_SEQ_TRANS_FIN = 339           -- ⚠️ AJUSTAR: Código da transação correta
WHERE VL_DEPOSITO = '995065,05'
  AND DT_RECEBIMENTO = '07/11/2025';

-- Atualizar MOVTO_TRANS_FINANC
UPDATE MOVTO_TRANS_FINANC 
SET NR_SEQ_TRANS_FINANC = 339        -- ⚠️ AJUSTAR: Código da transação correta
WHERE NR_SEQUENCIA = 40842;


-- ==================================================================================
-- PASSO 3: VALIDAR ALTERAÇÕES (Execute para confirmar)
-- ==================================================================================

-- Validar CONVENIO_RECEB
SELECT 
    NR_SEQ_TRANS_FIN AS TRANSACAO_CORRIGIDA,
    VL_DEPOSITO,
    DT_RECEBIMENTO
FROM CONVENIO_RECEB
WHERE VL_DEPOSITO = '995065,05'
  AND DT_RECEBIMENTO = '07/11/2025';

-- Validar MOVTO_TRANS_FINANC
SELECT 
    NR_SEQUENCIA,
    NR_SEQ_TRANS_FINANC AS TRANSACAO_CORRIGIDA
FROM MOVTO_TRANS_FINANC
WHERE NR_SEQUENCIA = 40842;


-- ==================================================================================
-- IMPORTANTE: Confirme a transação após validar
-- ==================================================================================
-- COMMIT;     -- ✅ Executar para confirmar as alterações
-- ROLLBACK;   -- ❌ Executar para desfazer as alterações

/*
==================================================================================
CHECKLIST DE EXECUÇÃO:
  [ ] 1. Executar PASSO 1 (Consultar) e anotar valores atuais
  [ ] 2. Validar com setor financeiro se a correção está correta
  [ ] 3. Executar PASSO 2 (Atualizar)
  [ ] 4. Executar PASSO 3 (Validar) e comparar com valores do PASSO 1
  [ ] 5. Se OK: executar COMMIT / Se erro: executar ROLLBACK
  [ ] 6. Documentar a alteração realizada
==================================================================================
*/
