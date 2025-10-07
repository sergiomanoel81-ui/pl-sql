/*
╔══════════════════════════════════════════════════════════════════════════╗
║ QUERY: Usuários Ativos nos Últimos 30 Dias                              ║
╠══════════════════════════════════════════════════════════════════════════╣
║ Descrição: Lista usuários que fizeram login no último mês               ║
║ Banco: Oracle/PostgreSQL/MySQL                                          ║
║ Versão: 1.0                                                              ║
║ Autor: Sergio Manoel                                                     ║
║ Data Criação: 07/10/2025                                                 ║
║                                                                          ║
║ Tags: #analytics #usuarios #login #exemplo                               ║
╚══════════════════════════════════════════════════════════════════════════╝
*/

SELECT 
    user_id,
    username,
    email,
    last_login_date,
    TRUNC(SYSDATE - last_login_date) AS dias_sem_login
FROM 
    users
WHERE 
    last_login_date >= SYSDATE - 30
    AND status = 'ACTIVE'
ORDER BY 
    last_login_date DESC;

-- NOTAS:
-- Ajustar SYSDATE para CURRENT_DATE (PostgreSQL) ou NOW() (MySQL)
-- Pode adicionar filtro por tipo de usuário se necessário
