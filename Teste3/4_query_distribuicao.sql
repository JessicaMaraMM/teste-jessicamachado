-- TESTE 3: QUERY ANALÍTICA 2 - DISTRIBUIÇÃO GEOGRÁFICA DE DESPESAS
-- Autora: Jéssica Mara de Morais Machado
-- SGBD: PostgreSQL 16.11
-- Objetivo: Analisar distribuição de despesas por estado (UF)

-- Query principal: Distribuição por UF
WITH despesas_por_uf AS (
    -- Agrupa despesas válidas por UF da operadora
    SELECT 
        o.uf,
        COUNT(DISTINCT d.registro_ans) AS qtd_operadoras,
        COUNT(*) AS qtd_registros,
        SUM(d.valor_despesas) AS total_despesas,
        AVG(d.valor_despesas) AS media_por_registro
    FROM despesas d
    JOIN operadoras o ON d.registro_ans = o.registro_ans
    WHERE d.flag_valor_suspeito = FALSE
        AND d.flag_duplicado = FALSE
        AND o.uf IS NOT NULL
    GROUP BY o.uf
),
totais AS (
    -- Calcula totais nacionais para percentuais
    SELECT 
        SUM(total_despesas) AS total_nacional,
        SUM(qtd_operadoras) AS total_operadoras
    FROM despesas_por_uf
)
SELECT 
    d.uf AS estado,
    d.qtd_operadoras,
    ROUND((d.qtd_operadoras * 100.0) / t.total_operadoras, 2) AS perc_operadoras,
    TO_CHAR(d.total_despesas, 'FM999,999,999,990.00') AS total_despesas_fmt,
    ROUND((d.total_despesas * 100.0) / t.total_nacional, 2) AS perc_total_nacional,
    TO_CHAR(d.total_despesas / NULLIF(d.qtd_operadoras, 0), 'FM999,999,999,990.00') AS media_por_operadora,
    d.qtd_registros AS qtd_transacoes
FROM despesas_por_uf d
CROSS JOIN totais t
ORDER BY d.total_despesas DESC;

-- Query auxiliar: Top 5 estados e participação acumulada
SELECT 
    'Top 5 Estados (Princípio de Pareto)' AS analise;

WITH despesas_por_uf AS (
    SELECT 
        o.uf,
        SUM(d.valor_despesas) AS total_despesas
    FROM despesas d
    JOIN operadoras o ON d.registro_ans = o.registro_ans
    WHERE d.flag_valor_suspeito = FALSE
        AND d.flag_duplicado = FALSE
        AND o.uf IS NOT NULL
    GROUP BY o.uf
),
totais AS (
    SELECT SUM(total_despesas) AS total_nacional
    FROM despesas_por_uf
),
ranked AS (
    SELECT 
        d.uf,
        d.total_despesas,
        SUM(d.total_despesas) OVER (ORDER BY d.total_despesas DESC) AS acumulado
    FROM despesas_por_uf d
)
SELECT 
    r.uf AS estado,
    TO_CHAR(r.total_despesas, 'FM999,999,999,990.00') AS total_despesas,
    ROUND((r.total_despesas * 100.0) / t.total_nacional, 2) AS perc_individual,
    ROUND((r.acumulado * 100.0) / t.total_nacional, 2) AS perc_acumulado
FROM ranked r
CROSS JOIN totais t
ORDER BY r.total_despesas DESC
LIMIT 5;

-- Query auxiliar: Estados sem dados válidos
SELECT 
    'Estados com Poucos Dados Válidos' AS alerta;

SELECT 
    o.uf AS estado,
    COUNT(DISTINCT o.registro_ans) AS qtd_operadoras_cadastradas,
    COUNT(DISTINCT d.registro_ans) AS qtd_com_despesas_validas,
    COUNT(DISTINCT o.registro_ans) - COUNT(DISTINCT d.registro_ans) AS qtd_sem_dados_validos
FROM operadoras o
LEFT JOIN despesas d ON o.registro_ans = d.registro_ans
    AND d.flag_valor_suspeito = FALSE
    AND d.flag_duplicado = FALSE
WHERE o.uf IS NOT NULL
GROUP BY o.uf
HAVING COUNT(DISTINCT d.registro_ans) < COUNT(DISTINCT o.registro_ans) * 0.1  -- Menos de 10% com dados
ORDER BY qtd_sem_dados_validos DESC;
