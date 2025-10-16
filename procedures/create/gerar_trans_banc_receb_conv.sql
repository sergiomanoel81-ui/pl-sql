/*
==================================================================================
Nome: Identificar Transação por Retorno de Convênio
==================================================================================
Descrição: 
  Localiza transações financeiras vinculadas a um recebimento de convênio
  específico, incluindo informações da conta bancária.
Autor: Sérgio Manoel
Data Criação: 2025-10-16
Versão: 1.0
Tabelas:
  - MOVTO_TRANS_FINANC (Movimentações Financeiras)
Dependências:
  - Function: OBTER_CONTA_BANCO()
Uso: 
  Rastreamento de transações financeiras por número de recebimento
Parâmetros:
  - NR_SEQ_CONV_RECEB: Número sequencial do convênio/recebimento
Changelog:
  v1.0 (2025-10-16) - Versão inicial
==================================================================================
*/
SELECT 
    OBTER_CONTA_BANCO(a.nr_seq_banco) AS CONTA_BANCO,
    a.*
FROM MOVTO_TRANS_FINANC a
WHERE a.NR_SEQ_CONV_RECEB = 1188;

/*
==================================================================================
Nome: Gerar Recebimento no Controle Bancário
==================================================================================
Descrição: 
  Procedure para registrar movimento de recebimento de convênio no controle
  bancário do estabelecimento.
Autor: Sérgio Manoel
Data Criação: 2025-10-16
Versão: 1.0
Tipo: PL/SQL Procedure Call
Procedure:
  - gerar_movto_receb_convenio()
Parâmetros:
  - cd_estabelecimento_p: Código do estabelecimento (ex: 7)
  - nr_seq_receb_p: Número sequencial do recebimento
  - nm_usuario_p: Nome do usuário executante
  - ie_commit_p: 'S' para confirmar / 'N' para testar
Uso: 
  Integração financeira - registro de recebimentos de convênios
Changelog:
  v1.0 (2025-10-16) - Versão inicial
==================================================================================
*/
BEGIN
    gerar_movto_receb_convenio(
        cd_estabelecimento_p => 7,
        nr_seq_receb_p => 1203,
        nm_usuario_p => 'sergio.cerqueir',
        ie_commit_p => 'N' -- Confirma alterações (COMMIT)
    );
END;
/
