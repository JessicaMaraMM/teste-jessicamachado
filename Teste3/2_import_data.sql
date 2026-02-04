-- TESTE 3: IMPORTAÇÃO DE DADOS
-- Autora: Jéssica Mara de Morais Machado
-- SGBD: PostgreSQL 16.11
-- Objetivo: Importar dados dos CSVs com tratamento de inconsistências
-- Abordagem: ETL em 5 etapas (staging → carga → validação/conversão → pós-processamento → relatório)
-- [OPCIONAL] LIMPEZA PARA REEXECUÇÃO
-- Descomente as linhas abaixo se precisar rodar o script múltiplas vezes
/*
 TRUNCATE TABLE despesas, agregados, operadoras
 RESTART IDENTITY CASCADE;
 
 DROP TABLE IF EXISTS stg_erros, stg_agregados, stg_despesas, stg_operadoras CASCADE;
 */
/*
 TRUNCATE TABLE despesas, agregados, operadoras
 RESTART IDENTITY CASCADE;
 
 DROP TABLE IF EXISTS stg_erros, stg_agregados, stg_despesas, stg_operadoras CASCADE;
 */
-- Etapa 1: Criação de tabelas temporárias (staging)
DROP TABLE IF EXISTS stg_operadoras CASCADE;

CREATE TABLE stg_operadoras (
    registro_operadora TEXT,
    cnpj TEXT,
    razao_social TEXT,
    nome_fantasia TEXT,
    modalidade TEXT,
    logradouro TEXT,
    numero TEXT,
    complemento TEXT,
    bairro TEXT,
    cidade TEXT,
    uf TEXT,
    cep TEXT,
    ddd TEXT,
    telefone TEXT,
    fax TEXT,
    endereco_eletronico TEXT,
    representante TEXT,
    cargo_representante TEXT,
    regiao_de_comercializacao TEXT,
    data_registro_ans TEXT
);

DROP TABLE IF EXISTS stg_despesas CASCADE;

CREATE TABLE stg_despesas (
    reg_ans TEXT,
    cnpj TEXT,
    razaosocial TEXT,
    ano TEXT,
    trimestre TEXT,
    valordespesas TEXT,
    flagvalorsuspeito TEXT,
    flagduplicado TEXT
);

DROP TABLE IF EXISTS stg_agregados CASCADE;

CREATE TABLE stg_agregados (
    razao_social TEXT,
    uf TEXT,
    total_despesas TEXT,
    media_despesas TEXT,
    desvio_padrao TEXT,
    qtd_registros TEXT
);

DROP TABLE IF EXISTS stg_erros CASCADE;

CREATE TABLE stg_erros (
    arquivo_origem TEXT NOT NULL,
    linha_original TEXT NOT NULL,
    linha_hash TEXT NOT NULL,
    motivo_rejeicao TEXT NOT NULL,
    data_rejeicao TIMESTAMP DEFAULT NOW(),
    CONSTRAINT uq_erros UNIQUE (arquivo_origem, linha_hash, motivo_rejeicao)
);

-- Etapa 2: Importação dos dados dos arquivos CSV para as tabelas temporárias
COPY stg_operadoras
FROM
    'C:\Users\Public\Teste3\data\operadoras.csv' WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER ';',
        QUOTE '"',
        ENCODING 'UTF8'
    );

COPY stg_operadoras
FROM
    'C:\Users\Public\Teste3\data\operadoras.csv' WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER ';',
        QUOTE '"',
        ENCODING 'UTF8'
    );

COPY stg_despesas
FROM
    'C:\Users\Public\Teste3\data\consolidado_despesas.csv' WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER ';',
        QUOTE '"',
        ENCODING 'UTF8'
    );

COPY stg_despesas
FROM
    'C:\Users\Public\Teste3\data\consolidado_despesas.csv' WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER ';',
        QUOTE '"',
        ENCODING 'UTF8'
    );

