
# 📊 Teste Técnico — Engenharia de Dados ANS

**Autora:** Jéssica Mara de Morais Machado  
**Stack:** Python • SQL • Flask • Vue.js

---

## 🎯 Visão Geral
Pipeline completo de dados da ANS, dividido em 4 etapas:
1. **Extração:** Download e consolidação dos dados brutos das Demonstrações Contábeis (Teste1)
2. **Transformação e Validação:** Enriquecimento, limpeza, validação e agregação dos dados (Teste2)
3. **Modelagem e Análise:** Estruturação dos dados em banco relacional e queries analíticas (Teste3)
4. **API e Interface Web:** Exposição dos dados via API Flask e frontend Vue.js (Teste4)

Cada etapa possui README próprio detalhado.

---

## 📁 Estrutura do Repositório
```
Teste_JessicaMachado/
├── Teste1/          ETL de Demonstrações Contábeis (Python)
├── Teste2/          Transformação e Validação (Python)
├── Teste3/          Modelagem e Queries SQL (PostgreSQL)
├── Teste4/          API Flask + Frontend Vue.js
└── README.md        Este arquivo
```

---

## 🚀 Execução Rápida
```bash
# Instalar dependências globais (se necessário)
pip install -r requirements.txt

# Executar cada etapa
python Teste1/main.py                    # → consolidado_despesas.csv
python Teste2/main.py                    # → dados_validados.csv
# Para Teste3, siga instruções do README da pasta
python Teste4/backend/main.py            # → Inicia API Flask
cd Teste4/frontend/teste-jessicamachado && npm install && npm run dev  # → Inicia frontend Vue.js
```
---

## 📦 Funcionalidades por Etapa
- **Teste1:** Download, extração e consolidação dos dados ANS
- **Teste2:** Enriquecimento, validação, agregação e geração de estatísticas
- **Teste3:** Modelagem relacional, importação, queries analíticas e estatísticas
- **Teste4:** API REST (Flask) e interface web (Vue.js) com tabela paginada, busca, detalhes e gráfico de despesas por UF

---

## 📚 Detalhes Técnicos
Os trade-offs, decisões de modelagem e justificativas técnicas estão detalhados nos READMEs de cada etapa (Teste1, Teste2, Teste3, Teste4). Consulte-os para informações aprofundadas sobre cada parte do pipeline.

---

## 📝 Tratamento de Erros, Loading e Dados Vazios
- **Erros de rede/API:** Mensagem genérica (“Erro ao carregar dados”), erro completo logado no console
- **Loading:** Indicador simples (“Carregando...”) durante requisições
- **Dados vazios:** Mensagem específica (“Nenhum registro encontrado”)
- **Análise crítica:** Mensagens genéricas para erros técnicos (segurança e clareza); mensagens específicas para loading e dados vazios (melhora UX)

---