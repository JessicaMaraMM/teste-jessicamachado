# TESTE 1 - INTEGRAÇÃO COM API PÚBLICA
# Autora: Jéssica Mara de Morais Machado
# Objetivo: Download, extração e consolidação de Demonstrações Contábeis

# Bibliotecas

import pandas as pd
import requests
from pathlib import Path
import zipfile
from bs4 import BeautifulSoup

# Configurações

URL_BASE = "https://dadosabertos.ans.gov.br/FTP/PDA/"

# Trimestres definidos manualmente
ANO = "2025"
TRIMESTRES = ["1T2025", "2T2025", "3T2025"]

PASTA_ATUAL = Path(__file__).parent
PASTA_DOWNLOADS = PASTA_ATUAL / "downloads"
PASTA_EXTRAIDOS = PASTA_ATUAL / "extraídos"
PASTA_PROCESSADOS = PASTA_ATUAL / "processados"

# Funções

def criar_estrutura_pastas():
    """Cria pastas: downloads/, extraídos/, processados/."""
    print("📁 Estrutura de pastas")

    PASTA_DOWNLOADS.mkdir(exist_ok=True)
    PASTA_EXTRAIDOS.mkdir(exist_ok=True)
    PASTA_PROCESSADOS.mkdir(exist_ok=True)

    print("✅ Pastas criadas\n")


def encontrar_pasta_demonstracoes():
    """Navega pelo FTP da ANS e retorna URL da pasta demonstracoes_contabeis."""
    print("🔍 FTP ANS")

    try:
        resposta = requests.get(URL_BASE, timeout=30)
        resposta.raise_for_status()

        soup = BeautifulSoup(resposta.text, 'html.parser')

        for link in soup.find_all('a'):
            href = link.get('href')
            if href and 'demonstracoes_contabeis' in href.lower():
                pasta_url = f"{URL_BASE}{href}"
                print(f"  ✅ Encontrada: {href}")
                return pasta_url

        print("  ❌ Pasta 'demonstracoes_contabeis' não encontrada!")
        return None

    except Exception as erro:
        print(f"  ❌ Erro ao navegar pelo FTP: {erro}")
        return None


def baixar_arquivos_zip():
    """Baixa os ZIPs dos trimestres especificados via HTTP."""
    print("📥 Download ZIP")

    pasta_demonstracoes = encontrar_pasta_demonstracoes()

    if not pasta_demonstracoes:
        print("  ❌ Não foi possível encontrar a pasta de demonstrações!")
        return

    for trimestre in TRIMESTRES:
        url = f"{pasta_demonstracoes}{ANO}/{trimestre}.zip"
        nome_arquivo = f"{trimestre}.zip"
        caminho_destino = PASTA_DOWNLOADS / nome_arquivo

        print(f"  🔽 {trimestre}")

        try:
            resposta = requests.get(url, timeout=30)
            resposta.raise_for_status()

            with open(caminho_destino, 'wb') as arquivo:
                arquivo.write(resposta.content)

            print(f"  ✅ {nome_arquivo}")

        except Exception as erro:
            print(f"  ❌ Erro ao baixar {trimestre}: {erro}")

    print()


def extrair_arquivos_zip():
    """Extrai todos os arquivos ZIP baixados."""
    print("📦 Extração ZIP")

    arquivos_zip = list(PASTA_DOWNLOADS.glob("*.zip"))
    if not arquivos_zip:
        print("  ⚠️ Nenhum arquivo ZIP encontrado na pasta downloads!")
        return

    for arquivo_zip in arquivos_zip:
        print(f"  📂 {arquivo_zip.name}")
        try:
            with zipfile.ZipFile(arquivo_zip, 'r') as zip_ref:
                zip_ref.extractall(PASTA_EXTRAIDOS)
            print(f"  ✅ {arquivo_zip.name}")
        except Exception as erro:
            print(f"  ❌ Erro ao extrair {arquivo_zip.name}: {erro}")

    print()


def identificar_arquivos_despesas():
    """Busca arquivos por palavras-chave: despesa, evento, sinistro."""
    print("🔍 Arquivos Despesas")

    arquivos_despesas = []
    palavras_chave = ['despesa', 'evento', 'sinistro']

    for arquivo in PASTA_EXTRAIDOS.rglob("*"):
        if arquivo.is_file():
            nome_arquivo_minusculo = arquivo.name.lower()

            if any(palavra in nome_arquivo_minusculo for palavra in palavras_chave):
                arquivos_despesas.append(arquivo)
                print(f"  ✅ {arquivo.name}")

    if not arquivos_despesas:
        print("  ⚠️ Nenhum arquivo com palavras-chave")
        print("  🔄 Processando todos CSV/TXT/XLSX")

        extensoes_validas = ['.csv', '.txt', '.xls', '.xlsx']
        for arquivo in PASTA_EXTRAIDOS.rglob("*"):
            if arquivo.is_file() and arquivo.suffix.lower() in extensoes_validas:
                arquivos_despesas.append(arquivo)
                print(f"  ✅ {arquivo.name}")

    if arquivos_despesas:
        print(f"  ✅ Total: {len(arquivos_despesas)}")
    else:
        print("  ⚠️ Nenhum arquivo válido")

    print()
    return arquivos_despesas


