-- ════════════════════════════════════════════════════════════════════════════
-- ALERTA: ADMISSÃO DE ENFERMAGEM PENDENTE
-- ════════════════════════════════════════════════════════════════════════════

-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ QUERY 1: CONTADOR                                                        ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

SELECT 
    -- Conta quantos pacientes distintos estão com admissão pendente
    COUNT(DISTINCT pa.CD_PESSOA_FISICA) AS "Pacientes Pendentes - Admissão Enfermagem"
FROM 
    -- Tabela principal que contém os tratamentos dos pacientes
    PACIENTE_TRATAMENTO pa
WHERE 
    -- Filtro 1: Apenas pacientes que iniciaram tratamento a partir de 01/01/2025
    -- Esta é a data de corte fixa para considerar "pacientes novos"
    pa.DT_INICIO_TRATAMENTO >= TO_DATE('01/01/2025','DD/MM/YYYY')
    
    -- Filtro 2: Paciente ainda está em tratamento (ativo)
    -- Considera ativo se: não tem data final OU data final é futura/hoje
    AND (pa.DT_FINAL_TRATAMENTO IS NULL OR pa.DT_FINAL_TRATAMENTO >= TRUNC(SYSDATE))
    
    -- Filtro 3: Filtra pela unidade de diálise (1 = Matriz)
    -- Para outras unidades, trocar este número
    AND pa.NR_SEQ_UNID_DIALISE = 1
    
    -- Filtro 4: Verifica se NÃO existe admissão de enfermagem para este paciente
    -- NOT EXISTS é mais performático que LEFT JOIN com IS NULL
    AND NOT EXISTS (
        SELECT 
            -- Usa 1 por convenção (não precisa trazer dados, só verificar existência)
            1 
        FROM 
            -- Tabela que registra as evoluções/admissões dos pacientes
            EVOLUCAO_PACIENTE e
        WHERE 
            -- Relaciona com o paciente da query principal
            e.CD_PESSOA_FISICA = pa.CD_PESSOA_FISICA
            
            -- Código específico para admissão de enfermagem
            AND e.IE_EVOLUCAO_CLINICA = 'AEF'
            
            -- Garante que a admissão foi liberada (não está em rascunho)
            AND e.DT_LIBERACAO IS NOT NULL
            
            -- Garante que o registro está ativo (não foi cancelado/excluído)
            AND e.IE_SITUACAO = 'A'
    );

-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ QUERY 2: LISTAGEM DETALHADA                                              ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

SELECT 
    -- CHR(10) adiciona quebra de linha no início (formatação do Tasy)
    CHR(10) || 
    
    -- Emoji de relógio + quantos dias o paciente está em tratamento
    '⏰ ' || TRUNC(SYSDATE - pa.DT_INICIO_TRATAMENTO) || ' dias | ' ||
    
    -- Nome do paciente truncado em 35 caracteres
    -- obter_nome_pf é uma função do Tasy que busca o nome pela chave
    'Paciente: ' || SUBSTR(obter_nome_pf(pa.CD_PESSOA_FISICA), 1, 35) || ' | ' ||
    
    -- Data de início do tratamento formatada DD/MM/AA
    'Início: ' || TO_CHAR(pa.DT_INICIO_TRATAMENTO, 'DD/MM/YY')
FROM 
    -- Mesma tabela da Query 1
    PACIENTE_TRATAMENTO pa
WHERE 
    -- MESMOS FILTROS da Query 1 (garantir consistência)
    
    -- Filtro de data de corte
    pa.DT_INICIO_TRATAMENTO >= TO_DATE('01/01/2025','DD/MM/YYYY')
    
    -- Filtro de tratamento ativo
    AND (pa.DT_FINAL_TRATAMENTO IS NULL OR pa.DT_FINAL_TRATAMENTO >= TRUNC(SYSDATE))
    
    -- Filtro de unidade
    AND pa.NR_SEQ_UNID_DIALISE = 1
    
    -- Filtro de admissão pendente
    AND NOT EXISTS (
        SELECT 1 
        FROM EVOLUCAO_PACIENTE e
        WHERE e.CD_PESSOA_FISICA = pa.CD_PESSOA_FISICA
        AND e.IE_EVOLUCAO_CLINICA = 'AEF'
        AND e.DT_LIBERACAO IS NOT NULL
        AND e.IE_SITUACAO = 'A'
    )
ORDER BY 
    -- Ordena por tempo em tratamento DESCENDENTE (mais antigos primeiro)
    -- Pacientes há mais tempo sem admissão aparecem no topo (maior urgência)
    TRUNC(SYSDATE - pa.DT_INICIO_TRATAMENTO) DESC;
