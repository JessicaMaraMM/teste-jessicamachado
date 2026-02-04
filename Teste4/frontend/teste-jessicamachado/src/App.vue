
<template>
  <div>
    <h1>Operadoras ANS</h1>
    <input v-model="search" placeholder="Buscar por razão social ou CNPJ" />
    <table>
      <thead>
        <tr>
          <th>CNPJ</th>
          <th>Razão Social</th>
          <th>Ações</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="op in operadoras" :key="op.CNPJ">
          <td>{{ op.CNPJ }}</td>
          <td>{{ op.Razao_Social }}</td>
          <td><button @click="selectOperadora(op.CNPJ)">Detalhes</button></td>
        </tr>
      </tbody>
    </table>
    <div>
      <button :disabled="page === 1" @click="page--">Anterior</button>
      <span>Página {{ page }}</span>
      <button :disabled="page * limit >= total" @click="page++">Próxima</button>
    </div>
    <div v-if="selectedOperadora">
      <h2>Detalhes da Operadora</h2>
      <p><strong>CNPJ:</strong> {{ selectedOperadora.CNPJ }}</p>
      <p><strong>Razão Social:</strong> {{ selectedOperadora.RAZAO_SOCIAL }}</p>
      <p><strong>UF:</strong> {{ selectedOperadora.UF }}</p>
      <h3>Histórico de Despesas</h3>
      <table>
        <thead>
          <tr>
            <th>Ano</th>
            <th>Trimestre</th>
            <th>Valor</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="d in despesas" :key="d.ANO + '-' + d.TRIMESTRE + '-' + d.VALOR_DESPESA">
            <td>{{ d.ANO }}</td>
            <td>{{ d.TRIMESTRE }}</td>
            <td>{{ d.VALOR_DESPESA }}</td>
          </tr>
        </tbody>
      </table>
      <div v-if="despesas.length">
        <h4>Total por Trimestre</h4>
        <ul>
          <li v-for="(valor, chave) in getTotaisPorTrimestre()" :key="chave">
            {{ chave }}: {{ valor.toLocaleString('pt-BR', {minimumFractionDigits: 2}) }}
          </li>
        </ul>
      </div>
    </div>
    <div>
      <h2>Distribuição de Despesas por UF</h2>
      <canvas id="ufChart"></canvas>
    </div>
    </div>
    </template>

  <script>
  import Chart from 'chart.js/auto';
  window.Chart = Chart;

  export default {
  data() {
    return {
      operadoras: [],
      total: 0,
      page: 1,
      limit: 10,
      search: '',
      selectedCnpj: null,
      selectedOperadora: null,
      despesas: [],
      ufChart: null
    };
  },
  watch: {
    page() { this.fetchOperadoras(); },
    search() { this.page = 1; this.fetchOperadoras(); }
  },
  mounted() {
    this.fetchOperadoras();
    this.fetchDespesasUF();
  },
  methods: {
    async fetchOperadoras() {
      let url = `/api/operadoras?page=${this.page}&limit=${this.limit}`;
      if (this.search) url += `&search=${encodeURIComponent(this.search)}`;
      try {
        const res = await fetch(url);
        const json = await res.json();
        this.operadoras = json.data || [];
        this.total = json.total || 0;
      } catch (e) {
        this.operadoras = [];
        this.total = 0;
      }
    },
    async selectOperadora(cnpj) {
      this.selectedCnpj = cnpj;
      try {
        const opRes = await fetch(`/api/operadoras/${cnpj}`);
        this.selectedOperadora = await opRes.json();
        const despRes = await fetch(`/api/operadoras/${cnpj}/despesas`);
        const despJson = await despRes.json();
        this.despesas = despJson.despesas || [];
      } catch (e) {
        this.selectedOperadora = null;
        this.despesas = [];
      }
    },
    async fetchDespesasUF() {
      try {
        const res = await fetch('/api/estatisticas');
        const json = await res.json();
        // Supondo que a API retorne distribuição por UF em json.uf_despesas
        const ufData = json.uf_despesas || {};
        const labels = Object.keys(ufData);
        const values = Object.values(ufData);
        if (window.Chart) {
          if (this.ufChart) this.ufChart.destroy();
          const ctx = document.getElementById('ufChart').getContext('2d');
          this.ufChart = new window.Chart(ctx, {
            type: 'bar',
            data: {
              labels,
              datasets: [{
                label: 'Despesas por UF',
                data: values,
                backgroundColor: '#42b983'
              }]
            },
            options: {
              indexAxis: 'y', // barras horizontais
              responsive: true,
              plugins: { legend: { display: false } }
            }
          });
        }
      } catch (e) {}
    },
    getTotaisPorTrimestre() {
      const totais = {};
      for (const d of this.despesas) {
        const chave = `${d.ANO} ${d.TRIMESTRE}`;
        const valor = parseFloat(d.VALOR_DESPESA) || 0;
        totais[chave] = (totais[chave] || 0) + valor;
      }
      return totais;
    }
  }

};
</script>

<style scoped>
table { border-collapse: collapse; width: 100%; margin-bottom: 10px; }
th, td { border: 1px solid #ccc; padding: 8px; }
input { margin-bottom: 10px; padding: 5px; width: 300px; }
button { margin: 5px; }
canvas { max-width: 600px; margin-top: 20px; }
</style>
