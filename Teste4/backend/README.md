
# 🖥️ Teste 4 — Backend Flask

## 🎯 Objetivo
API Flask para expor dados de operadoras e despesas processados no Teste 3.

---

## 🚀 Como Executar
1. Instale as dependências:
   ```bash
   pip install -r requirements.txt
   ```
2. Inicie a API Flask:
   ```bash
   python main.py
   ```
A API estará disponível em: http://localhost:5000


---

## 🔗 Rotas principais
- `GET /api/operadoras` — Lista paginada de operadoras
- `GET /api/operadoras/<cnpj>` — Detalhes de uma operadora
- `GET /api/operadoras/<cnpj>/despesas` — Histórico de despesas
- `GET /api/estatisticas` — Estatísticas agregadas

---

## 📝 Exemplo de resposta

```json
{
   "data": [ {"CNPJ": "...", "Razao_Social": "..."} ],
   "total": 123, "page": 1, "limit": 10
}
```


---

## ⚖️ Trade-offs Técnicos
- **Flask + pandas**: Simples e rápido para prototipagem. Não foi usado banco SQL para manter compatibilidade com os outros testes.
- **Paginação e busca**: Feitas no backend para performance.
- **Leitura de CSV**: pandas lê direto, mas limita linhas se arquivo for muito grande.

---

## 🧪 Postman
- Coleção Postman disponível na raiz do Teste4 ou exporte após rodar a API.
