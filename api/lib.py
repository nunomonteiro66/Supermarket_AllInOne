import re
import requests
from asyncio.windows_events import NULL
from ctypes import sizeof
from importlib.resources import contents
from types import NoneType
from typing import Dict
from bs4 import BeautifulSoup as bs
import csv
from time import sleep
from dataclasses import dataclass
from html.parser import HTMLParser as hp
import json
from database import addProduto
from difflib import SequenceMatcher

# devolve o valor correspondente a uma tag, se esse valor estiver entre aspas
def getValueByTag(tag, html):
    try:
        if "=" not in tag:
            tag = tag+'="'

        html = html.split(tag)[1]
        html = html.split('"')[0]
        return html

    except:
        pass

# devolve o valor do desconto (float) e o tipo (str)

#extrai os valores e o tipo de desconto de um excerto de código de uma página
#do continente
def getValueDescontoContinente(desc):
    desc = desc.split('Desconto')[1]  # remove a palavra desconto
    desc = desc.split(':')
    tipo = desc[0].strip().strip()
    
    
    valor = float(desc[1].replace('%', '').replace('€', '').strip())
    #+valor = float(desc[1].replace('%', '').strip())
    
    return valor, tipo


# simplifica o preco:
# 1-remove o '€'
# 2-remove os espacos
# 3-retorna o preco em float
def simplifyPrice(preco):
    if ('€' in preco):
        preco = preco.replace('€', '')
    if(',' in preco):
        preco=preco.replace(',','.')
    return float(preco.strip())


# cria um dicionario com os dados da lista
#adiciona o produto a database (caso ainda nao tenha sido adicionado)
#caso ja tenha sido, atualiza o preco do produto (caso ainda nao tenha sido atualizado)
# devolve o dicionario criado
#ordem da lista: [nome, marca, quantidade, preco, preco_unidade, unidade, img, desconto{valor, tipo, preco_original}]
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

    

    addProduto(dicionario)

    return dicionario

# cria um dicionario com os dados da lista
# devolve o dicionario criado
#ordem da lista: [valor, tipo, preco_original]
def dicionarioDesconto(lista):
    dict_desc = dict()
    dict_desc['valor'] = lista[0]
    dict_desc['tipo'] = lista[1].strip()
    dict_desc['preco_original'] = lista[2]
    return dict_desc

# calcula a percentagem do desconto, dado o preco original e final
def calculoDesconto(inicial, final):
    return int(((inicial-final)/inicial)*100)

#extrai o preco de um excerto de código de uma página
def miniprecoGetUnidadePreco(preco):
    preco = preco.replace('(','').replace(')','').replace(',','.')
    preco = preco.split("€/")
    return float(preco[0].strip()), preco[1].strip()
    
    

#verifica se existe um numero na string 'text
#retorna esse numero caso exista, senao retorna -1
def numberInString(text):
    num = '-1'
    for i in text:
        if i.isnumeric():
            if(num == '-1'):
                num = i
            else:
                num = num + i
    return int(num)



#escreve a lista de produtos (dicionarios) para um ficheiro json (name default: response)
def writeJson(lista):    
    with open('response.json','w') as file:
        file.write(json.dumps(lista))


#remove as letras e espacos e retorna a string com apenas os numeros
def onlyNumbers(string):
    try:
        return re.findall(r"[-+]?(?:\d*\.\d+|\d+)", string)[0]
    except:
        return string
    
def criarDicionarioPagina(info_adicional, info_nutricional):
    dict_info = dict()
    dict_info['info_adicional']=info_adicional
    dict_info['info_nutricional']=info_nutricional
    return [dict_info]      



def getGeneralMeasure(quantidade_u_m):
    if(quantidade_u_m.lower() == 'kg' or quantidade_u_m.lower() == 'g'):
            return'kg'
    elif(quantidade_u_m.lower() == 'cl' or quantidade_u_m.lower() == 'ml' or quantidade_u_m.lower() == 'l'):
        return 'l'
    else:
        return ''



def calculoPrecoQuantidade(preco, quantidade, unidade):
    #print(preco, quantidade, unidade)
    preco = float(preco)
    
    #verifica (e converte) caso a quantidade seja composta por varios artigos (p.e varias garrafas de agua)
    if ('x' in str(quantidade)):
        quantidade = quantidade.split('x')
        quantidade = float(quantidade[0])*float(quantidade[1])
    elif ('+' in str(quantidade)):
        quantidade = quantidade.split('+')
        quantidade = float(quantidade[0])*float(quantidade[1])
    quantidade = float(quantidade)
    
    #converte para a medida geral
    if(unidade.lower() == 'g' or unidade.lower() == 'ml'):
        quantidade = (quantidade/1000)
    elif(unidade.lower() == 'cl'):
        quantidade = (quantidade/100)
    

    pq = (preco/quantidade)
    return float("{0:.2f}".format(pq))



def checkEquivalence(word1, word2):
    return SequenceMatcher(None, word1, word2).ratio()

