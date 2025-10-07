-- ============================================================================
-- TEMPLATE 1: QUERY SELECT
-- ============================================================================
/*
╔══════════════════════════════════════════════════════════════════════════╗
║ QUERY: [Nome descritivo da query]                                       ║
╠══════════════════════════════════════════════════════════════════════════╣
║ Descrição: [Explique o que a query faz]                                 ║
║ Banco: Oracle/PostgreSQL/MySQL/SQL Server                               ║
║ Versão: 1.0                                                              ║
║ Autor: Sergio Manoel                                                     ║
║ Data Criação: DD/MM/YYYY                                                 ║
║ Última Atualização: DD/MM/YYYY                                           ║
║                                                                          ║
║ Tags: #categoria #subcategoria #tipo                                     ║
║                                                                          ║
║ Dependências:                                                            ║
║ - Tabela: nome_tabela                                                    ║
║ - Views: nome_view (se aplicável)                                        ║
║ - Permissões: SELECT em schema.tabela                                    ║
╚══════════════════════════════════════════════════════════════════════════╝

PARÂMETROS:
  - :parametro1 - Descrição do parâmetro
  - :parametro2 - Descrição do parâmetro

EXEMPLO DE USO:
  -- Substituir :data_inicio por '01/01/2025'
  -- Substituir :data_fim por '31/01/2025'

RESULTADO ESPERADO:
  - Colunas: coluna1, coluna2, coluna3
  - Registros: Aproximadamente X linhas

PERFORMANCE:
  - Tempo médio: X segundos
  - Índices usados: idx_nome_campo
  - Custo estimado: X

HISTÓRICO DE ALTERAÇÕES:
  - DD/MM/YYYY - Nome - Descrição da alteração
*/

SELECT 
    t1.campo1,
    t1.campo2,
    t2.campo3,
    COUNT(*) AS total
FROM 
    schema.tabela1 t1
    INNER JOIN schema.tabela2 t2 ON t1.id = t2.id_ref
WHERE 
    t1.data_cadastro BETWEEN :data_inicio AND :data_fim
    AND t1.status = 'A'
GROUP BY 
    t1.campo1,
    t1.campo2,
    t2.campo3
HAVING 
    COUNT(*) > 10
ORDER BY 
    total DESC;

-- NOTAS ADICIONAIS:
-- 1. Considerar particionar a tabela se volume crescer
-- 2. Validar índice em data_cadastro
-- 3. Ajustar filtros conforme necessidade


-- ============================================================================
-- TEMPLATE 2: STORED PROCEDURE
-- ============================================================================
/*
╔══════════════════════════════════════════════════════════════════════════╗
║ PROCEDURE: [Nome da Procedure]                                          ║
╠══════════════════════════════════════════════════════════════════════════╣
║ Descrição: [Explique o que a procedure faz]                             ║
║ Banco: Oracle/PostgreSQL/MySQL/SQL Server                               ║
║ Versão: 1.0                                                              ║
║ Autor: Sergio Manoel                                                     ║
║ Data Criação: DD/MM/YYYY                                                 ║
║                                                                          ║
║ Tags: #procedure #automation #processo                                   ║
╚══════════════════════════════════════════════════════════════════════════╝

PARÂMETROS:
  IN:
    - p_parametro1 (VARCHAR2) - Descrição
    - p_parametro2 (NUMBER) - Descrição
  OUT:
    - p_resultado (VARCHAR2) - Mensagem de retorno
    - p_codigo (NUMBER) - Código de status (0=sucesso, >0=erro)

EXEMPLO DE USO:
  DECLARE
    v_resultado VARCHAR2(200);
    v_codigo NUMBER;
  BEGIN
    proc_nome(
      p_parametro1 => 'valor1',
      p_parametro2 => 100,
      p_resultado => v_resultado,
      p_codigo => v_codigo
    );
    DBMS_OUTPUT.PUT_LINE('Resultado: ' || v_resultado);
  END;

DEPENDÊNCIAS:
  - Tabelas: tabela1, tabela2
  - Outras Procedures: proc_auxiliar
  - Jobs: job_nome (se aplicável)

ERROS CONHECIDOS:
  - Código -20001: Descrição do erro
  - Código -20002: Descrição do erro
*/

