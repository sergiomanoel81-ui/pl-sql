-- =====================================================================================
-- SCRIPT : reconciliacao_schematic_pos_update.sql
-- OBJETIVO: Detectar e recuperar registros de metadados Schematic (telas, funcoes, CRUD,
--           eventos, regras de condicao, padroes HTML) divergentes entre PRODUCAO (TASY)
--           e REFERENCIA (TASY_VERSAO) apos uma atualizacao de versao do TASY.
-- CONTEXTO: A atualizacao deixa uma copia de referencia em TASY_VERSAO. Comparando a
--           contagem de linhas tabela a tabela achamos onde a producao ficou sem
--           registros padrao (sintoma: tela/funcao que some ou trava pos-update).
-- AUTOR   : Sergio Cerqueira
-- DATA    : 2026-07-03
-- ATENCAO : Fazer BACKUP das tabelas alvo antes de qualquer INSERT. Nao commitar antes
--           de validar as telas afetadas. Rodar em janela de baixo uso / homologacao.
-- =====================================================================================


-- =====================================================================================
-- PASSO 1: DIAGNOSTICO - Contagem comparativa (PRODUCAO x TASY_VERSAO)
-- QT_DIF = TASY - TASY_VERSAO
--   = 0  -> contagem igual (ok; mas so pega o liquido, pode esconder chave faltando)
--   > 0  -> producao tem MAIS (customizacao local -> MANTER, ou orfao -> investigar)
--   < 0  -> referencia tem MAIS -> producao esta FALTANDO padrao -> RECUPERAR (PASSO 2)
-- =====================================================================================
SELECT /*+ PARALLEL (DEFAULT) */ a.*,
       to_number(a.tasy) - to_number(a.tasy_versao) qt_dif
FROM (
  select 'FUNCAO_SCHEMATIC' ds,(select count(1) from funcao_schematic) tasy, (select count(1) from  tasy_versao.funcao_schematic) tasy_versao from dual union
  select 'OBJETO_SCHEMATIC',(select count(1) from objeto_schematic), (select count(1) from  tasy_versao.objeto_schematic) from dual union
  select 'REGRA_CONDICAO',(select count(1) from regra_condicao), (select count(1) from  tasy_versao.regra_condicao) from dual union
  select 'REGRA_CONDICAO_ITEM',(select count(1) from regra_condicao_item), (select count(1) from  tasy_versao.regra_condicao_item) from dual union
  select 'OBJ_SCHEMATIC_VISAO',(select count(1) from OBJ_SCHEMATIC_VISAO), (select count(1) from  tasy_versao.OBJ_SCHEMATIC_VISAO) from dual union
  select 'OBJ_SCHEMATIC_EVENTO',(select count(1) from obj_schematic_evento), (select count(1) from  tasy_versao.obj_schematic_evento) from dual union
  select 'OBJ_SCHEMATIC_EVENTO_ACAO',(select count(1) from obj_schematic_evento_acao), (select count(1) from  tasy_versao.obj_schematic_evento_acao) from dual union
  select 'OBJETO_SCHEMATIC_PARAM',(select count(1) from objeto_schematic_param), (select count(1) from  tasy_versao.objeto_schematic_param) from dual union
  select 'OBJETO_SCHEMATIC_PROP',(select count(1) from objeto_schematic_prop), (select count(1) from  tasy_versao.objeto_schematic_prop) from dual union
  select 'OBJETO_SCHEMATIC_ATIV',(select count(1) from objeto_schematic_ativ), (select count(1) from  tasy_versao.objeto_schematic_ativ) from dual union
  select 'OBJETO_SCHEMATIC_COND_ATIV',(select count(1) from objeto_schematic_cond_ativ), (select count(1) from  tasy_versao.objeto_schematic_cond_ativ) from dual union
  select 'OPCOES_CRUD',(select count(1) from opcoes_crud), (select count(1) from  tasy_versao.opcoes_crud) from dual union
  select 'OBJETO_SCHEMATIC_LEGENDA',(select count(1) from objeto_schematic_legenda), (select count(1) from  tasy_versao.objeto_schematic_legenda) from dual union
  select 'OBJ_SCHEMATIC_ATIV_PARAM',(select count(1) from obj_schematic_ativ_param), (select count(1) from  tasy_versao.obj_schematic_ativ_param) from dual union
  select 'XML_ATRIBUTO',(select count(1) from xml_atributo), (select count(1) from  tasy_versao.xml_atributo) from dual union
  select 'TASY_PADRAO_IMAGEM_HTML',(select count(1) from TASY_PADRAO_IMAGEM_HTML), (select count(1) from tasy_versao.TASY_PADRAO_IMAGEM_HTML) from dual union
  select 'TASY_PADRAO_COR_HTML',(select count(1) from TASY_PADRAO_COR_HTML), (select count(1) from tasy_versao.TASY_PADRAO_COR_HTML) from dual union
  select 'TASY_PADRAO_CONCEITO_HTML',(select count(1) from TASY_PADRAO_CONCEITO_HTML), (select count(1) from tasy_versao.TASY_PADRAO_CONCEITO_HTML) from dual union
  select 'PEPO_CONFIG_CHART_HTML',(select count(1) from PEPO_CONFIG_CHART_HTML), (select count(1) from tasy_versao.PEPO_CONFIG_CHART_HTML) from dual
) a
ORDER BY ds;


