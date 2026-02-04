# Teste 4 — Frontend Vue.js (Vite)

## Objetivo
Interface web para consulta, busca e visualização dos dados das operadoras via API Flask.

## Estrutura
```
teste-jessicamachado/
  App.vue
  main.js
  ...
```

## Funcionalidades
- Tabela paginada de operadoras
- Busca/filtro por razão social ou CNPJ
- Página de detalhes da operadora
- Histórico de despesas por operadora
- Gráfico de distribuição de despesas por UF
- Totais por trimestre

## Execução
1. Instale dependências:
   ```bash
   npm install
   ```
2. Inicie o servidor de desenvolvimento:
   ```bash
   npm run dev
   ```

## Trade-offs Técnicos
- **Vue 3 + Vite**: Hot reload, fácil integração com Chart.js.
- **Chart.js**: Simples e suficiente para o escopo.
- **Totais por trimestre**: Calculados no frontend para evitar sobrecarga no backend.

## Postman
- Veja README do backend para exemplos de uso e coleção Postman.

1. Instale as dependências:
   ```sh
   npm install
   ```
2. Inicie o servidor de desenvolvimento:
   ```sh
   npm run dev
   ```
3. Acesse o endereço exibido no terminal (ex: http://localhost:5173)

O frontend está configurado para consumir a API Flask em http://localhost:5000 via proxy.
