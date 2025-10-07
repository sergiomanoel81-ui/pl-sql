# 📊 PL/SQL - Repositório de Queries e Scripts

> Meu repositório pessoal de queries SQL/PL-SQL organizadas, documentadas e prontas para uso.

## 🎯 Sobre

Este repositório contém uma coleção de queries, procedures, functions e scripts que utilizo no dia a dia. Cada arquivo está devidamente documentado com:
- Descrição clara do propósito
- Parâmetros e dependências
- Exemplos de uso
- Tags para facilitar busca

## 📁 Estrutura do Repositório

```
pl-sqll/
├── README.md
├── TEMPLATES.sql                    # Templates para novos arquivos
│
├── queries/                         # Queries SELECT
│   ├── analytics/                   # Queries analíticas
│   ├── reports/                     # Relatórios
│   └── monitoring/                  # Queries de monitoramento
│
├── procedures/                      # Stored Procedures
│   ├── batch/                       # Processos em lote
│   ├── integration/                 # Integrações
│   └── maintenance/                 # Manutenção
│
├── functions/                       # Functions
│   ├── calculations/                # Cálculos
│   ├── transformations/             # Transformações
│   └── validations/                 # Validações
│
├── scripts/                         # Scripts diversos
│   ├── ddl/                         # CREATE, ALTER, DROP
│   ├── dml/                         # INSERT, UPDATE, DELETE
│   ├── etl/                         # Scripts de ETL/Carga
│   └── migration/                   # Scripts de migração
│
├── views/                           # Views
│   └── materialized/                # Materialized Views
│
└── docs/                            # Documentação adicional
    ├── guia-uso.md
    └── convencoes.md
```

## 🔍 Como Usar

### Buscar Queries
Use a busca do GitHub (pressione `/` ou `Ctrl+K`) e digite:
- Nome do arquivo
- Tags (#analytics, #relatorio, #etl)
- Palavras-chave da descrição

### Copiar e Usar
1. Navegue até o arquivo desejado
2. Clique no botão `Raw` para ver o código puro
3. Copie e ajuste os parâmetros conforme necessário

## 📝 Convenções

### Nomenclatura de Arquivos
- **Queries**: `descricao_funcional.sql` (ex: `usuarios_ativos_mes.sql`)
- **Procedures**: `proc_nome_funcional.sql` (ex: `proc_carga_vendas.sql`)
- **Functions**: `func_nome_funcional.sql` (ex: `func_calcula_desconto.sql`)
- **Scripts**: `tipo_descricao.sql` (ex: `ddl_criar_tabela_clientes.sql`)

### Tags Padronizadas
Use estas tags nos comentários para facilitar buscas:

**Por Categoria:**
- `#analytics` - Análises e métricas
- `#relatorio` - Relatórios gerenciais
- `#etl` - Extração, transformação e carga
- `#manutencao` - Limpeza e otimização
- `#monitoramento` - Queries de saúde do sistema

**Por Tipo:**
- `#select` - Queries de consulta
- `#procedure` - Stored procedures
- `#function` - Functions
- `#view` - Views
- `#ddl` - Comandos de estrutura
- `#dml` - Comandos de manipulação

**Por Complexidade:**
- `#simples` - Queries básicas
- `#intermediario` - Queries com joins/agregações
- `#avancado` - Queries complexas com subqueries/CTE

## 📚 Índice Rápido

### 🔥 Mais Usadas

| Query | Descrição | Caminho |
|-------|-----------|---------|
| Usuários Ativos | Lista usuários com login recente | `queries/analytics/usuarios_ativos.sql` |
| Vendas Diárias | Relatório de vendas do dia | `queries/reports/vendas_diarias.sql` |
| Espaço em Disco | Monitora uso de tablespace | `queries/monitoring/espaco_disco.sql` |

### 📊 Analytics

- [ ] `usuarios_ativos.sql` - Usuários ativos no período
- [ ] `taxa_conversao.sql` - Análise de conversão
- [ ] `top_produtos.sql` - Produtos mais vendidos

### 📋 Relatórios

- [ ] `vendas_por_regiao.sql` - Vendas segmentadas por região
- [ ] `performance_vendedores.sql` - Performance da equipe
- [ ] `estoque_critico.sql` - Produtos com estoque baixo

### 🔧 Procedures

- [ ] `proc_carga_diaria.sql` - Carga incremental diária
- [ ] `proc_calculo_comissao.sql` - Cálculo de comissões
- [ ] `proc_backup_logs.sql` - Arquivamento de logs

### ⚡ Functions

- [ ] `func_calcula_desconto.sql` - Cálculo de desconto por regra
- [ ] `func_valida_cpf.sql` - Validação de CPF
- [ ] `func_formata_telefone.sql` - Formatação de telefone

### 🗂️ Scripts DDL

- [ ] `criar_tabela_clientes.sql` - Estrutura tabela clientes
- [ ] `criar_indices_performance.sql` - Índices para otimização
- [ ] `alterar_estrutura_vendas.sql` - Alterações em vendas

## 🎓 Recursos

### Templates Disponíveis
Copie e use os templates em `TEMPLATES.sql`:
1. Template de Query SELECT
2. Template de Stored Procedure
3. Template de Function
4. Template de DDL (CREATE TABLE)
5. Template de Script de Manutenção/ETL
6. Template de View

### Documentação Externa
- [Documentação Oracle PL/SQL](https://docs.oracle.com/en/database/oracle/oracle-database/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [SQL Server Documentation](https://learn.microsoft.com/en-us/sql/)

## 📊 Estatísticas

- **Total de Queries**: X arquivos
- **Total de Procedures**: X arquivos
- **Total de Functions**: X arquivos
- **Última atualização**: Outubro 2025

## 🤝 Como Contribuir

Este é um repositório pessoal, mas sugestões são bem-vindas:
1. Abra uma Issue com sua sugestão
2. Descreva o problema ou melhoria
3. Se possível, inclua exemplos

## 📋 Lista de Tarefas

- [x] Criar estrutura inicial do repositório
- [x] Adicionar templates
- [ ] Documentar queries existentes
- [ ] Criar guia de boas práticas
- [ ] Adicionar exemplos de uso
- [ ] Criar scripts de automação

## 📫 Contato

**Sergio Manoel**
- GitHub: [@sergiomanoel81-ui](https://github.com/sergiomanoel81-ui)

---

⭐ Se este repositório foi útil para você, considere dar uma estrela!

*Última atualização: 07 de Outubro de 2025*
