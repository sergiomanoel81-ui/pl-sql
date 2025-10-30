/*
==================================================================================
Nome: Geração de Movimento Financeiro para Título a Receber
==================================================================================
Descrição: 
  Script PL/SQL para gerar movimentação bancária de baixa/liquidação de 
  títulos a receber. Executa a procedure GERAR_MOVTO_TIT_BAIXA e ajusta 
  automaticamente os registros de estorno vinculando-os ao movimento original.

Autor: Sérgio Manoel
Data Criação: 2025-10-30
Versão: 1.0

Tabelas:
  - movto_trans_financ (Movimentações Financeiras)
  - titulo_receber (Títulos a Receber)
  - titulo_receber_liq (Liquidações)

Dependências:
  - Procedure: GERAR_MOVTO_TIT_BAIXA()

Uso: 
  Processar baixas de títulos a receber gerando os respectivos movimentos 
  bancários e corrigindo vínculos de estorno.

Parâmetros da Procedure:
  1. nr_titulo (5558)         - Número do título a receber
  2. nr_sequencia (1)         - Sequência da liquidação
  3. ie_opcao ('R')           - R = Receber | P = Pagar
  4. nm_usuario               - Usuário responsável pela operação
  5. ie_commit ('S')          - S = Commit automático | N = Manual

Lógica de Processamento:
  1️⃣ Gera movimentação financeira via procedure
  2️⃣ Busca o movimento original (vl_transacao > 0)
  3️⃣ Identifica registros de estorno (vl_transacao < 0)
  4️⃣ Vincula estornos ao movimento original
  5️⃣ Atualiza data de referência de saldo
  6️⃣ Marca registros como estorno (ie_estorno = 'E')

Observações:
  ⚠️ COMMIT está comentado para validação manual
  ⚠️ Ajuste o número do título (5558) conforme necessário
  ⚠️ Validar movimento gerado antes de comitar
  
Changelog:
  v1.0 (2025-10-30) - Versão inicial adaptada para contas a receber
==================================================================================
*/

DECLARE
    nr_seq_movto_trans_orig_w NUMBER(10);
 
BEGIN
    -- Gera movimentação financeira do título a receber
    GERAR_MOVTO_TIT_BAIXA(
        5558,                 -- Número do título a receber
        1,                    -- Sequência da liquidação
        'R',                  -- Tipo: R = Receber
        'sergio.cerqueir',    -- Usuário responsável
        'S'                   -- Commit automático na procedure
    );
 
    -- Busca o movimento original (valor positivo)
    SELECT MAX(nr_sequencia)
      INTO nr_seq_movto_trans_orig_w
      FROM movto_trans_financ x
     WHERE x.nr_seq_titulo_receber = 5558
       AND x.vl_transacao > 0;
    
    -- Atualiza registros de estorno vinculando ao movimento original
    UPDATE movto_trans_financ a
       SET a.nr_seq_movto_orig = nr_seq_movto_trans_orig_w,
           a.ie_estorno = 'E',
           a.dt_referencia_saldo = (
               SELECT MAX(x1.dt_referencia_saldo)
                 FROM movto_trans_financ x1
                WHERE x1.nr_sequencia = nr_seq_movto_trans_orig_w
           )
     WHERE a.vl_transacao < 0
       AND a.nr_seq_titulo_receber = 5558;
      
    -- COMMIT;  -- ⚠️ Descomente após validar os registros
 
    DBMS_OUTPUT.PUT_LINE('✅ Processamento concluído com sucesso!');
    DBMS_OUTPUT.PUT_LINE('📊 Movimento Original: ' || nr_seq_movto_trans_orig_w);
    DBMS_OUTPUT.PUT_LINE('🔄 Registros de estorno vinculados e atualizados');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('❌ ERRO: Nenhum movimento original encontrado');
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ ERRO: ' || SQLERRM);
        ROLLBACK;
END;
/