def processar_arquivo(caminho_arquivo):
    """Lê arquivo CSV/TXT/XLSX e retorna DataFrame."""
    print(f"📄 {caminho_arquivo.name}")

    try:
        extensao = caminho_arquivo.suffix.lower()

        if extensao == '.csv':
            df = pd.read_csv(caminho_arquivo, encoding='utf-8', sep=';')
        elif extensao == '.txt':
            df = pd.read_csv(caminho_arquivo, encoding='utf-8', sep='\t')
        elif extensao in ['.xls', '.xlsx']:
            df = pd.read_excel(caminho_arquivo, engine='openpyxl')
        else:
            print(f"  ⚠️ Formato de arquivo não suportado: {extensao}")
            return None

        print(f"  ✅ {len(df)} linhas, {len(df.columns)} colunas")
        return df

    except Exception as erro:
        print(f"  ❌ Erro ao processar {caminho_arquivo.name}: {erro}")
        return None


def consolidar_dados(lista_arquivos):
    """Processa e junta todos os arquivos em um único DataFrame."""
    print("📊 Consolidação")

    lista_dataframes = []

    for arquivo in lista_arquivos:
        df = processar_arquivo(arquivo)

        if df is not None:
            df['arquivo_origem'] = arquivo.name
            lista_dataframes.append(df)

    if not lista_dataframes:
        print("  ❌ Nenhum arquivo foi processado com sucesso!")
        return None

    df_consolidado = pd.concat(lista_dataframes, ignore_index=True)

    print(f"  ✅ {len(df_consolidado)} registros, {len(df_consolidado.columns)} colunas, {len(lista_dataframes)} arquivos\n")

    return df_consolidado


def normalizar_colunas(df):
    """
    Padroniza colunas: REG_ANS, CNPJ, RazaoSocial, Ano, Trimestre,
    ValorDespesas, FlagValorSuspeito, FlagDuplicado.
    """
    print("🔄 Normalização")

    df_normalizado = df.copy()

    if 'REG_ANS' not in df_normalizado.columns:
        print("  ⚠️ Coluna REG_ANS não encontrada!")
        df_normalizado['REG_ANS'] = pd.NA

    if 'CNPJ' not in df_normalizado.columns:
        df_normalizado['CNPJ'] = pd.NA
        print("  ⚠️ Coluna CNPJ não encontrada nos dados - preenchida com NULL")

    if 'RazaoSocial' not in df_normalizado.columns and 'Razao_Social' not in df_normalizado.columns:
        df_normalizado['RazaoSocial'] = pd.NA
        print("  ⚠️ Coluna RazaoSocial não encontrada nos dados - preenchida com NULL")

    elif 'Razao_Social' in df_normalizado.columns:
        df_normalizado['RazaoSocial'] = df_normalizado['Razao_Social']

    if 'arquivo_origem' in df_normalizado.columns:
        df_normalizado['Trimestre'] = df_normalizado['arquivo_origem'].str.extract(
            r'(\dT)', expand=False)
        df_normalizado['Ano'] = df_normalizado['arquivo_origem'].str.extract(
            r'(20\d{2})', expand=False)
    else:
        df_normalizado['Trimestre'] = 'N/A'
        df_normalizado['Ano'] = '2025'

    if 'VL_SALDO_FINAL' in df_normalizado.columns:
        df_normalizado['ValorDespesas'] = pd.to_numeric(
            df_normalizado['VL_SALDO_FINAL'], errors='coerce')
        df_normalizado['ValorDespesas'] = df_normalizado['ValorDespesas'].fillna(
            0.0)
    else:
        print("  ⚠️ Coluna VL_SALDO_FINAL não encontrada!")
        df_normalizado['ValorDespesas'] = 0.0

    df_normalizado['FlagValorSuspeito'] = False
    df_normalizado['FlagDuplicado'] = False

    colunas_finais = [
        'REG_ANS', 'CNPJ', 'RazaoSocial', 'Ano', 'Trimestre',
        'ValorDespesas', 'FlagValorSuspeito', 'FlagDuplicado'
    ]

    df_final = df_normalizado[colunas_finais]

    print(f"  ✅ Colunas normalizadas: {', '.join(colunas_finais)}")
    print()

    return df_final


