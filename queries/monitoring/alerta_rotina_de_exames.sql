-- ════════════════════════════════════════════════════════════════════════════
-- ALERTA: AUDITORIA - ROTINAS AUTOMÁTICAS
-- ════════════════════════════════════════════════════════════════════════════

-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ QUERY 1: CONTADOR                                                        ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

SELECT 
    -- Conta quantos pacientes ativos NÃO tiveram rotina gerada no mês passado
    COUNT(DISTINCT prc.CD_PESSOA_FISICA) AS "Pacientes sem Rotina no Mês Passado"
FROM 
    -- Tabela de pacientes renais crônicos
    HD_PAC_RENAL_CRONICO prc
    
    -- JOIN com atendimento para verificar se está ativo
    INNER JOIN ATEND_CATEGORIA_CONVENIO acc
        ON prc.CD_PESSOA_FISICA = Obter_Dados_Atendimento(acc.NR_ATENDIMENTO, 'CP')
        
WHERE 
    -- Filtro 1: Apenas pacientes SEM alta (ativos)
    Obter_data_alta_Atend(acc.NR_ATENDIMENTO) IS NULL
    
    -- Filtro 2: Apenas estabelecimento 7 (Matriz)
    AND obter_estab_atendimento(acc.NR_ATENDIMENTO) = 7
    
    -- Filtro 3: Verifica se NÃO existe rotina gerada no mês passado
    -- NOT EXISTS é mais performático que LEFT JOIN com IS NULL
    AND NOT EXISTS (
        SELECT 1
        FROM hd_protocolo_exame_prescr pep
        WHERE pep.CD_PESSOA_FISICA = prc.CD_PESSOA_FISICA
        AND pep.nm_usuario = 'TASY'
        -- Primeiro dia do mês passado até último dia do mês passado
        AND pep.DT_ATUALIZACAO >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -1)
        AND pep.DT_ATUALIZACAO < TRUNC(SYSDATE, 'MM')
    );

-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ QUERY 2: LISTAGEM DETALHADA                                              ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

SELECT 
    -- CHR(10) adiciona quebra de linha no início (formatação do Tasy)
    CHR(10) || 
    
    -- Status: Emoji + identificação se teve ou não rotina no mês passado
    CASE 
        WHEN rmp.CD_PESSOA_FISICA IS NULL THEN '❌ PROBLEMA | '
        ELSE '✅ OK | '
    END ||
    
    -- Dias desde a última rotina (se houver)
    CASE 
        WHEN ur.DT_ULTIMA IS NULL THEN 'NUNCA GERADO | '
        ELSE TRUNC(SYSDATE - ur.DT_ULTIMA) || ' dias | '
    END ||
    
    -- Nome do paciente truncado em 35 caracteres
    'Paciente: ' || SUBSTR(obter_nome_pf(prc.CD_PESSOA_FISICA), 1, 35) || ' | ' ||
    
    -- Número do atendimento
    'Atend: ' || acc.NR_ATENDIMENTO || ' | ' ||
    
    -- Mês passado DINÂMICO + status da rotina
    -- Mostra o nome do mês passado (Jan, Fev, Mar, etc) e se gerou ou não
    CASE 
        WHEN TO_CHAR(ADD_MONTHS(SYSDATE, -1), 'MM') = '01' THEN 'Jan: '
        WHEN TO_CHAR(ADD_MONTHS(SYSDATE, -1), 'MM') = '02' THEN 'Fev: '
        WHEN TO_CHAR(ADD_MONTHS(SYSDATE, -1), 'MM') = '03' THEN 'Mar: '
        WHEN TO_CHAR(ADD_MONTHS(SYSDATE, -1), 'MM') = '04' THEN 'Abr: '
        WHEN TO_CHAR(ADD_MONTHS(SYSDATE, -1), 'MM') = '05' THEN 'Mai: '
        WHEN TO_CHAR(ADD_MONTHS(SYSDATE, -1), 'MM') = '06' THEN 'Jun: '
        WHEN TO_CHAR(ADD_MONTHS(SYSDATE, -1), 'MM') = '07' THEN 'Jul: '
        WHEN TO_CHAR(ADD_MONTHS(SYSDATE, -1), 'MM') = '08' THEN 'Ago: '
        WHEN TO_CHAR(ADD_MONTHS(SYSDATE, -1), 'MM') = '09' THEN 'Set: '
        WHEN TO_CHAR(ADD_MONTHS(SYSDATE, -1), 'MM') = '10' THEN 'Out: '
        WHEN TO_CHAR(ADD_MONTHS(SYSDATE, -1), 'MM') = '11' THEN 'Nov: '
        WHEN TO_CHAR(ADD_MONTHS(SYSDATE, -1), 'MM') = '12' THEN 'Dez: '
    END ||
    CASE 
        WHEN rmp.DT_ROTINA_MES_PASS IS NOT NULL THEN 
            TO_CHAR(rmp.DT_ROTINA_MES_PASS, 'DD/MM/YY')
        ELSE 'NAO GERADO'
    END ||
    
    -- Data da última rotina que teve (qualquer mês) - ou "Nunca gerado"
    CASE 
        WHEN ur.DT_ULTIMA IS NULL THEN 
            ' | Ult: NUNCA GERADO'
        ELSE 
            ' | Ult: ' || 
            CASE 
                WHEN TO_CHAR(ur.DT_ULTIMA, 'MM') = '01' THEN 'Jan/'
                WHEN TO_CHAR(ur.DT_ULTIMA, 'MM') = '02' THEN 'Fev/'
                WHEN TO_CHAR(ur.DT_ULTIMA, 'MM') = '03' THEN 'Mar/'
                WHEN TO_CHAR(ur.DT_ULTIMA, 'MM') = '04' THEN 'Abr/'
                WHEN TO_CHAR(ur.DT_ULTIMA, 'MM') = '05' THEN 'Mai/'
                WHEN TO_CHAR(ur.DT_ULTIMA, 'MM') = '06' THEN 'Jun/'
                WHEN TO_CHAR(ur.DT_ULTIMA, 'MM') = '07' THEN 'Jul/'
                WHEN TO_CHAR(ur.DT_ULTIMA, 'MM') = '08' THEN 'Ago/'
                WHEN TO_CHAR(ur.DT_ULTIMA, 'MM') = '09' THEN 'Set/'
                WHEN TO_CHAR(ur.DT_ULTIMA, 'MM') = '10' THEN 'Out/'
                WHEN TO_CHAR(ur.DT_ULTIMA, 'MM') = '11' THEN 'Nov/'
                WHEN TO_CHAR(ur.DT_ULTIMA, 'MM') = '12' THEN 'Dez/'
            END || TO_CHAR(ur.DT_ULTIMA, 'YY')
    END

