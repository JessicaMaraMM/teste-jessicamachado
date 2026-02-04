# TESTE 2 - TRANSFORMAÇÃO E VALIDAÇÃO DE DADOS
# Autora: Jéssica Mara de Morais Machado
# Objetivo: Transformação, validação e enriquecimento de dados de despesas com operadoras de saúde, incluindo validação de CNPJ, agregação e cruzamento com cadastro ANS.

# Bibliotecas

import pandas as pd
import requests
import os
from bs4 import BeautifulSoup

# Configurações dos arquivos

CAMINHO_CONSOLIDADO = '../Teste1/processados/consolidado_despesas.csv'
CAMINHO_DOWNLOAD = 'downloads/'
CAMINHO_ENRIQUECIDO = 'processados/dados_enriquecidos.csv'
CAMINHO_VALIDADO = 'processados/dados_validados.csv'
CAMINHO_PROCESSADOS = 'processados/'

URL_CADASTRO_ANS = 'https://dadosabertos.ans.gov.br/FTP/PDA/operadoras_de_plano_de_saude_ativas/'


# Funções para enriquecimento com cadastro ANS

def criar_pastas():
    """Cria pastas: downloads/, processados/."""
    print("📁 Estrutura de pastas")

    os.makedirs(CAMINHO_DOWNLOAD, exist_ok=True)
    os.makedirs(CAMINHO_PROCESSADOS, exist_ok=True)

    print("✅ Pastas criadas\n")


def baixar_cadastro_ans():
    """Baixa o arquivo de cadastro da ANS."""
    print("📥 Download cadastro ANS")

    response = requests.get(URL_CADASTRO_ANS, timeout=30)
    response.raise_for_status()

    soup = BeautifulSoup(response.text, 'html.parser')

    arquivos_csv = []
    for link in soup.find_all('a'):
        href = link.get('href')
        if href and href.endswith('.csv'):
            arquivos_csv.append(href)

    if not arquivos_csv:
        raise FileNotFoundError("Nenhum arquivo CSV encontrado no FTP da ANS")

    arquivo_escolhido = arquivos_csv[0]
    print(f"  ✅ {arquivo_escolhido}")

    caminho_local = os.path.join(CAMINHO_DOWNLOAD, arquivo_escolhido)
    if os.path.exists(caminho_local):
        return arquivo_escolhido

    url_completa = URL_CADASTRO_ANS + arquivo_escolhido

    response = requests.get(url_completa, timeout=30)
    response.raise_for_status()

    with open(caminho_local, 'wb') as f:
        f.write(response.content)

    print()
    return arquivo_escolhido


def carregar_dados(nome_arquivo_cadastro):
    """Carrega consolidado do Teste 1 e cadastro ANS."""
    print("📂 Carregamento")

    consolidado = pd.read_csv(CAMINHO_CONSOLIDADO, sep=';')
    print(f"  ✅ Consolidado: {len(consolidado):,} registros")

    caminho_cadastro = os.path.join(CAMINHO_DOWNLOAD, nome_arquivo_cadastro)
    cadastro = pd.read_csv(caminho_cadastro, encoding='utf-8', sep=';')
    print(f"  ✅ Cadastro: {len(cadastro):,} operadoras\n")

    return consolidado, cadastro


def enriquecer_dados(consolidado, cadastro):
    """Faz o JOIN e enriquece os dados."""
    print("🔗 Enriquecimento")

    cadastro.rename(columns={
        'REGISTRO_OPERADORA': 'REG_ANS',
        'Razao_Social': 'RazaoSocial'
    }, inplace=True)

    tamanho_original = len(cadastro)
    cadastro_limpo = cadastro.drop_duplicates(subset='REG_ANS', keep='first')
    duplicatas_removidas = tamanho_original - len(cadastro_limpo)
    print(f"  ⚠️  {duplicatas_removidas} duplicatas removidas")

    resultado = consolidado.merge(
        cadastro_limpo[['REG_ANS', 'CNPJ', 'RazaoSocial', 'Modalidade', 'UF']],
        on='REG_ANS',
        how='left',
        suffixes=('', '_Cadastro')
    )

    resultado['CNPJ'] = resultado['CNPJ_Cadastro']
    resultado['RazaoSocial'] = resultado['RazaoSocial_Cadastro']

    resultado['FlagSemCadastro'] = resultado['CNPJ'].isna()
    sem_cadastro = resultado['FlagSemCadastro'].sum()
    print(f"  ⚠️  {sem_cadastro:,} sem cadastro")

    resultado.drop(['CNPJ_Cadastro', 'RazaoSocial_Cadastro'],
                   axis=1, inplace=True)

    resultado.rename(columns={'REG_ANS': 'RegistroANS'}, inplace=True)

    print("✅ Enriquecimento concluído\n")
    return resultado

# Funções para validação

def validar_cnpj(cnpj):
    """Valida formato e dígitos verificadores do CNPJ."""

    if pd.isna(cnpj):
        return False

    cnpj_str = str(cnpj).replace('.', '').replace(
        '/', '').replace('-', '').strip()

    if len(cnpj_str) != 14:
        return False

    if not cnpj_str.isdigit():
        return False

    if cnpj_str == cnpj_str[0] * 14:
        return False

    # Calcular primeiro dígito verificador
    soma = 0
    pesos = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
    for i in range(12):
        soma += int(cnpj_str[i]) * pesos[i]

    resto = soma % 11
    digito1 = 0 if resto < 2 else 11 - resto

    if int(cnpj_str[12]) != digito1:
        return False

    # Calcular segundo dígito verificador
    soma = 0
    pesos = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
    for i in range(13):
        soma += int(cnpj_str[i]) * pesos[i]

    resto = soma % 11
    digito2 = 0 if resto < 2 else 11 - resto

    if int(cnpj_str[13]) != digito2:
        return False

    return True


