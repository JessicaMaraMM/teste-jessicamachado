-- TESTE 3: QUERY ANALÍTICA 1 - CRESCIMENTO DE DESPESAS
-- Autora: Jéssica Mara de Morais Machado
-- SGBD: PostgreSQL 16.11
-- Objetivo: Top 5 operadoras com maior crescimento percentual entre primeiro e último trimestre
-- Query principal
WITH periodo_analise AS (
    -- Define o período analisado (primeiro e último trimestre global)
    SELECT
        MIN(ano * 10 + trimestre) AS periodo_inicial,
        MAX(ano * 10 + trimestre) AS periodo_final
    FROM
        despesas
    WHERE
        flag_valor_suspeito = FALSE
        AND flag_duplicado = FALSE
),
WITH periodo_analise AS (
    -- Define o período analisado (primeiro e último trimestre global)
    SELECT
        MIN(ano * 10 + trimestre) AS periodo_inicial,
        MAX(ano * 10 + trimestre) AS periodo_final
    FROM
        despesas
    WHERE
        flag_valor_suspeito = FALSE
        AND flag_duplicado = FALSE
),
despesas_primeiro_trimestre AS (
    -- Despesas de cada operadora no PRIMEIRO trimestre que ela tem dados
    SELECT
        d.registro_ans,
        o.razao_social,
        MIN(d.ano * 10 + d.trimestre) AS periodo,
        SUM(d.valor_despesas) AS valor_inicial
    FROM
        despesas d
        JOIN operadoras o ON d.registro_ans = o.registro_ans
    WHERE
        d.flag_valor_suspeito = FALSE
        AND d.flag_duplicado = FALSE
    GROUP BY
        d.registro_ans,
        o.razao_social
),
SELECT
    d.registro_ans,
    o.razao_social,
    MIN(d.ano * 10 + d.trimestre) AS periodo,
    SUM(d.valor_despesas) AS valor_inicial
FROM
    despesas d
    JOIN operadoras o ON d.registro_ans = o.registro_ans
WHERE
    d.flag_valor_suspeito = FALSE
    AND d.flag_duplicado = FALSE
GROUP BY
    d.registro_ans,
    o.razao_social
),
despesas_ultimo_trimestre AS (
    -- Despesas de cada operadora no ÚLTIMO trimestre que ela tem dados
    SELECT
        d.registro_ans,
        MAX(d.ano * 10 + d.trimestre) AS periodo,
        SUM(d.valor_despesas) AS valor_final
    FROM
        despesas d
    WHERE
        d.flag_valor_suspeito = FALSE
        AND d.flag_duplicado = FALSE
    GROUP BY
        d.registro_ans
),
SELECT
    d.registro_ans,
    MAX(d.ano * 10 + d.trimestre) AS periodo,
    SUM(d.valor_despesas) AS valor_final
FROM
    despesas d
WHERE
    d.flag_valor_suspeito = FALSE
    AND d.flag_duplicado = FALSE
GROUP BY
    d.registro_ans
),
crescimento AS (
    -- Calcula crescimento percentual
    SELECT
        pi.registro_ans,
        pi.razao_social,
        pi.periodo AS periodo_inicial,
        pf.periodo AS periodo_final,
        pi.valor_inicial,
        pf.valor_final,
        ROUND(
            (
                (pf.valor_final - pi.valor_inicial) / NULLIF(pi.valor_inicial, 0)
            ) * 100,
            2
        ) AS crescimento_percentual,
        pf.periodo - pi.periodo AS trimestres_analisados
    FROM
        despesas_primeiro_trimestre pi
        JOIN despesas_ultimo_trimestre pf ON pi.registro_ans = pf.registro_ans
    WHERE
        pi.valor_inicial > 0 -- Evita divisão por zero e valores negativos
        AND pf.periodo > pi.periodo -- Garante que há evolução temporal
)
SELECT
    pi.registro_ans,
    pi.razao_social,
    pi.periodo AS periodo_inicial,
    pf.periodo AS periodo_final,
    pi.valor_inicial,
    pf.valor_final,
    ROUND(
        (
            (pf.valor_final - pi.valor_inicial) / NULLIF(pi.valor_inicial, 0)
        ) * 100,
        2
    ) AS crescimento_percentual,
    pf.periodo - pi.periodo AS trimestres_analisados
FROM
    despesas_primeiro_trimestre pi
    JOIN despesas_ultimo_trimestre pf ON pi.registro_ans = pf.registro_ans
WHERE
    pi.valor_inicial > 0 -- Evita divisão por zero e valores negativos
    AND pf.periodo > pi.periodo -- Garante que há evolução temporal
)
SELECT
    registro_ans,
    razao_social,
    periodo_inicial / 10 AS ano_inicial,
    periodo_inicial % 10 AS trimestre_inicial,
    periodo_final / 10 AS ano_final,
    periodo_final % 10 AS trimestre_final,
    trimestres_analisados AS qtd_trimestres_entre,
    TO_CHAR(valor_inicial, 'FM999,999,999,990.00') AS valor_inicial_fmt,
    TO_CHAR(valor_final, 'FM999,999,999,990.00') AS valor_final_fmt,
    crescimento_percentual || '%' AS crescimento
FROM
    crescimento
ORDER BY
    crescimento_percentual DESC
LIMIT
    5;

SELECT
    registro_ans,
    razao_social,
    periodo_inicial / 10 AS ano_inicial,
    periodo_inicial % 10 AS trimestre_inicial,
    periodo_final / 10 AS ano_final,
    periodo_final % 10 AS trimestre_final,
    trimestres_analisados AS qtd_trimestres_entre,
    TO_CHAR(valor_inicial, 'FM999,999,999,990.00') AS valor_inicial_fmt,
    TO_CHAR(valor_final, 'FM999,999,999,990.00') AS valor_final_fmt,
    crescimento_percentual || '%' AS crescimento
FROM
    crescimento
ORDER BY
    crescimento_percentual DESC
LIMIT
    5;

-- Query auxiliar: Operadoras excluídas e motivo
SELECT
    'Análise de Exclusões' AS relatorio;

WITH operadoras_com_dados AS (
    SELECT
        DISTINCT registro_ans
    FROM
        despesas
    WHERE
        flag_valor_suspeito = FALSE
        AND flag_duplicado = FALSE
),
operadoras_apenas_um_trimestre AS (
    SELECT
        registro_ans
    FROM
        despesas
    WHERE
        flag_valor_suspeito = FALSE
        AND flag_duplicado = FALSE
    GROUP BY
        registro_ans
    HAVING
        COUNT(DISTINCT (ano * 10 + trimestre)) = 1
)
SELECT
    'Total de operadoras no banco' AS categoria,
    COUNT(*) AS quantidade
FROM
    operadoras
UNION
ALL
SELECT
    'Operadoras com despesas válidas',
    COUNT(*)
FROM
    operadoras_com_dados
UNION
ALL
SELECT
    'Operadoras com apenas 1 trimestre (excluídas)',
    COUNT(*)
FROM
    operadoras_apenas_um_trimestre
UNION
ALL
SELECT
    'Operadoras analisadas (≥2 trimestres)',
    COUNT(*) - (
        SELECT
            COUNT(*)
        FROM
            operadoras_apenas_um_trimestre
    )
FROM
    operadoras_com_dados;