COPY stg_agregados
FROM
    'C:\Users\Public\Teste3\data\despesas_agregadas.csv' WITH (
        FORMAT csv,
        HEADER true,
        COPY stg_agregados
        FROM
            'C:\Users\Public\Teste3\data\despesas_agregadas.csv' WITH (
                FORMAT csv,
                HEADER true,
                DELIMITER ',',
                QUOTE '"',
                ENCODING 'UTF8'
            );

DELIMITER ',',
QUOTE '"',
ENCODING 'UTF8'
);

SELECT
    'STAGING' AS etapa,
    'stg_operadoras' AS tabela,
    COUNT(*) AS total
FROM
    stg_operadoras
UNION
ALL
SELECT
    'STAGING',
    'stg_despesas',
    COUNT(*)
FROM
    stg_despesas
UNION
ALL
SELECT
    'STAGING',
    'stg_agregados',
    COUNT(*)
FROM
    stg_agregados;

-- Etapa 3: Validação e conversão de dados
-- OPERADORAS: Normalização de CNPJ e remoção de registros inválidos
WITH base AS (
    SELECT
        NULLIF(TRIM(registro_operadora), '') AS reg_ans_txt,
        NULLIF(TRIM(cnpj), '') AS cnpj_txt,
        NULLIF(TRIM(razao_social), '') AS razao_social_txt,
        NULLIF(TRIM(modalidade), '') AS modalidade_txt,
        NULLIF(UPPER(TRIM(uf)), '') AS uf_txt,
        registro_operadora || '|' || cnpj || '|' || razao_social || '|' || modalidade || '|' || uf AS linha_original
    FROM
        stg_operadoras
),
convertidas AS (
    SELECT
        reg_ans_txt :: INTEGER AS reg_ans,
        cnpj_txt AS cnpj,
        razao_social_txt AS razao_social,
        modalidade_txt AS modalidade,
        uf_txt AS uf,
        linha_original
    FROM
        base
    WHERE
        reg_ans_txt ~ '^\d+$'
        AND cnpj_txt IS NOT NULL
        AND razao_social_txt IS NOT NULL
        AND LENGTH(uf_txt) = 2
)
INSERT INTO
    operadoras (registro_ans, cnpj, razao_social, modalidade, uf)
SELECT
    reg_ans,
    cnpj,
    razao_social,
    modalidade,
    uf
FROM
    convertidas;

-- Registra operadoras rejeitadas
WITH base AS (
    SELECT
        NULLIF(TRIM(registro_operadora), '') AS reg_ans_txt,
        NULLIF(TRIM(cnpj), '') AS cnpj_txt,
        NULLIF(TRIM(razao_social), '') AS razao_social_txt,
        NULLIF(UPPER(TRIM(uf)), '') AS uf_txt,
        registro_operadora || '|' || cnpj || '|' || razao_social || '|' || modalidade || '|' || uf AS linha_original
    FROM
        stg_operadoras
)
INSERT INTO
    stg_erros (
        arquivo_origem,
        linha_original,
        linha_hash,
        motivo_rejeicao
    )
SELECT
    'operadoras',
    linha_original,
    MD5(linha_original),
    CASE
        WHEN reg_ans_txt IS NULL
        OR reg_ans_txt !~ '^\d+$' THEN 'reg_ans inválido ou vazio'
        WHEN cnpj_txt IS NULL THEN 'CNPJ vazio'
        WHEN razao_social_txt IS NULL THEN 'Razão social vazia'
        WHEN LENGTH(uf_txt) != 2 THEN 'UF inválida (deve ter 2 caracteres)'
        ELSE 'erro desconhecido'
    END
FROM
    base
WHERE
    NOT (
        reg_ans_txt ~ '^\d+$'
        AND cnpj_txt IS NOT NULL
        AND razao_social_txt IS NOT NULL
        AND LENGTH(uf_txt) = 2
    ) ON CONFLICT (arquivo_origem, linha_hash, motivo_rejeicao) DO NOTHING;

