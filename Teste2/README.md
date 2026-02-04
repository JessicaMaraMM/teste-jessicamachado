
# 🔄 Teste 2 — Transformação e Validação de Dados

## 🎯 Objetivo

Pipeline para transformar, validar e enriquecer dados de despesas de operadoras de saúde, cruzando com cadastro ANS, validando CNPJ/razão social e gerando estatísticas agregadas.


## 🧠 Trade-offs e Análise Crítica

### Estratégia para CNPJs inválidos
Todos os CNPJs são validados. Os inválidos são marcados com a flag `FlagCNPJInvalido` e mantidos no dataset para rastreabilidade, mas podem ser filtrados em análises posteriores. Não são corrigidos automaticamente para evitar falsos positivos.

### Join (enriquecimento)
O join entre consolidado e cadastro ANS é feito via `pandas.merge` (estratégia em memória), pois o volume de dados é gerenciável e o pandas oferece flexibilidade e performance para cruzamento e limpeza. SQL/streaming foi descartado por simplicidade e portabilidade.

### Ordenação
A ordenação dos dados é feita com `sort_values` do pandas, suficiente para o volume atual. Para volumes muito grandes, recomenda-se processamento em lotes ou uso de banco de dados.

### CNPJs duplicados com razões sociais diferentes
Mantidos ambos os registros, mas marcados para análise posterior. Duplicatas são identificadas e podem ser filtradas.

### Valores zerados ou negativos
São marcados com a flag `FlagValorSuspeito` e mantidos para auditoria, mas podem ser excluídos em análises.

### Registros sem match no cadastro
São marcados com a flag `FlagSemCadastro`. Mantidos para transparência, mas sinalizados como incompletos.

## 🛠️ Tecnologias

- **Python 3.8+**
- **pandas:** JOIN, validação e agregação
- **requests + BeautifulSoup:** Download do cadastro ANS
- **zipfile:** Compactação de resultados

---

## 🚀 Como Executar

```bash

# 1. Instale as dependências (a partir da raiz do projeto)
pip install -r requirements.txt

# 2. Execute o pipeline completo
python Teste2/main.py

```

**Pré-requisito:** Execute o Teste 1 antes (gera o arquivo `Teste1/processados/consolidado_despesas.csv`)

---


**Saídas esperadas:**
- `Teste2/processados/dados_validados.csv`
- `Teste2/processados/despesas_agregadas.csv`
- `Teste2/Teste_JessicaMachado.zip`

---


---

## 📊 Entrada e Saída

### Entrada
1. **`../Teste1/processados/consolidado_despesas.csv`** (2.1M registros do Teste 1)
2. **Cadastro ANS:** Download automático de `operadoras_de_plano_de_saude_ativas/`

### Saída 1: dados_validados.csv
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `RegistroANS` | int | Registro da operadora |
| `CNPJ` | str | CNPJ enriquecido do cadastro |
| `RazaoSocial` | str | Razão Social enriquecida |
| `Ano` | int | Ano da despesa |
| `Trimestre` | int | Trimestre da despesa |
| `ValorDespesas` | float | Valor da despesa |
| `Modalidade` | str | Modalidade da operadora |
| `UF` | str | Estado da operadora |
| `FlagValorSuspeito` | bool | Valores ≤ 0 (do Teste 1) |
| `FlagDuplicado` | bool | Duplicatas (do Teste 1) |
| `FlagSemCadastro` | bool | Não encontrou match no cadastro |
| `FlagCNPJInvalido` | bool | CNPJ com dígitos verificadores incorretos |
| `FlagRazaoSocialInvalida` | bool | Razão Social vazia/NULL |

### Saída 2: despesas_agregadas.csv
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `RazaoSocial` | str | Nome da operadora |
| `UF` | str | Estado |
| `TotalDespesas` | float | Soma de todas as despesas |
| `MediaDespesas` | float | Média por trimestre |
| `DesvioPadrao` | float | Variabilidade dos valores |
| `QtdRegistros` | int | Quantidade de registros |

---

## 🎯 Decisões Técnicas

### 1. LEFT JOIN (não INNER)
**Por quê:** Mantém todos os 2.1M registros mesmo sem match no cadastro. `FlagSemCadastro` sinaliza os 0.89% sem correspondência para análise posterior.

### 2. JOIN por REG_ANS (não por CNPJ)
**Por quê:** CNPJ estava NULL no Teste 1. REG_ANS é a chave primária oficial das operadoras ANS.

### 3. Validação de CNPJ com Dígitos Verificadores
**Por quê:** Implementa cálculo completo dos 2 dígitos verificadores (pesos específicos para cada posição), não apenas verificação de formato.

### 4. Sinalização, Não Remoção
**Por quê:** CNPJs inválidos podem estar no cadastro oficial. Razões Sociais vazias já foram sinalizadas. Flags permitem filtragem posterior pelo analista.

### 5. Agregação por RazaoSocial + UF
**Por quê:** Operadoras podem atuar em múltiplos estados. Agregação separada permite análise regional.

### 6. Encoding UTF-8
**Por quê:** Cadastro ANS contém acentuação ("BIOVIDA SAÚDE"). UTF-8 evita caracteres corrompidos.

---

## ⚠️ Limitações Conhecidas

- **Ordem de execução:** Requer Teste 1 concluído (dependência de `consolidado_despesas.csv`)
- **Duplicatas no cadastro:** Remove com `keep='first'` (arbitrário, mas consistente)
- **Sem match no cadastro:** 0.89% dos registros (11 RegistroANS únicos) não encontram correspondência
- **Processamento em memória:** Não escala para volumes > 10M registros sem adaptação
- **Sem validação de UF:** Não verifica se sigla é válida (confia na fonte ANS)

---

## 📊 Exemplo de Saída (resumido)

```
✅ Pastas criadas
✅ Download cadastro ANS: Relatorio_cadop.csv
✅ Consolidado: 2.113.924 registros
✅ Cadastro: 1.500 operadoras
✅ 8 duplicatas removidas
✅ 18.739 sem cadastro (0.89%)
✅ CNPJs inválidos: 19.250
✅ Razões inválidas: 18.739
✅ Valores suspeitos: 2.088.874
✅ Duplicatas: 2.096.250
✅ dados_validados.csv salvo
✅ despesas_agregadas.csv salvo
✅ Teste_JessicaMachado.zip gerado
✅ PROCESSO CONCLUÍDO
```