from distutils.command.build import build
from sre_constants import JUMP
import database, lib

#cria um dicionario com os dados do produto, mas sem o adicionar a database
def criarDicionario(lista):
    dicionario = dict()
    dicionario['nome'] = lista[0].strip()
    dicionario['marca'] = lista[1].strip()
    dicionario['quantidade'] = str(lista[2]).strip()
    try:
        dicionario['preco'] = lista[3].replace(',', '.')
    except:
        dicionario['preco'] = lista[3]
    try:
        dicionario['preco_unidade'] = lista[4].replace(',','.')
    except:
        dicionario['preco_unidade'] = lista[4]
    dicionario['unidade'] = lista[5].strip()
    dicionario['img'] = lista[6].strip()
    dicionario['desconto'] = lista[7]
    dicionario['link'] = lista[8].strip()
    dicionario['nomeSM'] = lista[9].strip()
    dicionario['quantidade_u_m'] = lista[10].strip()

    return dicionario


#backup caso nao seja possivel extrair produtos do site
#procura por nomes que correspondam a pesquisa
def getProdutoSearch(pesquisa, sm):
    listaProdutos = []
    #pesquisa = pesquisa.split()[0]
    
    cursor = database.connection.cursor()
    sqlCommand = """select * from produtos where NomeSupermercado = '{}'""".format(sm)
    cursor.execute(sqlCommand)
    result = cursor.fetchall()
    produto = []

    for i in result:
        #print(i[1], i[8])
        #if (pesquisa in i[1].lower()): #produto encontrado
        if(lib.checkEquivalence(pesquisa, i[1].lower()) >= 0.5):
            produto = buildProductFromDatabase(i)
            listaProdutos.append(produto)
 
    return listaProdutos


#verifica se o produto tem desconto, e se tiver, constroi o dicionario do desconto
#devolve o produto em formato dicionario, atraves dos dados da database (lista produto)
def buildProductFromDatabase(produto):
    if(produto[-1] != None):
        desconto = lib.dicionarioDesconto([produto[-1],'', produto[-2]])
    else:
        desconto = 0
    return criarDicionario([produto[1], produto[2],produto[3],produto[4],produto[5],produto[6],produto[7],desconto,produto[9],produto[8], produto[6]])


#procura na database por produtos que correspondam ao produto indicado
def comparacaoProdutos(produto_base, listaSM):
    #print("comparacao")
    cursor = database.connection.cursor()

    lista_produtos = []

    print(produto_base)
    
    #para cada supermercado
    for SM in listaSM:
        #procura na database pelo produto do supermercado, e pela quantidade (tem que ser igual a quantidade do produto base)
        sqlcommand = """select * from produtos where NomeSupermercado = '{}' and quantidade={} and unidade='{}'""".format(SM, produto_base['quantidade'], produto_base['unidade'])
        cursor.execute(sqlcommand)
        result = cursor.fetchall()
        
        #nao foi encontrado nenhum produto valido, saltar para outro SM
        if(len(result) == 0): continue 
        
        #so foi devolvido um resultado, pelo que é este que vai ser devolvido
        if(len(result) == 0): 
            lista_produtos.append(buildProductFromDatabase(result))
            continue

        #foi encontrado mais de um produto, entao tem que ser feita a comparacao
        #1º converter os produtos em dicionarios
        tmp_lista = []
        for p in result: 
            tmp_lista.append(buildProductFromDatabase(p))
        
    

        #2º organizar por preco
        tmp_lista.sort(key=lambda x: x['preco'])
        
        #3º comparar os produtos (compatibilidade do texto)
        statistic = []
        for p in tmp_lista: statistic.append(lib.checkEquivalence(produto_base['nome'], p['nome']))
        
        #4º encontrar o produto com maior compatibilidade, e adiciona-lo a lista
        max_index = statistic.index(max(statistic))
        lista_produtos.append(tmp_lista[max_index])
    return lista_produtos

