/*
==================================================================================
Nome: Listar Atividades Abertas com Grupo de Trabalho
==================================================================================
Descrição: 
  Consulta todas as atividades sem data de encerramento incluindo o grupo 
  de trabalho da OS, tempo decorrido e indicadores de criticidade.

Autor: Sérgio Manoel
Data Criação: 2025-10-16
Versão: 1.2

Tabelas:
  - MAN_ORDEM_SERV_ATIV (Atividades)
  - MAN_ORDEM_SERVICO (Ordens de Serviço)

Dependências:
  - Function: obter_nome_grupo_trabalho()

Uso: 
  Monitoramento diário de atividades pendentes e identificação de gargalos

Indicadores:
  🟢 NORMAL:   0-1 dia
  🟠 ALERTA:   2-5 dias
  🟡 ATENÇÃO:  6-7 dias
  🔴 CRÍTICO:  > 7 dias

Changelog:
  v1.2 (2025-10-16) - Ajustado indicadores de criticidade para prazos menores
  v1.1 (2025-10-16) - Adicionado grupo de trabalho e métricas
  v1.0 (2025-01-XX) - Versão inicial

==================================================================================
*/

SELECT 
    a.NR_SEQ_ORDEM_SERV AS NR_ORDEM,
    os.NR_GRUPO_TRABALHO AS CD_GRUPO,
    obter_nome_grupo_trabalho(os.NR_GRUPO_TRABALHO) AS GRUPO,
    a.DT_ATIVIDADE,
    a.NM_USUARIO_EXEC AS USUARIO,
    a.QT_MINUTO AS MINUTOS,
    ROUND(a.QT_MINUTO / 60, 2) AS HORAS_TRABALHADAS,
    TRUNC(SYSDATE - a.DT_ATIVIDADE) AS DIAS_ABERTO,
    -- Indicador de criticidade
    CASE 
        WHEN TRUNC(SYSDATE - a.DT_ATIVIDADE) > 7 THEN '🔴 CRÍTICO'
        WHEN TRUNC(SYSDATE - a.DT_ATIVIDADE) > 5 THEN '🟡 ATENÇÃO'
        WHEN TRUNC(SYSDATE - a.DT_ATIVIDADE) > 1 THEN '🟠 ALERTA'
        ELSE '🟢 NORMAL'
    END AS STATUS_PRAZO,
    a.NR_SEQ_GRUPO_TRABALHO,
    a.DS_ATIVIDADE,
    a.DS_OBSERVACAO
FROM MAN_ORDEM_SERV_ATIV a
INNER JOIN MAN_ORDEM_SERVICO os 
    ON a.NR_SEQ_ORDEM_SERV = os.NR_SEQUENCIA
WHERE a.DT_FIM_ATIVIDADE IS NULL
ORDER BY 
    TRUNC(SYSDATE - a.DT_ATIVIDADE) DESC,  -- Mais antigas primeiro
    a.DT_ATIVIDADE ASC;
