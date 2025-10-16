/*
==================================================================================
Nome: Troca de Máquina de Diálise entre Unidades
==================================================================================
Descrição: 
  Realiza a transferência de máquinas de diálise entre estabelecimentos
  e unidades, atualizando os códigos de estabelecimento e unidade de diálise.

Autor: Sérgio Manoel
Data Criação: 2025-10-16
Versão: 1.0

Tabela:
  - HD_MAQUINA_DIALISE (UPDATE)

Legenda de Códigos:
  
  NR_SEQ_UNID_DIALISE (Unidade de Diálise):
    1  = Matriz
    9  = Convênios
    10 = Monte Serrat
    11 = Rio Vermelho
    12 = Santo Estevão
  
  CD_ESTABELECIMENTO (Estabelecimento):
    1 = Matriz
    3 = Monte Serrat
    4 = Convênios
    5 = Rio Vermelho
    7 = Santo Estevão

Impacto:
  ⚠️ ATENÇÃO: Este script realiza UPDATE
  - Sempre execute em ambiente de TESTE primeiro
  - Valide as máquinas que serão transferidas

Exemplo Atual:
  Transferindo máquinas 2946 e 5539 para Monte Serrat

Changelog:
  v1.0 (2025-10-16) - Versão inicial

==================================================================================
*/

UPDATE HD_MAQUINA_DIALISE
SET CD_ESTABELECIMENTO = 3,      -- Monte Serrat
    NR_SEQ_UNID_DIALISE = 10     -- Monte Serrat
WHERE CD_MAQUINA IN (2946, 5539);

-- IMPORTANTE: Não esqueça de fazer COMMIT ou ROLLBACK
-- COMMIT;
-- ROLLBACK;