-- DESPESAS: Conversão de valor_despesas para NUMERIC e remoção de registros inválidos
WITH base AS (
    SELECT
        NULLIF(TRIM(reg_ans), '') AS reg_ans_txt,
        NULLIF(TRIM(ano), '') AS ano_txt,
        NULLIF(TRIM(REPLACE(trimestre, 'T', '')), '') AS tri_txt,
        NULLIF(TRIM(valordespesas), '') AS valor_original,
        reg_ans || '|' || ano || '|' || trimestre || '|' || valordespesas AS linha_original
    FROM
        stg_despesas
),
normalizado AS (
    SELECT
        reg_ans_txt,
        ano_txt,
        tri_txt,
        valor_original,
        REGEXP_REPLACE(valor_original, '[^0-9,.-]', '', 'g') AS valor_limpo,
        linha_original
    FROM
        base
),
preparado AS (
    SELECT
        reg_ans_txt,
        ano_txt,
        tri_txt,
        CASE
            WHEN valor_limpo LIKE '%,%' THEN TRANSLATE(REPLACE(valor_limpo, '.', ''), ',', '.')
            ELSE valor_limpo
        END AS valor_normalizado,
        linha_original
    FROM
        normalizado
),
convertidas AS (
    SELECT
        reg_ans_txt :: INTEGER AS reg_ans,
        ano_txt :: INTEGER AS ano,
        tri_txt :: INTEGER AS trimestre,
        valor_normalizado :: NUMERIC(15, 2) AS valor_despesas,
        CASE
            WHEN valor_normalizado :: NUMERIC <= 0 THEN TRUE
            ELSE FALSE
        END AS flag_valor_suspeito,
        linha_original
    FROM
        preparado
    WHERE
        reg_ans_txt ~ '^\d+$'
        AND ano_txt ~ '^\d{4}$'
        AND ano_txt :: INTEGER BETWEEN 2000
        AND 2100
        AND tri_txt ~ '^[1-4]$'
        AND valor_normalizado ~ '^-?\d+(\.\d{1,2})?$'
)
INSERT INTO
    despesas (
        registro_ans,
        ano,
        trimestre,
        valor_despesas,
        flag_valor_suspeito,
        flag_sem_cadastro
    )
SELECT
    reg_ans,
    ano,
    trimestre,
    valor_despesas,
    flag_valor_suspeito,
    FALSE
FROM
    convertidas;

-- Registra despesas rejeitadas
WITH base AS (
    SELECT
        NULLIF(TRIM(reg_ans), '') AS reg_ans_txt,
        NULLIF(TRIM(ano), '') AS ano_txt,
        NULLIF(TRIM(REPLACE(trimestre, 'T', '')), '') AS tri_txt,
        NULLIF(TRIM(valordespesas), '') AS valor_original,
        reg_ans || '|' || ano || '|' || trimestre || '|' || valordespesas AS linha_original
    FROM
        stg_despesas
),
normalizado AS (
    SELECT
        reg_ans_txt,
        ano_txt,
        tri_txt,
        REGEXP_REPLACE(valor_original, '[^0-9,.-]', '', 'g') AS valor_limpo,
        linha_original
    FROM
        base
),
preparado AS (
    SELECT
        reg_ans_txt,
        ano_txt,
        tri_txt,
        CASE
            WHEN valor_limpo LIKE '%,%' THEN TRANSLATE(REPLACE(valor_limpo, '.', ''), ',', '.')
            ELSE valor_limpo
        END AS valor_normalizado,
        linha_original
    FROM
        normalizado
)
INSERT INTO
    stg_erros (
        arquivo_origem,
        linha_original,
        linha_hash,
        motivo_rejeicao
    )
SELECT
    'despesas',
    linha_original,
    MD5(linha_original),
    CASE
        WHEN reg_ans_txt IS NULL
        OR reg_ans_txt !~ '^\d+$' THEN 'reg_ans inválido'
        WHEN ano_txt IS NULL
        OR ano_txt !~ '^\d{4}$' THEN 'ano inválido (formato não é AAAA)'
        WHEN ano_txt :: INTEGER NOT BETWEEN 2000
        AND 2100 THEN 'ano fora do intervalo aceitável'
        WHEN tri_txt IS NULL
        OR tri_txt !~ '^[1-4]$' THEN 'trimestre inválido (deve ser 1-4)'
        WHEN valor_normalizado IS NULL
        OR valor_normalizado !~ '^-?\d+(\.\d{1,2})?$' THEN 'valor não numérico ou mais de 2 casas decimais'
        ELSE 'erro desconhecido'
    END
