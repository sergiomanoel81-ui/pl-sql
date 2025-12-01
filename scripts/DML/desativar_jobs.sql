-- ============================================================
-- SCRIPT: DESATIVAR JOBS ANTES DE ATUALIZAÇÃO TASY
-- Ambiente: HOMOLOGAÇÃO
-- Autor: Sérgio
-- Data: 2025-01-01
-- ============================================================

-- PASSO 1: ANOTAR VALOR ATUAL (IMPORTANTE!)
PROMPT === CAPTURANDO CONFIGURAÇÃO ATUAL ===
SELECT value AS JOB_QUEUE_PROCESSES_ATUAL 
FROM v$parameter 
WHERE name = 'job_queue_processes';

-- ANOTAR O VALOR ACIMA: _______

-- PASSO 2: DESABILITAR PROCESSAMENTO DE JOBS
ALTER SYSTEM SET JOB_QUEUE_PROCESSES = 0 SCOPE=BOTH;

-- PASSO 3: QUEBRAR TODAS AS JOBS ATIVAS
BEGIN
  FOR job_rec IN (SELECT job FROM user_jobs WHERE broken = 'N') LOOP
    DBMS_JOB.BROKEN(job_rec.job, TRUE);
  END LOOP;
  COMMIT;
END;
/

-- PASSO 4: VALIDAR DESATIVAÇÃO
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
WHERE broken = 'N';

-- RESULTADO ESPERADO:
-- JOB_QUEUE_PROCESSES = 0
-- JOBS_ATIVAS = 0

PROMPT === JOBS DESATIVADAS COM SUCESSO ===
