
# 🌐 Teste 4 — Frontend Vue.js

## 🎯 Objetivo
Interface web para consulta, busca e visualização dos dados das operadoras expostos pela API Flask.

---

## 📁 Estrutura
```
frontend/
   App.vue
   main.js
   teste-jessicamachado/  # Projeto Vite
```

---

## 🛠️ Funcionalidades

- Tabela paginada de operadoras
- Busca/filtro por razão social ou CNPJ
- Página de detalhes da operadora
- Histórico de despesas por operadora
- Gráfico de distribuição de despesas por UF
- Totais por trimestre

---

## 🚀 Como Executar
1. Instale as dependências:
   ```bash
   cd teste-jessicamachado
   npm install
   ```
2. Inicie o servidor de desenvolvimento:
   ```bash
   npm run dev
   ```

---

## ⚖️ Trade-offs Técnicos
- **Vue 3 + Vite**: Hot reload, fácil integração com Chart.js.
- **Chart.js**: Simples e suficiente para o escopo.
- **Totais por trimestre**: Calculados no frontend para evitar sobrecarga no backend.

---

## 🧪 Postman
- Veja README do backend para exemplos de uso e coleção Postman.