FROM
    preparado
WHERE
    NOT (
        reg_ans_txt ~ '^\d+$'
        AND ano_txt ~ '^\d{4}$'
        AND ano_txt :: INTEGER BETWEEN 2000
        AND 2100
        AND tri_txt ~ '^[1-4]$'
        AND valor_normalizado ~ '^-?\d+(\.\d{1,2})?$'
    ) ON CONFLICT (arquivo_origem, linha_hash, motivo_rejeicao) DO NOTHING;

-- AGREGADOS: Conversão de campos numéricos e remoção de registros inválidos
-- Primeiro, busca o reg_ans a partir da razao_social
-- Normaliza caracteres especiais do CSV para fazer JOIN correto (problema de encoding UTF-8)
WITH base AS (
    SELECT
        o.registro_ans AS reg_ans,
        NULLIF(UPPER(TRIM(a.uf)), '') AS uf_txt,
        NULLIF(TRIM(a.total_despesas), '') AS total_original,
        NULLIF(TRIM(a.media_despesas), '') AS media_original,
        NULLIF(TRIM(a.desvio_padrao), '') AS desvio_original,
        NULLIF(TRIM(a.qtd_registros), '') AS qtd_txt,
        a.razao_social || '|' || a.uf || '|' || a.total_despesas AS linha_original
    FROM
        stg_agregados a
        LEFT JOIN operadoras o ON -- Normaliza texto removendo caracteres problemáticos do CSV
        TRANSLATE(
            UPPER(TRIM(a.razao_social)),
            'ÃÃšÃÃƒÃ‰Ã',
            'AAUAAE'
        ) = UPPER(o.razao_social)
        AND UPPER(TRIM(a.uf)) = o.uf
),
normalizado AS (
    SELECT
        reg_ans,
        uf_txt,
        REGEXP_REPLACE(total_original, '[^0-9,.-]', '', 'g') AS total_limpo,
        REGEXP_REPLACE(media_original, '[^0-9,.-]', '', 'g') AS media_limpo,
        REGEXP_REPLACE(desvio_original, '[^0-9,.-]', '', 'g') AS desvio_limpo,
        qtd_txt,
        linha_original
    FROM
        base
),
preparado AS (
    SELECT
        reg_ans,
        uf_txt,
        CASE
            WHEN total_limpo LIKE '%,%' THEN TRANSLATE(REPLACE(total_limpo, '.', ''), ',', '.')
            ELSE total_limpo
        END AS total_norm,
        CASE
            WHEN media_limpo LIKE '%,%' THEN TRANSLATE(REPLACE(media_limpo, '.', ''), ',', '.')
            ELSE media_limpo
        END AS media_norm,
        CASE
            WHEN desvio_limpo LIKE '%,%' THEN TRANSLATE(REPLACE(desvio_limpo, '.', ''), ',', '.')
            ELSE desvio_limpo
        END AS desvio_norm,
        qtd_txt,
        linha_original
    FROM
        normalizado
),
convertidas AS (
    SELECT
        reg_ans,
        uf_txt AS uf,
        ROUND(total_norm :: NUMERIC, 2) AS total_despesas,
        ROUND(media_norm :: NUMERIC, 2) AS media_despesas,
        ROUND(NULLIF(desvio_norm, '') :: NUMERIC, 2) AS desvio_padrao,
        qtd_txt :: INTEGER AS qtd_registros,
        linha_original
    FROM
        preparado
    WHERE
        reg_ans IS NOT NULL
        AND LENGTH(uf_txt) = 2
        AND total_norm ~ '^-?\d+(\.\d+)?$'
        AND media_norm ~ '^-?\d+(\.\d+)?$'
        AND qtd_txt ~ '^\d+$'
)
INSERT INTO
    agregados (
        registro_ans,
        uf,
        total_despesas,
        media_despesas,
        desvio_padrao,
        qtd_registros
    )