-- =====================================================================================
-- PASSO 2: DETALHAMENTO - Diff por tabela (registros na REFERENCIA que faltam em PRODUCAO)
-- Execute APENAS para as tabelas com divergencia identificada no PASSO 1.
-- Troque <TABELA> pelo nome da tabela. Confirme a PK real: a maioria usa NR_SEQUENCIA,
-- mas se for chave composta, adicione todas as colunas da chave no NOT EXISTS.
-- =====================================================================================
-- SELECT a.*
-- FROM tasy_versao.<TABELA> a
-- WHERE NOT EXISTS (
--     SELECT 1
--     FROM <TABELA> b
--     WHERE b.nr_sequencia = a.nr_sequencia
-- );

-- Exemplo usado na atualizacao (OBJETO_SCHEMATIC_PROP):
SELECT a.*
FROM tasy_versao.OBJETO_SCHEMATIC_PROP a
WHERE NOT EXISTS (
    SELECT 1
    FROM OBJETO_SCHEMATIC_PROP b
    WHERE b.nr_sequencia = a.nr_sequencia
);


-- =====================================================================================
-- PASSO 3: EXPORTACAO - Gerar os INSERTs a partir do resultado do PASSO 2
-- Na ferramenta (Localizar Objeto do Banco / SQL do TASY / PL-SQL Developer):
--   1. Selecionar todas as linhas do resultado
--   2. Botao direito -> Exportar -> formato INSERT
--   3. Salvar um .sql por tabela (facilita versionamento e rollback)
-- =====================================================================================


-- =====================================================================================
-- PASSO 4: APLICACAO - Reinserir em PRODUCAO respeitando a ordem de FK (pai -> filho)
-- Valide as FKs do seu ambiente. Ordem sugerida:
--   1. FUNCAO_SCHEMATIC
--   2. OBJETO_SCHEMATIC
--   3. OBJETO_SCHEMATIC_PARAM, OBJETO_SCHEMATIC_PROP, OBJETO_SCHEMATIC_LEGENDA, OBJ_SCHEMATIC_VISAO
--   4. OBJETO_SCHEMATIC_ATIV -> OBJETO_SCHEMATIC_COND_ATIV, OBJ_SCHEMATIC_ATIV_PARAM
--   5. OBJ_SCHEMATIC_EVENTO  -> OBJ_SCHEMATIC_EVENTO_ACAO
--   6. REGRA_CONDICAO        -> REGRA_CONDICAO_ITEM
--   7. OPCOES_CRUD, XML_ATRIBUTO, TASY_PADRAO_*_HTML, PEPO_CONFIG_CHART_HTML
-- CUIDADOS:
--   - QT_DIF > 0 (producao com mais) NAO e tratado aqui: pode ser custom local. Nao apagar.
--   - Sequences: conferir se o NR_SEQUENCIA reinserido nao colide com valores futuros.
--   - Apos aplicar, rodar de novo o PASSO 1 -> QT_DIF das tabelas tratadas deve convergir.
-- =====================================================================================
-- <colar aqui os INSERTs exportados no PASSO 3, na ordem acima>


-- =====================================================================================
-- PASSO 5: FINALIZACAO
-- IMPORTANTE: Validar as telas/funcoes afetadas ANTES de confirmar.
-- =====================================================================================
-- COMMIT;
-- ROLLBACK;