def marcar_valores_suspeitos(df):
    """Marca valores <= 0 como suspeitos. Mantém valores originais."""
    print("🔍 Valores suspeitos")

    df_marcado = df.copy()

    df_marcado['FlagValorSuspeito'] = (df_marcado['ValorDespesas'] <= 0) | (
        df_marcado['ValorDespesas'].isna())

    total_suspeitos = df_marcado['FlagValorSuspeito'].sum()
    total_negativos = (df_marcado['ValorDespesas'] < 0).sum()
    total_zerados = (df_marcado['ValorDespesas'] == 0).sum()

    print(f"  📋 Valores negativos: {total_negativos}")
    print(f"  📋 Valores zerados: {total_zerados}")
    print(f"  📋 Total suspeitos: {total_suspeitos}")
    print()

    return df_marcado


def detectar_duplicatas_suspeitas(df):
    """
    Detecta registros idênticos ou com REG_ANS+período+valor duplicados.
    Nota: REG_ANS pode repetir no mesmo período (múltiplas contas contábeis).
    """
    print("🔍 Duplicatas")

    df_resultado = df.copy()

    dup_total = df_resultado.duplicated(keep=False)

    dup_logica = df_resultado.duplicated(
        subset=['REG_ANS', 'Ano', 'Trimestre', 'ValorDespesas'],
        keep=False
    )

    df_resultado['FlagDuplicado'] = dup_total | dup_logica

    total_duplicados = df_resultado['FlagDuplicado'].sum()

    if total_duplicados > 0:
        print(f"  ⚠️ {total_duplicados} duplicatas")
    else:
        print("  ✅ Sem duplicatas")

    print()
    return df_resultado


def exportar_resultado(df):
    """Exporta DataFrame em CSV e ZIP com estatísticas."""
    print("💾 Exportação")

    try:
        caminho_csv = PASTA_PROCESSADOS / "consolidado_despesas.csv"
        caminho_zip = PASTA_PROCESSADOS / "consolidado_despesas.zip"

        df.to_csv(caminho_csv, index=False, encoding='utf-8-sig', sep=';')
        print(f"  ✅ {caminho_csv.name}")

        with zipfile.ZipFile(caminho_zip, 'w', zipfile.ZIP_DEFLATED) as zip_file:
            zip_file.write(caminho_csv, arcname="consolidado_despesas.csv")
        print(f"  ✅ {caminho_zip.name}\n")

        total_registros = len(df)
        total_suspeitos = df['FlagValorSuspeito'].sum()
        total_duplicados = df['FlagDuplicado'].sum()
        total_ok = ((~df['FlagValorSuspeito']) & (~df['FlagDuplicado'])).sum()

        print(f"\n📊 RESUMO:")
        print(f"  📁 {PASTA_PROCESSADOS}")
        print(f"  📄 Total de registros: {total_registros}")
        print(f"  ✅ Registros OK: {total_ok}")
        print(f"  ⚠️  Valores suspeitos: {total_suspeitos}")
        print(f"  ⚠️  Duplicatas suspeitas: {total_duplicados}")
        print()

        return True

    except Exception as erro:
        print(f"  ❌ Erro ao exportar resultados: {erro}")
        return False

# Main

def main():

    print("="*60)
    print("TESTE 1 - INTEGRAÇÃO COM API ANS")
    print("Processamento de Demonstrações Contábeis")
    print("="*60)
    print()

    try:
        criar_estrutura_pastas()
        baixar_arquivos_zip()
        extrair_arquivos_zip()

        arquivos_despesas = identificar_arquivos_despesas()

        if not arquivos_despesas:
            print("❌ Nenhum arquivo de despesas encontrado. Encerrando processo.")
            return

        df_consolidado = consolidar_dados(arquivos_despesas)

        if df_consolidado is None:
            print("❌ Falha na consolidação dos dados. Encerrando processo.")
            return

        df_normalizado = normalizar_colunas(df_consolidado)
        df_com_flags_valor = marcar_valores_suspeitos(df_normalizado)
        df_final = detectar_duplicatas_suspeitas(df_com_flags_valor)

        sucesso = exportar_resultado(df_final)

        if sucesso:
            print("="*60)
            print("✅ PROCESSAMENTO CONCLUÍDO")
            print("="*60)
            print(f"\n📁 {PASTA_PROCESSADOS}")
            print("📄 consolidado_despesas.zip")
            print()
        else:
            print("⚠️ Processamento com erros")

    except Exception as erro:
        print(f"\n❌ ERRO CRÍTICO: {erro}")
        print("Encerrando processamento.")
        import traceback
        traceback.print_exc()

# Executar


if __name__ == "__main__":
    main()