SELECT
    reg_ans,
    uf,
    total_despesas,
    media_despesas,
    desvio_padrao,
    qtd_registros
FROM
    convertidas ON CONFLICT (registro_ans, uf) DO
UPDATE
SET
    total_despesas = EXCLUDED.total_despesas,
    media_despesas = EXCLUDED.media_despesas,
    desvio_padrao = EXCLUDED.desvio_padrao,
    qtd_registros = EXCLUDED.qtd_registros;

-- Registra agregados rejeitados
WITH base AS (
    SELECT
        o.registro_ans AS reg_ans,
        NULLIF(UPPER(TRIM(a.uf)), '') AS uf_txt,
        NULLIF(TRIM(a.total_despesas), '') AS total_original,
        NULLIF(TRIM(a.qtd_registros), '') AS qtd_txt,
        a.razao_social || '|' || a.uf || '|' || a.total_despesas AS linha_original
    FROM
        stg_agregados a
        LEFT JOIN operadoras o ON TRANSLATE(
            UPPER(TRIM(a.razao_social)),
            'ÃÃšÃÃƒÃ‰Ã',
            'AAUAAE'
        ) = UPPER(o.razao_social)
        AND UPPER(TRIM(a.uf)) = o.uf
),
normalizado AS (
    SELECT
        reg_ans,
        uf_txt,
        REGEXP_REPLACE(total_original, '[^0-9,.-]', '', 'g') AS total_limpo,
        qtd_txt,
        linha_original
    FROM
        base
),
preparado AS (
    SELECT
        reg_ans,
        uf_txt,
        CASE
            WHEN total_limpo LIKE '%,%' THEN TRANSLATE(REPLACE(total_limpo, '.', ''), ',', '.')
            ELSE total_limpo
        END AS total_norm,
        qtd_txt,
        linha_original
    FROM
        normalizado
)
INSERT INTO
    stg_erros (
        arquivo_origem,
        linha_original,
        linha_hash,
        motivo_rejeicao
    )
SELECT
    'agregados',
    linha_original,
    MD5(linha_original),
    CASE
        WHEN reg_ans IS NULL THEN 'Operadora não encontrada no cadastro'
        WHEN LENGTH(uf_txt) != 2 THEN 'UF inválida'
        WHEN total_norm IS NULL
        OR total_norm !~ '^-?\d+(\.\d{1,2})?$' THEN 'total_despesas não numérico'
        WHEN qtd_txt IS NULL
        OR qtd_txt !~ '^\d+$' THEN 'qtd_registros inválido'
        ELSE 'erro desconhecido'
    END
FROM
    preparado
WHERE
    NOT (
        reg_ans IS NOT NULL
        AND LENGTH(uf_txt) = 2
        AND total_norm ~ '^-?\d+(\.\d{1,2})?$'
        AND qtd_txt ~ '^\d+$'
    ) ON CONFLICT (arquivo_origem, linha_hash, motivo_rejeicao) DO NOTHING;

-- Etapa 4: Pós-processamento
-- Marca despesas sem cadastro de operadora
UPDATE
    despesas
SET
    flag_sem_cadastro = TRUE
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            operadoras o
        WHERE
            o.registro_ans = despesas.registro_ans
    );

-- Marca despesas duplicadas e mantém o primeiro registro
WITH duplicados AS (
    SELECT
        registro_ans,
        ano,
        trimestre,
        COUNT(*) as qtd,
        MIN(id) as id_manter
    FROM
        despesas
    GROUP BY
        registro_ans,
        ano,
        trimestre
    HAVING
        COUNT(*) > 1
)
UPDATE
    despesas d
SET
    flag_duplicado = TRUE
