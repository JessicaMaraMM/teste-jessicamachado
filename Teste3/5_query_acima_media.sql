-- TESTE 3: QUERY ANALÍTICA 3 - OPERADORAS ACIMA DA MÉDIA
-- Autora: Jéssica Mara de Morais Machado
-- SGBD: PostgreSQL 16.11
-- Objetivo: Listar operadoras com despesas acima da média nacional e por UF
-- Query 1: Operadoras acima da média nacional
WITH despesas_validas AS (
    SELECT
        d.registro_ans,
        o.razao_social,
        o.uf,
        SUM(d.valor_despesas) AS total_despesas
    FROM
        despesas d
        JOIN operadoras o ON d.registro_ans = o.registro_ans
    WHERE
        d.flag_valor_suspeito = FALSE
        AND d.flag_duplicado = FALSE
    GROUP BY
        d.registro_ans,
        o.razao_social,
        o.uf
),
media_nacional AS (
    SELECT
        AVG(total_despesas) AS media_nacional
    FROM
        despesas_validas
)
SELECT
    dv.registro_ans,
    dv.razao_social,
    dv.uf,
    TO_CHAR(dv.total_despesas, 'FM999,999,999,990.00') AS total_despesas_fmt,
    TO_CHAR(mn.media_nacional, 'FM999,999,999,990.00') AS media_nacional_fmt,
    ROUND((dv.total_despesas / mn.media_nacional) * 100, 2) AS perc_acima_media
FROM
    despesas_validas dv
    CROSS JOIN media_nacional mn
WHERE
    dv.total_despesas > mn.media_nacional
ORDER BY
    dv.total_despesas DESC;

-- Query 2: Operadoras acima da média do seu estado (UF)
WITH despesas_validas AS (
    SELECT
        d.registro_ans,
        o.razao_social,
        o.uf,
        SUM(d.valor_despesas) AS total_despesas
    FROM
        despesas d
        JOIN operadoras o ON d.registro_ans = o.registro_ans
    WHERE
        d.flag_valor_suspeito = FALSE
        AND d.flag_duplicado = FALSE
    GROUP BY
        d.registro_ans,
        o.razao_social,
        o.uf
),
media_uf AS (
    SELECT
        uf,
        AVG(total_despesas) AS media_uf
    FROM
        despesas_validas
    GROUP BY
        uf
)
SELECT
    dv.registro_ans,
    dv.razao_social,
    dv.uf,
    TO_CHAR(dv.total_despesas, 'FM999,999,999,990.00') AS total_despesas_fmt,
    TO_CHAR(mu.media_uf, 'FM999,999,999,990.00') AS media_uf_fmt,
    ROUND((dv.total_despesas / mu.media_uf) * 100, 2) AS perc_acima_media_uf
FROM
    despesas_validas dv
    JOIN media_uf mu ON dv.uf = mu.uf
WHERE
    dv.total_despesas > mu.media_uf
ORDER BY
    dv.uf,
    dv.total_despesas DESC;

-- Query 3: Ranking nacional das operadoras
SELECT
    o.razao_social,
    o.uf,
    SUM(d.valor_despesas) AS total_despesas,
    RANK() OVER (
        ORDER BY
            SUM(d.valor_despesas) DESC
    ) AS ranking_nacional
FROM
    despesas d
    JOIN operadoras o ON d.registro_ans = o.registro_ans
WHERE
    d.flag_valor_suspeito = FALSE
    AND d.flag_duplicado = FALSE
GROUP BY
    o.razao_social,
    o.uf
ORDER BY
    ranking_nacional ASC;