def validar_razao_social(razao):
    """Verifica se a razão social não está vazia."""
    if pd.isna(razao):
        return False

    razao_str = str(razao).strip()

    if razao_str == '' or razao_str.lower() == 'nan':
        return False

    return True


def aplicar_validacao(df):
    """Valida CNPJ e Razão Social."""
    print("🔍 Validação")

    df['FlagCNPJInvalido'] = ~df['CNPJ'].apply(validar_cnpj)
    cnpj_invalidos = df['FlagCNPJInvalido'].sum()
    print(f"  ⚠️  CNPJs inválidos: {cnpj_invalidos:,}")

    df['FlagRazaoSocialInvalida'] = ~df['RazaoSocial'].apply(
        validar_razao_social)
    razoes_invalidas = df['FlagRazaoSocialInvalida'].sum()
    print(f"  ⚠️  Razões inválidas: {razoes_invalidas:,}")

    print(f"  ⚠️  Valores suspeitos: {df['FlagValorSuspeito'].sum():,}")
    print(f"  ⚠️  Duplicatas: {df['FlagDuplicado'].sum():,}\n")

    return df


def salvar_validado(df):
    """Salva dados validados."""
    print("💾 Salvamento")

    df.to_csv(CAMINHO_VALIDADO, index=False)
    print(f"  ✅ {CAMINHO_VALIDADO}")

    validos = df[
        ~df['FlagCNPJInvalido'] &
        ~df['FlagRazaoSocialInvalida'] &
        ~df['FlagSemCadastro'] &
        ~df['FlagValorSuspeito'] &
        ~df['FlagDuplicado']
    ]

    print(
        f"  ✅ Registros 100% válidos: {len(validos):,} ({len(validos)/len(df)*100:.2f}%)\n")


def agregar_dados(df):
    """Agrupa dados por RazaoSocial e UF com múltiplas métricas."""
    print("📊 Agregação")

    df_limpo = df[~df['FlagSemCadastro']].copy()
    print(f"  ✅ {len(df_limpo):,} registros")

    agregado = df_limpo.groupby(['RazaoSocial', 'UF']).agg({
        'ValorDespesas': ['sum', 'mean', 'std', 'count']
    }).reset_index()

    agregado.columns = ['RazaoSocial', 'UF', 'TotalDespesas',
                        'MediaDespesas', 'DesvioPadrao', 'QtdRegistros']

    agregado = agregado.sort_values('TotalDespesas', ascending=False)

    print(f"  ✅ {len(agregado):,} grupos (Operadora + UF)\n")

    return agregado


def salvar_agregado(df):
    """Salva o resultado agregado."""
    caminho_saida = 'processados/despesas_agregadas.csv'
    df.to_csv(caminho_saida, index=False)
    print(f"\nArquivo agregado salvo: {caminho_saida}")

    print("RESUMO DA AGREGAÇÃO")
    print(f"Total de grupos (Operadora + UF): {len(df):,}")
    print(f"Total de despesas agregadas: R$ {df['TotalDespesas'].sum():,.2f}")

    print("\nTop 10 operadoras com maiores despesas totais:")
    print(df[['RazaoSocial', 'UF', 'TotalDespesas']].head(
        10).to_string(index=False))


def salvar_enriquecido(dados_enriquecidos):
    """Salva os dados enriquecidos."""
    print("Salvando resultado enriquecido...")

    dados_enriquecidos.to_csv(CAMINHO_ENRIQUECIDO, index=False)

    print("Conjunto de dados salvo em:", CAMINHO_ENRIQUECIDO)

    print("RESUMO:")
    print(f"Total de registros: {len(dados_enriquecidos):,}")
    print(f"Com cadastro: {(~dados_enriquecidos['FlagSemCadastro']).sum():,}")
    print(f"Sem cadastro: {(dados_enriquecidos['FlagSemCadastro']).sum():,}")


def compactar_resultados():
    """Compacta todos os arquivos processados em um ZIP."""
    import zipfile

    print("📦 Compactação")

    nome_zip = 'Teste_JessicaMachado.zip'

    arquivos = [
        'processados/dados_validados.csv',
        'processados/despesas_agregadas.csv'
    ]

    with zipfile.ZipFile(nome_zip, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for arquivo in arquivos:
            if os.path.exists(arquivo):
                zipf.write(arquivo, os.path.basename(arquivo))
                print(f"  ✅ {os.path.basename(arquivo)}")

    print(f"\n📁 {nome_zip}")


# Execução do script

def main():
    print("="*60)
    print("TESTE 2: TRANSFORMAÇÃO E VALIDAÇÃO DE DADOS")
    print("="*60 + "\n")

    criar_pastas()
    nome_arquivo = baixar_cadastro_ans()
    consolidado, cadastro = carregar_dados(nome_arquivo)
    enriquecido = enriquecer_dados(consolidado, cadastro)
    validado = aplicar_validacao(enriquecido)
    salvar_validado(validado)
    agregado = agregar_dados(validado)
    salvar_agregado(agregado)
    compactar_resultados()

    print("✅ PROCESSO CONCLUÍDO")

if __name__ == "__main__":
    main()
