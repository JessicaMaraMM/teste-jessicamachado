
# 📊 Teste 1 — Integração com API Pública (ANS)

## 🎯 Objetivo

Pipeline para baixar, extrair e consolidar Demonstrações Contábeis da ANS, sinalizando automaticamente valores suspeitos e duplicatas.

---

## 🛠️ Tecnologias

- **Python 3.8+**
- **pandas:** Manipulação de DataFrames
- **requests + BeautifulSoup:** Web scraping do FTP ANS
- **openpyxl:** Leitura de arquivos Excel

---

## ⚙️ Ambiente Virtual (opcional)

```bash
# Crie e ative o ambiente virtual (Windows)
python -m venv venv
venv\Scripts\activate
```
Instale as dependências:
```bash
pip install -r requirements.txt
```


## 🚀 Como Rodar

```bash
# A partir da raiz do projeto
python Teste1/main.py
```



**Saídas esperadas:**
- `Teste1/processados/consolidado_despesas.csv`
- `Teste1/processados/consolidado_despesas.zip`

---

## 📊 Entrada e Saída

### Entrada
- **Fonte:** FTP público da ANS (`dados.ans.gov.br`)
- **Arquivos:** ZIPs de Demonstrações Contábeis (3 trimestres de 2025)

### Saída
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `REG_ANS` | int | Registro da operadora |
| `CNPJ` | NULL | Não disponível nesta fonte |
| `RazaoSocial` | NULL | Não disponível nesta fonte |
| `Ano` | int | Extraído do nome do arquivo |
| `Trimestre` | int | Extraído do nome do arquivo |
| `ValorDespesas` | float | Mapeado de `VL_SALDO_FINAL` |
| `FlagValorSuspeito` | bool | Valores ≤ 0 |
| `FlagDuplicado` | bool | Registros duplicados |

---

## 🎯 Decisões Técnicas

### 1. Processamento em Memória
**Por quê:** Volume pequeno (3 trimestres ≈ 2.1M registros ≈ 250MB) permite processamento direto sem chunks.

### 2. Navegação Dinâmica no FTP
**Por quê:** Evita hardcoding de URLs. O código busca automaticamente a pasta `demonstracoes_contabeis`.

### 3. Identificação Inteligente de Arquivos
**Por quê:** Busca arquivos com palavras-chave (`despesa`, `evento`, `sinistro`). Fallback para todos os arquivos compatíveis se nenhum for encontrado.

### 4. Sinalização, Não Remoção
**Por quê:** Valores zerados/negativos podem ser legítimos (estornos, ausência de despesas). Duplicatas podem ter justificativas contábeis. Flags permitem análise posterior.

### 5. CNPJ e Razão Social NULL
**Por quê:** Demonstrações Contábeis não contêm essas informações. Enriquecimento será feito no Teste 2 com cadastro ANS.

---

## ⚠️ Limitações Conhecidas

- **Trimestres fixos:** Atualmente processa apenas 1T, 2T e 3T de 2025 (configurado manualmente)
- **Sem paralelização:** Downloads sequenciais (adequado para 3 arquivos)
- **Memória:** Não escala para volumes > 10M registros sem adaptação
- **Sem retry:** Falhas de rede não têm tentativas automáticas

---

## 📝 Exemplo de Execução (resumido)

```
✅ Pastas criadas
✅ Busca pasta demonstrações: demonstracoes_contabeis
✅ Download ZIPs: 1T2025.zip, 2T2025.zip, 3T2025.zip
✅ Extração: 1T2025.csv, 2T2025.csv, 3T2025.csv
✅ Processamento: 2.113.924 registros consolidados
✅ Exportação: consolidado_despesas.csv, consolidado_despesas.zip
📊 RESUMO: 2.113.924 registros | 76.454 OK | 2.088.874 valores suspeitos | 2.096.250 duplicatas
✅ PROCESSO CONCLUÍDO

```