CREATE OR REPLACE PROCEDURE proc_nome (
    p_parametro1    IN  VARCHAR2,
    p_parametro2    IN  NUMBER,
    p_resultado     OUT VARCHAR2,
    p_codigo        OUT NUMBER
)
IS
    -- Declaração de variáveis
    v_contador NUMBER := 0;
    v_data DATE := SYSDATE;
    
    -- Declaração de exceções customizadas
    e_erro_validacao EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_erro_validacao, -20001);
    
BEGIN
    -- Log de início
    DBMS_OUTPUT.PUT_LINE('Início da execução: ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    
    -- Validações
    IF p_parametro1 IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Parâmetro obrigatório não informado');
    END IF;
    
    -- Lógica principal
    SELECT COUNT(*)
    INTO v_contador
    FROM tabela1
    WHERE campo1 = p_parametro1;
    
    -- Processamento condicional
    IF v_contador > 0 THEN
        UPDATE tabela1
        SET campo2 = p_parametro2,
            data_atualizacao = SYSDATE
        WHERE campo1 = p_parametro1;
        
        p_resultado := 'Registros atualizados: ' || v_contador;
        p_codigo := 0; -- Sucesso
    ELSE
        p_resultado := 'Nenhum registro encontrado';
        p_codigo := 1; -- Aviso
    END IF;
    
    COMMIT;
    
    -- Log de fim
    DBMS_OUTPUT.PUT_LINE('Fim da execução: ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    
EXCEPTION
    WHEN e_erro_validacao THEN
        ROLLBACK;
        p_codigo := -20001;
        p_resultado := 'Erro de validação: ' || SQLERRM;
        
    WHEN OTHERS THEN
        ROLLBACK;
        p_codigo := SQLCODE;
        p_resultado := 'Erro inesperado: ' || SQLERRM;
END proc_nome;
/


-- ============================================================================
-- TEMPLATE 3: FUNCTION
-- ============================================================================
/*
╔══════════════════════════════════════════════════════════════════════════╗
║ FUNCTION: [Nome da Function]                                            ║
╠══════════════════════════════════════════════════════════════════════════╣
║ Descrição: [Explique o que a function retorna]                          ║
║ Banco: Oracle/PostgreSQL/MySQL/SQL Server                               ║
║ Versão: 1.0                                                              ║
║ Autor: Sergio Manoel                                                     ║
║ Data Criação: DD/MM/YYYY                                                 ║
║                                                                          ║
║ Tags: #function #calculo #transformacao                                  ║
╚══════════════════════════════════════════════════════════════════════════╝

PARÂMETROS:
  - p_param1 (VARCHAR2) - Descrição
  - p_param2 (NUMBER) - Descrição

RETORNO:
  - VARCHAR2 - Descrição do retorno

EXEMPLO DE USO:
  SELECT func_nome('ABC', 123) FROM DUAL;
  
  -- Em uma query
  SELECT 
    id,
    nome,
    func_nome(codigo, valor) AS resultado
  FROM tabela;

REGRAS DE NEGÓCIO:
  - Regra 1: Descrição
  - Regra 2: Descrição
*/

CREATE OR REPLACE FUNCTION func_nome (
    p_param1 IN VARCHAR2,
    p_param2 IN NUMBER
)
RETURN VARCHAR2
IS
    v_resultado VARCHAR2(100);
    v_temp NUMBER;
BEGIN
    -- Validações
    IF p_param1 IS NULL THEN
        RETURN 'ERRO: Parâmetro inválido';
    END IF;
    
    -- Lógica de processamento
    SELECT MAX(campo)
    INTO v_temp
    FROM tabela
    WHERE codigo = p_param1;
    
    -- Cálculo do resultado
    v_resultado := p_param1 || '_' || TO_CHAR(v_temp * p_param2);
    
    RETURN v_resultado;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'SEM_DADOS';
    WHEN OTHERS THEN
        RETURN 'ERRO: ' || SQLERRM;
END func_nome;
/


-- ============================================================================
-- TEMPLATE 4: SCRIPT DDL (CREATE TABLE)
-- ============================================================================
/*
╔══════════════════════════════════════════════════════════════════════════╗
║ SCRIPT DDL: Criação de Tabela                                           ║
╠══════════════════════════════════════════════════════════════════════════╣
║ Descrição: [Propósito da tabela]                                        ║
║ Schema: nome_schema                                                      ║
║ Versão: 1.0                                                              ║
║ Autor: Sergio Manoel                                                     ║
║ Data Criação: DD/MM/YYYY                                                 ║
║                                                                          ║
║ Tags: #ddl #tabela #estrutura                                            ║
╚══════════════════════════════════════════════════════════════════════════╝

PRÉ-REQUISITOS:
  - Permissão CREATE TABLE no schema
  - Tablespace disponível
  - Sequences criadas (se aplicável)

PÓS-EXECUÇÃO:
  - Criar índices
  - Definir grants
  - Popular tabela (se necessário)
*/

-- Criação da tabela
CREATE TABLE schema.nome_tabela (
    id                  NUMBER(10)      NOT NULL,
    codigo              VARCHAR2(20)    NOT NULL,
    descricao           VARCHAR2(200),
    valor               NUMBER(15,2),
    data_cadastro       DATE            DEFAULT SYSDATE,
    data_atualizacao    DATE,
    status              CHAR(1)         DEFAULT 'A',
    usuario_cadastro    VARCHAR2(50),
    
    -- Constraints
    CONSTRAINT pk_nome_tabela PRIMARY KEY (id),
    CONSTRAINT uk_nome_tabela_codigo UNIQUE (codigo),
    CONSTRAINT ck_nome_tabela_status CHECK (status IN ('A', 'I')),
    CONSTRAINT fk_nome_tabela_ref FOREIGN KEY (campo_ref) 
        REFERENCES tabela_ref(id)
)
TABLESPACE nome_tablespace;

-- Comentários
COMMENT ON TABLE schema.nome_tabela IS 'Descrição detalhada da tabela';
COMMENT ON COLUMN schema.nome_tabela.id IS 'Identificador único';
COMMENT ON COLUMN schema.nome_tabela.codigo IS 'Código de referência';
COMMENT ON COLUMN schema.nome_tabela.status IS 'Status: A=Ativo, I=Inativo';

-- Sequence para ID
CREATE SEQUENCE schema.seq_nome_tabela
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Índices
CREATE INDEX idx_nome_tabela_data ON schema.nome_tabela(data_cadastro);
CREATE INDEX idx_nome_tabela_status ON schema.nome_tabela(status);

-- Grants
GRANT SELECT ON schema.nome_tabela TO role_leitura;
GRANT SELECT, INSERT, UPDATE, DELETE ON schema.nome_tabela TO role_escrita;


-- ============================================================================
-- TEMPLATE 5: SCRIPT DE MANUTENÇÃO/ETL
-- ============================================================================
/*
╔══════════════════════════════════════════════════════════════════════════╗
║ SCRIPT: [Nome do processo]                                              ║
╠══════════════════════════════════════════════════════════════════════════╣
║ Tipo: Manutenção/ETL/Carga/Limpeza                                      ║
║ Descrição: [O que o script faz]                                         ║
║ Frequência: Diário/Semanal/Mensal/Sob demanda                           ║
║ Autor: Sergio Manoel                                                     ║
║ Data Criação: DD/MM/YYYY                                                 ║
║                                                                          ║
║ Tags: #manutencao #etl #batch                                            ║
╚══════════════════════════════════════════════════════════════════════════╝

OBJETIVO:
  Descrever o objetivo do script em detalhes

IMPACTO:
  - Baixo/Médio/Alto
  - Tabelas afetadas: lista_tabelas
  - Tempo estimado: X minutos
  - Janela de execução: Madrugada/Horário comercial

VALIDAÇÕES PRÉ-EXECUÇÃO:
  1. Verificar espaço em disco
  2. Validar backup recente
  3. Confirmar janela de manutenção

ROLLBACK:
  [Instruções de rollback se necessário]
*/

-- Ativar log
SET SERVEROUTPUT ON;
SPOOL /caminho/log_script_DDMMYYYY.log

-- Início do script
DECLARE
    v_inicio TIMESTAMP := SYSTIMESTAMP;
    v_registros_processados NUMBER := 0;
    v_registros_erro NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=================================');
    DBMS_OUTPUT.PUT_LINE('INÍCIO: ' || TO_CHAR(v_inicio, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('=================================');
    
    -- Passo 1: Backup de segurança
    EXECUTE IMMEDIATE 'CREATE TABLE tabela_backup AS SELECT * FROM tabela_origem';
    DBMS_OUTPUT.PUT_LINE('Backup criado com sucesso');
    
    -- Passo 2: Processamento principal
    FOR rec IN (SELECT * FROM tabela_origem WHERE status = 'P') LOOP
        BEGIN
            -- Lógica de processamento
            UPDATE tabela_destino
            SET campo = rec.valor
            WHERE id = rec.id;
            
            v_registros_processados := v_registros_processados + 1;
            
            -- Commit a cada 1000 registros
            IF MOD(v_registros_processados, 1000) = 0 THEN
                COMMIT;
                DBMS_OUTPUT.PUT_LINE('Processados: ' || v_registros_processados || ' registros');
            END IF;
            
        EXCEPTION
            WHEN OTHERS THEN
                v_registros_erro := v_registros_erro + 1;
                DBMS_OUTPUT.PUT_LINE('Erro no registro ID ' || rec.id || ': ' || SQLERRM);
        END;
    END LOOP;
    
    COMMIT;
    
    -- Estatísticas finais
    DBMS_OUTPUT.PUT_LINE('=================================');
    DBMS_OUTPUT.PUT_LINE('FIM: ' || TO_CHAR(SYSTIMESTAMP, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('Tempo total: ' || TO_CHAR(SYSTIMESTAMP - v_inicio));
    DBMS_OUTPUT.PUT_LINE('Registros processados: ' || v_registros_processados);
    DBMS_OUTPUT.PUT_LINE('Registros com erro: ' || v_registros_erro);
    DBMS_OUTPUT.PUT_LINE('=================================');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERRO CRÍTICO: ' || SQLERRM);
        RAISE;
END;
/

SPOOL OFF;


-- ============================================================================
-- TEMPLATE 6: VIEW
-- ============================================================================
/*
╔══════════════════════════════════════════════════════════════════════════╗
║ VIEW: [Nome da View]                                                    ║
╠══════════════════════════════════════════════════════════════════════════╣
║ Descrição: [Propósito da view]                                          ║
║ Tipo: Simples/Materializada                                             ║
║ Autor: Sergio Manoel                                                     ║
║ Data Criação: DD/MM/YYYY                                                 ║
║                                                                          ║
║ Tags: #view #consulta #agregacao                                         ║
╚══════════════════════════════════════════════════════════════════════════╝

USO RECOMENDADO:
  - Dashboards
  - Relatórios
  - Integrações

PERFORMANCE:
  - Complexidade: Baixa/Média/Alta
  - Tempo resposta: X segundos (média)
  - Sugestão: Criar índices em tabelas base
*/

CREATE OR REPLACE VIEW vw_nome_view AS
SELECT 
    t1.id,
    t1.codigo,
    t1.descricao,
    t2.categoria,
    COUNT(t3.id) AS total_itens,
    SUM(t3.valor) AS valor_total
FROM 
    tabela1 t1
    LEFT JOIN tabela2 t2 ON t1.categoria_id = t2.id
    LEFT JOIN tabela3 t3 ON t1.id = t3.ref_id
WHERE 
    t1.status = 'A'
    AND t1.data_cadastro >= ADD_MONTHS(SYSDATE, -12)
GROUP BY 
    t1.id,
    t1.codigo,
    t1.descricao,
    t2.categoria;

-- Comentário
COMMENT ON TABLE vw_nome_view IS 'View agregada para análises';

-- Grant
GRANT SELECT ON vw_nome_view TO role_leitura;
