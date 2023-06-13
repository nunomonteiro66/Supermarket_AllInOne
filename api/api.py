# app.py
from fastapi import FastAPI
from matplotlib.pyplot import get
from pydantic import BaseModel, Field
from scrapping_pesquisa import *
import uvicorn
from fastapi import Header
from typing import Optional
from typing import List, Union
from database import priceHistory
from database_product_search import comparacaoProdutos, getProdutoSearch

app = FastAPI()


#insere o nome do supermercado no inicio da lista
def insertName(nome,lista):
    new_dict = dict()
    new_dict['nomeSM']=nome
    new_dict['listaProdutos']=lista
    return [new_dict]


#informacoes adicionais sobre um produto
@app.get('/produto/')
async def returnItem(sm: Optional[str] = Header(None), item: Optional[str] = Header(None)):
    match sm:
        case 'continente':
            return continente_pagina(item)
        case 'miniPreco':
            return mini_preco_produto(item)
        case 'pingoDoce':
            return pingoDoce_pagina(item)
        case 'auchan':
            return auchan_pagina(item)
        case _:
            return "-1"

#sm-supermercado
@app.get("/home/")
async def read_item(sm: Optional[str] = Header(None), item: Optional[str] = Header(None), page: Optional[str] = Header(0)):
    page = int(page)
    page_f = page+10
    match sm:
        case 'continente':
            lista = insertName('continente',continente(item,page, page_f, filter="homePage"))
            lista = lista[page:page_f]
            return lista
        case 'intermarche':
            return insertName('intermarche', intermarche('arroz'))
        case 'pingoDoce':
            return insertName('pingoDoce',pingoDoce('', page, filter = "homePage"))
            
        case 'miniPreco':
            return insertName('miniPreco', miniPreco(item, page, filter="homePage"))
        case 'auchan':
            return insertName('auchan', auchan(item, page, 100, filter='homePage'))
        case _:
            return "-1"

#lista de supermercados vai estar dividida por "|"
@app.get("/search/")
async def getSearch(sm: Optional[str]=Header(None), item: Optional[str] = Header(None), page: Optional[str] = Header(0), pageF: Optional[str] = Header(0), filter: Optional[str] = Header(0)):
    #print("search")
    try:
        page_f = int(pageF)
    except: #nao foi fornecida pagina final
        page = int(page)
        page_f = page+10
    #print(page_f)
    sm_list = sm.split("|")
    lista_produtos = [] #lista de produtos a ser retornada
    
    for sm in sm_list:
        match sm:
            case 'continente':
                try:
                    #print(item, page, page_f, filter)
                    lista = continente(item,page, page_f, filter=filter)
                    lista_produtos = lista_produtos + lista
                except Exception as e:
                    #print("Error: ", e)
                    getProdutoSearch(item, sm)
            case 'intermarche':
                try:
                    lista =  intermarche(item)
                    lista_produtos = lista_produtos + lista
                except:
                    getProdutoSearch(item, sm)
            case 'pingoDoce':
                try:
                    lista =  pingoDoce(item, page, filter=filter)
                    lista_produtos = lista_produtos + lista
                except:
                    getProdutoSearch(item, sm)
            case 'miniPreco':
                try:
                    lista =  miniPreco(item, page, filter=filter)
                    lista_produtos = lista_produtos + lista
                except:
                    getProdutoSearch(item, sm)
            case 'auchan':
                try:
                    lista =  auchan(item, page, page_f, filter=filter)
                    lista_produtos = lista_produtos + lista
                except:
                    getProdutoSearch(item, sm)
            case _:
                pass
    
    #organiza a lista por ordem crescente de precos
    lista_produtos = sorted(lista_produtos, key=lambda d: d['preco'])

    
    return lista_produtos

    


#obtem um produto equivalente dos restantes supermercados
@app.get("/equivalent/")
async def getEquivalent(nome: Optional[str]=Header(None), quantidade: Optional[str]=Header('-1'), marca: Optional[str]=Header(None), preco: Optional[str]=Header(None), unidade: Optional[str]=Header(None)):
    produto = {
    'marca':marca,
    'quantidade':quantidade,
    'preco':float(preco),
    'nome': nome,
    'unidade': unidade       
    }

    termo_pesquisa = nome.split(" ")[0]
    #print(termo_pesquisa)

    #1ª pesquisar pelo produto, de modo a garantir que o pontencial produto se encontra na database
    await getSearch(sm='continente', item=termo_pesquisa, page=0, filter='low-to-high', pageF=100)
    await getSearch(sm='intermarche', item=termo_pesquisa, page=0, filter='low-to-high')
    await getSearch(sm='pingoDoce', item=termo_pesquisa, page=0, filter='low-to-high',pageF=100)
    await getSearch(sm='miniPreco', item=termo_pesquisa, page=0, filter='low-to-high')
    await getSearch(sm='auchan', item=termo_pesquisa, page=0, filter='low-to-high',pageF=100)

    lista = comparacaoProdutos(produto, ['continente', 'pingoDoce', 'auchan', 'miniPreco', 'intermarche'])
    return lista



@app.get("/price_history/")
async def getPriceHistory(link: Optional[str]=Header(None)):
    return priceHistory(link)