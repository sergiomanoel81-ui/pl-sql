-- ============================================================
-- SCRIPT: REATIVAR JOBS APÓS ATUALIZAÇÃO TASY
-- Ambiente: HOMOLOGAÇÃO
-- Autor: Sérgio
-- Data: 2025-01-01
-- ============================================================

-- ATENÇÃO: SUBSTITUA O VALOR ANOTADO NO SCRIPT ANTERIOR
-- Valor original capturado: 20

-- PASSO 1: REABILITAR PROCESSAMENTO DE JOBS
ALTER SYSTEM SET JOB_QUEUE_PROCESSES = 20 SCOPE=BOTH;

-- PASSO 2: DESQUEBRAR TODAS AS JOBS
BEGIN
  FOR job_rec IN (SELECT job FROM user_jobs WHERE broken = 'Y') LOOP
    DBMS_JOB.BROKEN(job_rec.job, FALSE);
  END LOOP;
  COMMIT;
END;
/

-- PASSO 3: VALIDAR REATIVAÇÃO
PROMPT === VALIDAÇÃO ===
SELECT 
  'JOB_QUEUE_PROCESSES' AS PARAMETRO, 
  value AS VALOR 
FROM v$parameter 
WHERE name = 'job_queue_processes'
UNION ALL
SELECT 
  'JOBS_ATIVAS', 
  TO_CHAR(COUNT(*)) 
FROM user_jobs 
WHERE broken = 'N'
UNION ALL
SELECT 
  'JOBS_QUEBRADAS', 
  TO_CHAR(COUNT(*)) 
FROM user_jobs 
WHERE broken = 'Y';

-- RESULTADO ESPERADO:
-- JOB_QUEUE_PROCESSES = 20 (ou valor original)
-- JOBS_ATIVAS = 39 (ou quantidade original)
-- JOBS_QUEBRADAS = 0

PROMPT === JOBS REATIVADAS COM SUCESSO ===