FROM 
    -- Tabela de pacientes renais crônicos
    HD_PAC_RENAL_CRONICO prc
    
    -- JOIN com atendimento
    INNER JOIN ATEND_CATEGORIA_CONVENIO acc
        ON prc.CD_PESSOA_FISICA = Obter_Dados_Atendimento(acc.NR_ATENDIMENTO, 'CP')
    
    -- LEFT JOIN: Última rotina de todos os tempos
    LEFT JOIN (
        SELECT 
            CD_PESSOA_FISICA,
            MAX(DT_ATUALIZACAO) AS DT_ULTIMA
        FROM hd_protocolo_exame_prescr
        WHERE nm_usuario = 'TASY'
        GROUP BY CD_PESSOA_FISICA
    ) ur ON prc.CD_PESSOA_FISICA = ur.CD_PESSOA_FISICA
    
    -- LEFT JOIN: Rotina do mês passado
    LEFT JOIN (
        SELECT 
            CD_PESSOA_FISICA,
            MAX(DT_ATUALIZACAO) AS DT_ROTINA_MES_PASS
        FROM hd_protocolo_exame_prescr
        WHERE nm_usuario = 'TASY'
        AND DT_ATUALIZACAO >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -1)
        AND DT_ATUALIZACAO < TRUNC(SYSDATE, 'MM')
        GROUP BY CD_PESSOA_FISICA
    ) rmp ON prc.CD_PESSOA_FISICA = rmp.CD_PESSOA_FISICA

WHERE 
    -- MESMOS FILTROS da Query 1 (garantir consistência)
    
    -- Filtro de pacientes ativos
    Obter_data_alta_Atend(acc.NR_ATENDIMENTO) IS NULL
    
    -- Filtro de estabelecimento
    AND obter_estab_atendimento(acc.NR_ATENDIMENTO) = 7

ORDER BY 
    -- Ordena por: Problemáticos primeiro, depois por dias sem rotina (DESC)
    CASE WHEN rmp.CD_PESSOA_FISICA IS NULL THEN 0 ELSE 1 END ASC,
    CASE WHEN ur.DT_ULTIMA IS NULL THEN 999999 ELSE TRUNC(SYSDATE - ur.DT_ULTIMA) END DESC;
```

---

## 📊 **EXEMPLO DE SAÍDA ATUALIZADO:**

### **Hoje: 16 de Outubro de 2025**
```
❌ PROBLEMA | NUNCA GERADO | Paciente: Orlando Amado De Freitas Filho | Atend: 24075 | Set: NAO GERADO | Ult: NUNCA GERADO

❌ PROBLEMA | 174 dias | Paciente: Paciente Teste 32 | Atend: 8758 | Set: NAO GERADO | Ult: Abr/25

❌ PROBLEMA | 114 dias | Paciente: Janete Barbosa Sena | Atend: 854 | Set: NAO GERADO | Ult: Jun/25

❌ PROBLEMA | 84 dias | Paciente: Raimundo Alves De Jesus | Atend: 24484 | Set: NAO GERADO | Ult: Jul/25

✅ OK | 22 dias | Paciente: Adilene Gomes De Brito | Atend: 791 | Set: 24/09/25 | Ult: Set/25

✅ OK | 22 dias | Paciente: Alan Da Silva Oliveira | Atend: 798 | Set: 24/09/25 | Ult: Set/25
