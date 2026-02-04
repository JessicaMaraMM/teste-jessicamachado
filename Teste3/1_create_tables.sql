-- TESTE 3: MODELAGEM DE BANCO DE DADOS
-- Autora: Jéssica Mara de Morais Machado
-- SGBD: PostgreSQL 14+
-- Estrutura: 3 tabelas normalizadas (operadoras, despesas, agregados)

-- Limpeza de tabelas existentes
DROP TABLE IF EXISTS agregados CASCADE;
DROP TABLE IF EXISTS despesas CASCADE;
DROP TABLE IF EXISTS operadoras CASCADE;
DROP TABLE IF EXISTS agregados CASCADE;
DROP TABLE IF EXISTS despesas CASCADE;
DROP TABLE IF EXISTS operadoras CASCADE;

-- Tabela 1: Cadastro de Operadoras
CREATE TABLE operadoras (
    registro_ans INTEGER PRIMARY KEY,
    cnpj VARCHAR(18) UNIQUE,
    razao_social VARCHAR(255) NOT NULL,
    modalidade VARCHAR(100),
    uf CHAR(2)
);

-- Índices para tabelas operadoras
CREATE INDEX idx_operadoras_cnpj ON operadoras(cnpj);

CREATE INDEX idx_operadoras_uf ON operadoras(uf);

CREATE INDEX idx_operadoras_razao_social ON operadoras(razao_social);

-- Tabela 2: Despesas por Operadora
CREATE TABLE despesas (
    id SERIAL PRIMARY KEY,
    registro_ans INTEGER NOT NULL,
    ano INTEGER NOT NULL,
    trimestre INTEGER NOT NULL CHECK (
        trimestre BETWEEN 1
        AND 4
    ),
    trimestre INTEGER NOT NULL CHECK (
        trimestre BETWEEN 1
        AND 4
    ),
    valor_despesas DECIMAL(15, 2) NOT NULL,
    flag_valor_suspeito BOOLEAN DEFAULT FALSE,
    flag_duplicado BOOLEAN DEFAULT FALSE,
    flag_cnpj_invalido BOOLEAN DEFAULT FALSE,
    flag_razao_social_invalida BOOLEAN DEFAULT FALSE,
    flag_sem_cadastro BOOLEAN DEFAULT FALSE 
    flag_sem_cadastro BOOLEAN DEFAULT FALSE -- Sem FK: permite despesas sem operadora (identificadas por flag_sem_cadastro)
);

-- Índices para tabela despesas
CREATE INDEX idx_despesas_operadora ON despesas(registro_ans);

CREATE INDEX idx_despesas_periodo ON despesas(ano, trimestre);

CREATE INDEX idx_despesas_operadora_periodo ON despesas(registro_ans, ano, trimestre);

-- Tabela 3: Agregados de Despesas por Operadora e Período
CREATE TABLE agregados (
    id SERIAL PRIMARY KEY,
    registro_ans INTEGER NOT NULL,
    uf CHAR(2) NOT NULL,
    total_despesas DECIMAL(15, 2) NOT NULL,
    media_despesas DECIMAL(15, 2) NOT NULL,
    desvio_padrao DECIMAL(15, 2),
    qtd_registros INTEGER NOT NULL,
    CONSTRAINT fk_agregados_operadoras FOREIGN KEY (registro_ans) REFERENCES operadoras(registro_ans),
    CONSTRAINT uk_agregados_operadora_uf UNIQUE (registro_ans, uf)
);

-- Índices para tabela agregados
CREATE INDEX idx_agregados_operadora ON agregados(registro_ans);

CREATE INDEX idx_agregados_uf ON agregados(uf);

CREATE INDEX idx_agregados_total_desc ON agregados(total_despesas DESC);

-- RESUMO: 3 tabelas + 9 índices criados (12 incluindo PKs)
SELECT
    *
FROM
    pg_tables
WHERE
    schemaname = 'public';

SELECT
    *
FROM
    pg_tables
WHERE
    schemaname = 'public';