WHERE
    EXISTS (
        SELECT
            1
        FROM
            duplicados dup
        WHERE
            d.registro_ans = dup.registro_ans
            AND d.ano = dup.ano
            AND d.trimestre = dup.trimestre
            AND d.id != dup.id_manter
    );

-- Atualiza estatísticas
ANALYZE operadoras;

ANALYZE despesas;

ANALYZE agregados;

-- Etapa 5: Relatórios de importação
SELECT
    'RESUMO DA IMPORTAÇÃO' AS relatorio;

SELECT
    'operadoras' AS tabela,
    (
        SELECT
            COUNT(*)
        FROM
            stg_operadoras
    ) AS total_staging,
    (
        SELECT
            COUNT(*)
        FROM
            operadoras
    ) AS total_validos,
    (
        SELECT
            COUNT(*)
        FROM
            stg_erros
        WHERE
            arquivo_origem = 'operadoras'
    ) AS total_rejeitados,
    ROUND(
        (
            SELECT
                COUNT(*) :: NUMERIC
            FROM
                operadoras
        ) / NULLIF(
            (
                SELECT
                    COUNT(*)
                FROM
                    stg_operadoras
            ),
            0
        ) * 100,
        2
    ) AS percentual_valido
UNION
ALL
SELECT
    'despesas',
    (
        SELECT
            COUNT(*)
        FROM
            stg_despesas
    ),
    (
        SELECT
            COUNT(*)
        FROM
            despesas
    ),
    (
        SELECT
            COUNT(*)
        FROM
            stg_erros
        WHERE
            arquivo_origem = 'despesas'
    ),
    ROUND(
        (
            SELECT
                COUNT(*) :: NUMERIC
            FROM
                despesas
        ) / NULLIF(
            (
                SELECT
                    COUNT(*)
                FROM
                    stg_despesas
            ),
            0
        ) * 100,
        2
    )
UNION
ALL
SELECT
    'agregados',
    (
        SELECT
            COUNT(*)
        FROM
            stg_agregados
    ),
    (
        SELECT
            COUNT(*)
        FROM
            agregados
    ),
    (
        SELECT
            COUNT(*)
        FROM
            stg_erros
        WHERE
            arquivo_origem = 'agregados'
    ),
    ROUND(
        (
            SELECT
                COUNT(*) :: NUMERIC
            FROM
                agregados
        ) / NULLIF(
            (
                SELECT
                    COUNT(*)
                FROM
                    stg_agregados
            ),
            0
        ) * 100,
        2
    );

SELECT
    'DETALHAMENTO DE ERROS' AS relatorio;

SELECT
    arquivo_origem,
    motivo_rejeicao,
    COUNT(*) AS quantidade
FROM
    stg_erros
GROUP BY
    arquivo_origem,
    motivo_rejeicao
ORDER BY
    arquivo_origem,
    quantidade DESC;

SELECT
    'FLAGS EM DESPESAS VÁLIDAS' AS relatorio;

SELECT
    'Valores Suspeitos (≤0)' AS tipo_problema,
    COUNT(*) AS quantidade,
    ROUND(
        COUNT(*) :: NUMERIC / NULLIF(
            (
                SELECT
                    COUNT(*)
                FROM
                    despesas
            ),
            0
        ) * 100,
        2
    ) AS percentual
FROM
    despesas
WHERE
    flag_valor_suspeito = TRUE
UNION
ALL
SELECT
    'Duplicados',
    COUNT(*),
    ROUND(
        COUNT(*) :: NUMERIC / NULLIF(
            (
                SELECT
                    COUNT(*)
                FROM
                    despesas
            ),
            0
        ) * 100,
        2
    )
FROM
    despesas
WHERE
    flag_duplicado = TRUE
UNION
ALL
SELECT
    'Sem Cadastro de Operadora',
    COUNT(*),
    ROUND(
        COUNT(*) :: NUMERIC / NULLIF(
            (
                SELECT
                    COUNT(*)
                FROM
                    despesas
            ),
            0
        ) * 100,
        2
    )
FROM
    despesas
WHERE
    flag_sem_cadastro = TRUE;