/*
==================================================================================
Nome: minutos_ate_18
==================================================================================
Descrição: 
  Calcula quantos minutos faltam desde uma data/hora inicial até as 18:00 
  do mesmo dia.

Parâmetros:
  p_data_inicial (DATE) - Data/hora inicial para o cálculo

Retorno:
  NUMBER - Quantidade de minutos até as 18:00
           Retorna 0 se a hora inicial já passou das 18:00
           Retorna NULL em caso de erro

Autor: Sérgio Manoel
Data Criação: 2025-10-16
Versão: 1.1

Exemplos:
  -- Se são 14:30, retorna 210 minutos (3h30min até 18:00)
  SELECT minutos_ate_18(TO_DATE('16/10/2025 14:30', 'DD/MM/YYYY HH24:MI')) FROM DUAL;
  
  -- Se são 19:00, retorna 0 (já passou das 18:00)
  SELECT minutos_ate_18(TO_DATE('16/10/2025 19:00', 'DD/MM/YYYY HH24:MI')) FROM DUAL;

Uso:
  Utilizada para calcular tempo restante de atividades que devem 
  encerrar às 18:00 do dia.

Changelog:
  v1.1 (2025-10-16) - Melhorado tratamento de erros e documentação
  v1.0 (2025-01-XX) - Versão inicial

==================================================================================
*/
CREATE OR REPLACE FUNCTION minutos_ate_18 (
    p_data_inicial IN DATE
) RETURN NUMBER
IS
    v_data_final   DATE;
    v_minutos      NUMBER;
BEGIN
    -- Valida se a data foi informada
    IF p_data_inicial IS NULL THEN
        RETURN NULL;
    END IF;
    
    -- Define a data final como o mesmo dia da data inicial às 18:00
    v_data_final := TRUNC(p_data_inicial) + INTERVAL '18' HOUR;
    
    -- Calcula a diferença em minutos
    v_minutos := ROUND((v_data_final - p_data_inicial) * 24 * 60);
    
    -- Se o resultado for negativo (data inicial após 18:00), retorna 0
    RETURN GREATEST(v_minutos, 0);
    
EXCEPTION
    WHEN OTHERS THEN
        -- Log do erro (opcional)
        -- DBMS_OUTPUT.PUT_LINE('Erro em minutos_ate_18: ' || SQLERRM);
        RETURN NULL;
END minutos_ate_18;
/
