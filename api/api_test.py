from fastapi import Query
import requests
from requests.structures import CaseInsensitiveDict


from bs4 import BeautifulSoup as bs
from compareSM import compare_produtos
from lib import print_dict

from scrapping_pesquisa import auchan, continente, intermarche, mini_preco_produto, miniPreco, pingoDoce, pingoDoce_pagina
import database

    
database.createConnection()
print(intermarche('arroz'))

exit()

produto = {'quantidade': 27.5, 
           'marca': -1,
           'nome': 'vodka ice'
           }

for p in pingoDoce('vodka ice', '0'):
    print(p['quantidade'])
    
for p in auchan('vodka ice', '0', '30'):
    print(p['quantidade'])
    
for p in continente('vodka ice', '0', '30'):
    print(p['quantidade'])

compare_produtos(produto)

exit()

print(miniPreco('arroz agulha'))
exit()

strl = "asd34dsf4 45 grfg 5"

filter(str.isdigit, strl)

s=''.join(i for i in strl if i.isdigit())
print(s)

exit()

continentel = continente('arroz', '0', '10')
print(continentel)


headers = {
    'item': 'arroz',
    'sm': 'continente',
    'page': '1'
}

params = ["arroz"]

response = requests.get("https://mercadao.pt/api/catalogues/6107d28d72939a003ff6bf51/products/search",params=params)



print(len(response.content))