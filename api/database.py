from venv import create
from matplotlib.pyplot import connect
import mysql.connector 
from datetime import datetime

connection = None

#conecta ao banco de dados
def createConnection():
    global connection
    connection = mysql.connector.connect(host='localhost',
                                         database='comparador_precos',
                                         user='root',
                                         password='1234')

#############################################################################################################################    
#tabela Produtos
#############################################################################################################################

#adiciona o produto a database   
def addProduto(produto):
    #print("adicionar produto na database: {} {}".format(produto['nomeSM'], produto['link']))
    id = checkProdutoLink(produto['link'])
    if(id != -1): #o produto ja existe
        #print("o produto ja existe")
        updatePrice(id, produto) #apenas tenta atualizar o preco
        return


    cursor = connection.cursor()
    if(produto['desconto'] == 0):
        sqlCommand = """insert into produtos (Nome, Marca, Quantidade, Preco, Preco_unidade, Unidade, Link_img, NomeSupermercado, Link)
                    values ("{}","{}","{}",{},{},"{}","{}","{}", "{}")""".format(produto['nome'],produto['marca'],produto['quantidade'],produto['preco'],produto['preco_unidade'],produto['quantidade_u_m'],produto['img'],produto['nomeSM'], produto['link'])
    else:
        sqlCommand = """insert into produtos (Nome, Marca, Quantidade, Preco, Preco_unidade, Unidade, Link_img, NomeSupermercado, Link, Preco_original, Valor_desconto)
                    values ("{}","{}","{}",{},{},"{}","{}","{}", "{}", {}, {})""".format(produto['nome'],produto['marca'],produto['quantidade'],produto['preco'],produto['preco_unidade'],produto['quantidade_u_m'],produto['img'],produto['nomeSM'], produto['link'], produto['desconto']['preco_original'], produto['desconto']['preco_original'])
    

    #print("sqlcommand: ", sqlCommand)

    cursor.execute(sqlCommand)
    connection.commit()

    id = checkProdutoLink(produto['link']) #obtem o id do produto
    updatePrice(id,produto) #atualiza o preco do produto




#verifica se o produto ja existe atraves do link na database e retorna o id caso exista
def checkProdutoLink(link):
    cursors = connection.cursor()
    sqlCommand = """select * from produtos where link='{}' """.format(link)
    cursors.execute(sqlCommand)
    result = cursors.fetchall()
    
    if(len(result) == 0): #produto ainda nao existe
        return -1

    return result[0][0] #id


#############################################################################################################################    
#tabela Precos
#############################################################################################################################


#verifica se o preco do produto ja foi atualizado hoje
def checkDate(id):
    data_hoje = datetime.today().strftime('%Y-%m-%d')
    cursor = connection.cursor()
    sqlCommand = """select * from precos where idProduto={} and data='{}'""".format(id, data_hoje)
    cursor.execute(sqlCommand)
    result = cursor.fetchall()

    if(len(result) == 0): #este produto tem o preco desatualizado
        return False
    return True #o produto esta atualizado


#atualiza o preco de hoje na tabela precos, caso ainda nao tenha sido atualizado
def updatePrice(id,produto):
    preco_atual = produto['preco']
    if(checkDate(id) == False): #o produto ainda nao esta atualizado
        addPrecos(id, preco_atual)

#adiciona o preco do produto e a data de hoje na tabela "Precos"
def addPrecos(id, preco):
    data_hoje = datetime.today().strftime('%Y-%m-%d')
    cursor = connection.cursor()
    sqlCommand = """insert into precos (idProduto, Preco, data) values ({},{},'{}')""".format(id, preco, data_hoje)
    cursor.execute(sqlCommand)
    connection.commit()

    sqlcommand = """update produtos set Preco={} where id={}""".format(preco, id)
    cursor.execute(sqlCommand)
    connection.commit()



#retorna o histórico de precos do produto dado pelo link
def priceHistory(link):
    id = checkProdutoLink(link)
    if(id == -1):
        return -1
    cursor = connection.cursor()
    #print(id)
    sqlCommand = """select * from precos where idProduto={}""".format(id)
    cursor.execute(sqlCommand)
    result = cursor.fetchall()
    #print(result)
    return result


