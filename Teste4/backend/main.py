from flask import Flask, request, jsonify
import pandas as pd
import os

app = Flask(__name__)

OPERADORAS_CSV = r'C:\Users\jessi\OneDrive\Área de Trabalho\Teste_JessicaMachado\Teste3\data\operadoras.csv'
DESPESAS_CSV = r'C:\Users\jessi\OneDrive\Área de Trabalho\Teste_JessicaMachado\Teste3\data\consolidado_despesas.csv'
AGREGADAS_CSV = r'C:\Users\jessi\OneDrive\Área de Trabalho\Teste_JessicaMachado\Teste3\data\despesas_agregadas.csv'


@app.route('/')
def index():
    return {'status': 'API Flask rodando'}

# Lista paginada de operadoras (CSV)

@app.route('/api/operadoras')
def get_operadoras():
    page = int(request.args.get('page', 1))
    limit = int(request.args.get('limit', 10))
    search = request.args.get('search', '').strip().lower()
    try:
        df = pd.read_csv(OPERADORAS_CSV, dtype=str, sep=';')
        if search:
            df = df[df['Razao_Social'].str.lower().str.contains(
                search) | df['CNPJ'].str.contains(search)]
        total = len(df)
        start = (page - 1) * limit
        end = start + limit
        data = df.iloc[start:end][['CNPJ', 'Razao_Social']
                                  ].to_dict(orient='records')
        return jsonify({'data': data, 'total': total, 'page': page, 'limit': limit})
    except Exception as e:
        return jsonify({'error': f'Erro ao ler operadoras.csv: {str(e)}'}), 500

# Detalhes de uma operadora

@app.route('/api/operadoras/<cnpj>')
def get_operadora(cnpj):
    try:
        df = pd.read_csv(OPERADORAS_CSV, dtype=str, sep=';')
        op = df[df['CNPJ'] == cnpj]
        if op.empty:
            return jsonify({'error': 'Operadora não encontrada'}), 404
        row = op.iloc[0]
        result = {
            'CNPJ': row['CNPJ'],
            'RAZAO_SOCIAL': row['Razao_Social'],
            'UF': row['UF']
        }
        return jsonify(result)
    except Exception as e:
        return jsonify({'error': f'Erro ao ler operadoras.csv: {str(e)}'}), 500

# Histórico de despesas da operadora

@app.route('/api/operadoras/<cnpj>/despesas')
def get_despesas_operadora(cnpj):
    try:
        df_op = pd.read_csv(OPERADORAS_CSV, dtype=str, sep=';')
        op = df_op[df_op['CNPJ'] == cnpj]
        if op.empty:
            return jsonify({'error': 'Operadora não encontrada'}), 404
        reg_ans = op.iloc[0]['REGISTRO_OPERADORA']
        try:
            df_desp = pd.read_csv(DESPESAS_CSV, dtype=str, sep=';')
        except Exception as e:
            return jsonify({'error': f'Erro ao ler o arquivo de despesas: {str(e)}'}), 500
        # Ajuste para nomes reais das colunas
        if 'REG_ANS' not in df_desp.columns:
            return jsonify({'error': 'Coluna REG_ANS não encontrada no CSV de despesas.'}), 500
        filtro = df_desp['REG_ANS'] == reg_ans
        despesas_df = df_desp.loc[filtro, ['Ano', 'Trimestre', 'ValorDespesas']].copy()
        # Converter para float e filtrar apenas valores maiores que zero
        despesas_df['ValorDespesas'] = pd.to_numeric(despesas_df['ValorDespesas'], errors='coerce').fillna(0)
        despesas_df = despesas_df[despesas_df['ValorDespesas'] > 0]
        despesas = despesas_df.rename(columns={
            'Ano': 'ANO',
            'Trimestre': 'TRIMESTRE',
            'ValorDespesas': 'VALOR_DESPESA'
        }).to_dict(orient='records')
        return jsonify({'cnpj': cnpj, 'despesas': despesas})
    except Exception as e:
        return jsonify({'error': f'Erro ao ler despesas: {str(e)}'}), 500

# Estatísticas agregadas

@app.route('/api/estatisticas')
def get_estatisticas():
    try:
        try:
            df_ag = pd.read_csv(AGREGADAS_CSV)
        except Exception as e:
            return jsonify({'error': 'Arquivo de estatísticas muito grande para leitura direta. Use um arquivo menor para testes.'}), 500
        df_ag['TotalDespesas'] = pd.to_numeric(df_ag['TotalDespesas'], errors='coerce').fillna(0)
        total_despesas = float(df_ag['TotalDespesas'].sum())
        media_despesas = float(df_ag['TotalDespesas'].mean())
        top5 = df_ag.nlargest(5, 'TotalDespesas')[['RazaoSocial', 'TotalDespesas']].to_dict(orient='records')
        uf_despesas = df_ag.groupby('UF')['TotalDespesas'].sum().to_dict()
        return jsonify({
            'total_despesas': total_despesas,
            'media_despesas': media_despesas,
            'top5_operadoras': top5,
            'uf_despesas': uf_despesas
        })
    except Exception as e:
        return jsonify({'error': f'Erro ao calcular estatísticas: {str(e)}'}), 500


if __name__ == '__main__':
    app.run(debug=True)
