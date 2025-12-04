-- ============================================================
-- PASSO 1: VALIDAÇÃO - Liste os pacientes que serão afetados
-- ============================================================
SELECT obter_nome_paciente(NR_ATENDIMENTO) AS nome_paciente,
       COUNT(*) AS qtd_procedimentos
FROM PROCEDIMENTO_PACIENTE
WHERE (CD_MEDICO_EXECUTOR = 171 OR CD_PESSOA_FISICA = 171)
  AND TO_CHAR(DT_PROCEDIMENTO, 'MM/YYYY') = '10/2025'
  AND OBTER_ESTAB_ATENDIMENTO(NR_ATENDIMENTO) = 1
GROUP BY obter_nome_paciente(NR_ATENDIMENTO)
ORDER BY nome_paciente;

-- ============================================================
-- PASSO 2: ATUALIZAÇÃO - Execute apenas após validar
-- ============================================================
UPDATE PROCEDIMENTO_PACIENTE
SET CD_MEDICO_EXECUTOR = CASE 
                            WHEN CD_MEDICO_EXECUTOR = '140' THEN '124' 
                            ELSE CD_MEDICO_EXECUTOR 
                         END,
    CD_PESSOA_FISICA = CASE 
                          WHEN CD_PESSOA_FISICA = '140' THEN '124' 
                          ELSE CD_PESSOA_FISICA 
                       END
WHERE (CD_MEDICO_EXECUTOR = '140' OR CD_PESSOA_FISICA = '140')
  AND DT_PROCEDIMENTO > TO_DATE('01/11/2025 00:00:01', 'DD/MM/YYYY HH24:MI:SS')
  -- A conversão TO_NUMBER aqui permanece correta, assumindo que OBTER_ESTAB_ATENDIMENTO retorna CHAR e você compara com NUMBER.
  AND TO_NUMBER(OBTER_ESTAB_ATENDIMENTO(NR_ATENDIMENTO)) = 1;
-- ============================================================
-- PASSO 3: FINALIZAÇÃO
-- ============================================================
-- IMPORTANTE: Não esqueça de fazer COMMIT ou ROLLBACK
-- COMMIT;
-- ROLLBACK;
