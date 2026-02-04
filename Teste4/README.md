
# 🚀 Teste 4 — API e Interface Web

## 🎯 Objetivo
Expor os dados tratados do Teste 3 via API Flask e interface web Vue.js, permitindo consulta, busca e visualização de estatísticas de operadoras de saúde.

---

## 🛠️ Tecnologias
- **Python 3.8+** (Flask, pandas)
- **Node.js + Vue 3 + Vite**
- **Chart.js** (gráficos)

---

## 📦 Estrutura
```
Teste4/
   backend/        # API Flask
      main.py
      requirements.txt
   frontend/       # Interface Vue.js
      App.vue
      main.js
      teste-jessicamachado/  # Projeto Vite
```

---

## 🚀 Como Executar
1. **Backend:**
   ```bash
   pip install -r backend/requirements.txt
   python backend/main.py
   ```
2. **Frontend:**
   ```bash
   cd frontend/teste-jessicamachado
   npm install
   npm run dev
   ```

---

## 📊 Funcionalidades

- Tabela paginada de operadoras
- Busca/filtro por razão social ou CNPJ
- Página de detalhes da operadora
- Histórico de despesas por operadora
- Gráfico de distribuição de despesas por UF
- Totais por trimestre

---

## 🧪 Rotas da API (Exemplos)
- `GET /api/operadoras?page=1&limit=10&search=unimed` — Lista paginada e busca
- `GET /api/operadoras/<cnpj>` — Detalhes de uma operadora
- `GET /api/operadoras/<cnpj>/despesas` — Histórico de despesas
- `GET /api/estatisticas` — Estatísticas agregadas

**Exemplo de resposta:**
```json
{
   "data": [ {"CNPJ": "...", "Razao_Social": "..."} ],
   "total": 123, "page": 1, "limit": 10
}
```

---

## 📬 Coleção Postman
- Disponível em `/Teste4/postman_collection.json` (inclui exemplos de requisições e respostas para todas as rotas)

---

## ⚖️ Trade-offs Técnicos
- **Backend Flask**: Simples, integração fácil com pandas. FastAPI foi descartado para manter o foco didático.
- **Leitura de CSVs**: Feita com pandas, limitando linhas se necessário. Banco relacional foi descartado para manter compatibilidade e simplicidade.
- **Frontend Vue 3 + Vite**: Hot reload e integração fácil com Chart.js. React foi descartado por ser mais pesado para protótipos rápidos.
- **Chart.js**: Simples e suficiente para o escopo. Alternativas como ECharts e D3.js são mais complexas.
- **Paginação e busca**: No backend, para evitar transferir grandes volumes de dados.
- **Totais por trimestre**: Calculados no frontend para evitar sobrecarga no backend.
- **Separação de responsabilidades**: Backend serve dados, frontend faz visualização e agregações simples.

---

## 📝 Observações
- Scripts e instruções compatíveis com Windows 10+ e Linux.
- Para dúvidas, consulte os exemplos de uso no Postman.

### Tratamento de Erros, Loading e Dados Vazios
- **Erros de rede/API:** Mensagem genérica (“Erro ao carregar dados”), erro completo logado no console para debug.
- **Estados de loading:** Indicador simples (“Carregando...”) enquanto aguarda resposta da API.
- **Dados vazios:** Mensagem específica (“Nenhum registro encontrado”) quando não há dados.
- **Análise crítica:** Mensagens genéricas para erros técnicos (segurança e clareza); mensagens específicas para loading e dados vazios (melhora UX).

---