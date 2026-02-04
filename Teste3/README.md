
# 🗄️ Teste 3 – Banco de Dados e Análise

## 🎯 Objetivo
Modelar, importar e analisar dados de despesas de operadoras de saúde, tratando inconsistências e justificando decisões técnicas (DDL, ETL e queries analíticas).

---

## ⚖️ Trade-offs e Decisões Técnicas

### 1. Normalização vs Desnormalização
**Escolha:** Tabelas normalizadas (operadoras, despesas, agregados)
- **Justificativa:**
  - Volume de dados alto e crescimento esperado
  - Facilita manutenção, integridade e reuso
  - Queries analíticas ficam mais flexíveis
  - Evita redundância e inconsistências
- **Descartado:** Tabela única desnormalizada (dificulta manutenção, aumenta redundância)

### 2. Tipos de Dados
- **Valores monetários:** `DECIMAL(15,2)`
  - **Justificativa:** Alta precisão, sem erros de arredondamento (diferente de FLOAT)
  - **Descartado:** FLOAT (impreciso para dinheiro), INTEGER (limita centavos)
- **Datas:** `INTEGER` para ano/trimestre
  - **Justificativa:** Não há datas completas, apenas períodos
  - **Descartado:** DATE/TIMESTAMP (não aplicável)

### 3. Tratamento de Inconsistências
- **NULLs em campos obrigatórios:** Rejeitados e registrados em `stg_erros`
- **Strings em campos numéricos:** Limpeza com regex e conversão
- **Datas/Períodos inconsistentes:** Normalização (ex: "1T" → 1)
- **Valores monetários com muitas casas decimais:** Arredondamento para 2 casas
- **Despesas sem operadora:** Importadas e marcadas com flag
- **Duplicados:** Importados, mas marcados com flag
- **Valores suspeitos (≤0):** Importados, mas marcados com flag


---

## 🚀 Como Executar
1. Execute `1_create_tables.sql` para criar as tabelas
2. Execute `2_import_data.sql` para importar e tratar os dados
3. Execute as queries analíticas: `3_query_crescimento.sql`, `4_query_distribuicao.sql`, `5_query_acima_media.sql`


---

## ℹ️ Observações
- Scripts compatíveis com PostgreSQL 14+ (ajustável para MySQL 8.0)
- Flags e logs permitem auditoria e reprocessamento
- Scripts e queries estão indentados e comentados para facilitar avaliação

---
