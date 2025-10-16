/*
==================================================================================
Nome: Encerrar Atividades Abertas Antigas
==================================================================================
Descrição: 
  Encerra automaticamente atividades que estão abertas há mais de 7 dias,
  definindo a data de encerramento para as 18:00 do dia da atividade e
  ajustando os minutos trabalhados.

Autor: Sérgio Manoel
Data Criação: 2025-10-16
Versão: 1.1

Tabela:
  - MAN_ORDEM_SERV_ATIV (UPDATE)

Dependências:
  - Function: minutos_ate_18()

Regras de Negócio:
  - Encerra apenas atividades com DT_FIM_ATIVIDADE NULL
  - Considera atividades com mais de 7 dias em aberto
  - Define horário de encerramento para 18:00 do dia da atividade
  - Soma os minutos restantes até 18:00 no campo QT_MINUTO

Impacto:
  ⚠️ ATENÇÃO: Este script realiza UPDATE em massa
  - Sempre execute em ambiente de TESTE primeiro
  - Faça BACKUP da tabela antes de executar
  - Valide os registros que serão afetados

Uso:
  Executar mensalmente ou quando houver acúmulo de atividades antigas abertas

Changelog:
  v1.1 (2025-10-16) - Melhorada documentação e validações
  v1.0 (2025-01-16) - Versão inicial

==================================================================================
*/

UPDATE MAN_ORDEM_SERV_ATIV
SET DT_FIM_ATIVIDADE = TRUNC(DT_ATIVIDADE) + INTERVAL '18' HOUR,
    QT_MINUTO = QT_MINUTO + minutos_ate_18(DT_ATIVIDADE)
WHERE DT_FIM_ATIVIDADE IS NULL
  AND TRUNC(SYSDATE - DT_ATIVIDADE) > 7;

-- IMPORTANTE: Não esqueça de fazer COMMIT ou ROLLBACK
-- COMMIT;
-- ROLLBACK;
