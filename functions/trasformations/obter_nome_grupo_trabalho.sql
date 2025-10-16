/*
Nome: obter_nome_grupo_trabalho
Descrição: Retorna o nome do grupo de trabalho dado seu número de sequência
Autor: [Sérgio Manoel]
Data: 2025-10-16
Versão: 1.0
Tabela: MAN_GRUPO_TRABALHO
Parâmetros: p_nr_sequencia (NUMBER) - Número de sequência do grupo
Retorno: VARCHAR2 - Nome do grupo de trabalho

*/
CREATE OR REPLACE FUNCTION obter_nome_grupo_trabalho(
    p_nr_sequencia IN NUMBER
) RETURN VARCHAR2 IS
    v_nome_grupo VARCHAR2(200);
BEGIN
    SELECT DS_GRUPO_TRABALHO
    INTO v_nome_grupo
    FROM MAN_GRUPO_TRABALHO
    WHERE NR_SEQUENCIA = p_nr_sequencia;
    
    RETURN v_nome_grupo;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Grupo não encontrado';
    WHEN OTHERS THEN
        RETURN 'Erro ao buscar grupo';
END obter_nome_grupo_trabalho;
/
