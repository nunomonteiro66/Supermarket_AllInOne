from csv import list_dialects
from traceback import print_list
from turtle import end_fill

from matplotlib.font_manager import list_fonts
from lib import *



#informacao adicional e informacao nutricional
def continente_pagina(html):
    
    #informacao adicional
    page = requests.get(html)
    soup = bs(page.content, 'html.parser')

    subsoup = soup.find('div',class_="col-12 product-description ct-pdp--description-wrapper").find('div',class_='col-sm-8 col-md-9 tabContainer tab-row-details')
    
    page=list(bs(str(subsoup),'html.parser').findAll(text=True))
    
    page = [elem.strip() for elem in page if elem != '\n']
    
    info_adicional = ("\n".join(page))
    #---------------------------------------------------
    
    
    #informacao nutricional
    page = requests.get(html)
    soup = bs(page.content, 'html.parser')

    #pagina com as informacoes nutricionais
    nutricional_page = str(soup.find('a', class_='js-details-header js-nutritional-tab-anchor d-none')['data-url'])
    
    nutricional_page = requests.get(nutricional_page)
    nutricional_page = list(bs(nutricional_page.content, 'html.parser').findAll(text=True,recursive=True))
   
    nutricional_info = '\n'.join([elem for elem in nutricional_page if elem != '\n'])
    
    
    return criarDicionarioPagina(info_adicional, nutricional_info)

# pesquisa - o elemento a pesquisar (arroz, massa,...)
# initial/end - a range de produtos a devolver (0-24,25-50,...)
# retorna uma lista de dicionarios, sendo cada dicionario um produto
def continente(pesquisa, initial, end, filter="relevance"):
    # codigo html da pagina toda
    match filter:
        case 'relevance':
            html = "https://www.continente.pt/on/demandware.store/Sites-continente-Site/default/Search-UpdateGrid?pmin=0.01&q={pesquisa}&srule=Continente&start={initial}&sz={end}".format(pesquisa=pesquisa, initial=initial, end=end)
        case 'low-to-high':
            html = "https://www.continente.pt/on/demandware.store/Sites-continente-Site/default/Search-UpdateGrid?cgid=col-produtos&q={pesquisa}&pmin=0%2e01&srule=price-low-to-high&start={initial}&sz={end}".format(pesquisa=pesquisa, initial=initial, end=end)
        case 'high-to-low':
            html = "https://www.continente.pt/on/demandware.store/Sites-continente-Site/default/Search-UpdateGrid?cgid=col-produtos&q={pesquisa}&pmin=0%2e01&srule=price-high-to-low&start={initial}&sz={end}".format(pesquisa=pesquisa, initial=initial, end=end)
        case 'a-to-z':
            html = "https://www.continente.pt/on/demandware.store/Sites-continente-Site/default/Search-UpdateGrid?cgid=col-produtos&q={pesquisa}&pmin=0%2e01&srule=product-name-ascending&start={initial}&sz={end}".format(pesquisa=pesquisa, initial=initial, end=end)
        case 'homePage':
            html = "https://www.continente.pt/on/demandware.store/Sites-continente-Site/default/Search-UpdateGrid?cgid=col-produtos&pmin=0%2e01&prefn1=isPromo&prefv1=true&start=36&sz=36"
    
    print(html)
    page = requests.get(html)
    soup = bs(page.content, 'html.parser')

    # obtem uma lista dos produtos todos (html)
    produtos = list(soup.find_all(
        'div', class_='col-12 col-sm-3 col-lg-2 productTile'))


    # lista com os dicionarios relativos a cada produto
    lista_produtos = []

    
    i=0
    for produto in produtos:
        try:
            i=i+1
            # nova soup com apenas o codigo do produto em questao
            soup = bs(str(produto), 'html.parser')
            # desconto
            try:
                # linha com o tipo e valor do desconto
                desc = (soup.find('img', class_='img-fluid lazyload hidden'))
                desc = (desc['title'])
            
                # obtem o tipo e o valor do desconto, em variaveis separadas
                valor_desc, tipo_desc = getValueDescontoContinente(desc)
            
                # preco original sem o desconto
                html_text = soup.find('span', class_='value ct-tile--price-value')
                preco_original = (html_text.contents[2].strip().split("€")[1])
                preco_original = float(preco_original.replace(',', '.'))

                # cria um dicionario com os valores
                values = [valor_desc, tipo_desc, preco_original]
                dict_desc = dicionarioDesconto(values)

            except Exception as e:  # produto nao tem desconto
                dict_desc = 0

            # link da imagem, nome do artigo e link para o artigo
            html_text = soup.find('div', class_='ct-image-container col-4 col-sm')
            #print(html_text)
            html_text = str((html_text.contents[1]))
            img = getValueByTag("data-src", html_text)
        
            img = img.split("?") #apos o '?' fica apenas as dimensões da imagem
            img[1] = img[1].replace("280", "2000") #aumenta o tamanho da imagem (sem perder a qualidade)
            img = "?".join(img)
        
        
            nome = getValueByTag("title", html_text)
            link = getValueByTag("href",html_text)

        

            # marca
            html_text = soup.find('p', class_="ct-tile--brand")
            try:
                marca = str(html_text.contents[0])
            except:
                marca = ""
            # quantidade e quantidade_u_m
            try:
                html_text = soup.find('p', class_="ct-tile--quantity")
                quant = str(html_text.contents[0])
                quant = quant.split(" ")
                quant_u_m = quant[-1]
                quant.remove(quant_u_m)
                if('emb.' in quant):
                    quant.remove('emb.')
                quant = "".join(quant)
        
                quant= onlyNumbers(quant)
                if("(" in quant_u_m):
                    quant_u_m = quant_u_m.replace("(", "")
                if(")" in quant_u_m):
                    quant_u_m = quant_u_m.replace(")", "")
            except Exception as e:
                quant = ''
                quant_u_m = ''
            # preco por u.m (kg,l,...)
            html_text = soup.find('span', class_="ct-price-value")
            preco_un = (html_text.contents[0].strip().split('€')[1])

            # tipo de u.m (kg,l,...)
            html_text = list(soup.find_all('span', class_='pwc-m-unit'))[1]
            um = str((html_text.contents[0].strip()).split('/')[1])

            # preco
            html_text = soup.find('span', class_='value')
            preco = float(html_text['content'])

        
            # criar um dicionario com os dados
            values = [nome, marca, quant, preco, preco_un, um, img, dict_desc, link, 'continente', quant_u_m]
            #print(quant_u_m)
            dicionario = criarDicionario(values)
            # adiciona à lista de produtos
            lista_produtos.append(dicionario)
        except Exception as e:
            print(e)


        
    return lista_produtos



def intermarche(pesquisa):
    # codigo html da pagina toda
    html = "https://lojaonline.intermarche.pt/26-famoes/produit/recherche?mot={pesquisa}".format(
        pesquisa=pesquisa)
    page = requests.get(html)
    soup = bs(page.content, 'html.parser')
    


    # parte da pagina apenas referente aos produtos (lista de todos)
    soup_all = (
        soup.find('div', class_='content_vignettes js-vignette_recherche'))
    soup_all = list(soup_all.find_all(
        'li', class_='vignette_produit_info js-vignette_produit'))

    lista_produtos = []

    for soup in soup_all:

        # verifica se o produto esta disponivel
        non = soup.find('div', class_="vignette_non_dispo")
        if(non != None):  # salta o produto
            continue

        # produto atual
        soup = bs(str(soup), 'html.parser')

        #img (top)
        soup_top = soup.find(
            'div', class_="vignette_img transition js-ouvrir_fiche")
        #soup_top = bs(str(soup_top),'html.parser')

        try:
            img = soup_top.find('img')['src']
        except:
            img = soup_top.find('img')['data-original']

        #marca, nome, quantidade (medio)
        soup_medio = bs(
            str(soup.find('div', class_="vignette_info")), 'html.parser')
        soup_medio_list = soup_medio.find_all('p')
        marca = soup_medio_list[0].contents[0].strip()
        nome = soup_medio_list[1].contents[0].strip()
        try:
            quantidade = soup_medio.find('span').contents[0].strip()
            quantidade=onlyNumbers(quantidade)
        except:
            quantidade = 0
    

        #preco, preco_original, preco_u_m, u_m (low)
        soup_low = bs(
            str(soup.find('div', class_="vignette_prix inline")), "html.parser")
        preco_original = soup_low.find('del').contents

        soup_low_list = list(soup_low.find_all('p'))
        preco = simplifyPrice(soup_low_list[0].contents[0])

        soup_low_elem = soup_low_list[1].contents[0].strip().split("/")
        preco_un = simplifyPrice(soup_low_elem[0])
        u_m = soup_low_elem[1]

        if(len(preco_original) != 0):
            preco_original = simplifyPrice(preco_original[0])
        else:
            preco_original = preco

        #valor_desconto, tipo_desconto (calculo)
        if(preco_original != preco):
            valor_desc = calculoDesconto(preco_original, preco)
            tipo = 'imediato'

            # construcao do dicionario do desconto
            values = [valor_desc, tipo, preco_original]
            dict_desc = dicionarioDesconto(values)
        else:
            dict_desc = NULL

        # construir dicionario e adicionar a lista
        values = [nome, marca, quantidade,
                  preco, preco_un, u_m, img, dict_desc,img, 'intermarche',u_m]
        lista_produtos.append(criarDicionario(values))

    return lista_produtos



def pingoDoce_pagina(html):
    response = requests.get(html)
    response = response.json()
    
    info_adicional = response['additionalInfo']
    
    try:
        nome_fornecedor = response['nutritionalInfo']['InformationProviderName']
        end_fornecedor = response['nutritionalInfo']['ContactAddress'][0]['Value']
    
        info_nutricional = "\n".join((nome_fornecedor, end_fornecedor))
    except:
        info_nutricional = "Informação brevemente disponivel"
        
    dict_info = dict()
    dict_info['info_adicional']=info_adicional
    dict_info['info_nutricional']=info_nutricional
    return [dict_info]           
        


def pingoDoce(pesquisa, page, filter = "relevance"):
    #https://mercadao.pt/api/catalogues/6107d28d72939a003ff6bf51/products/search?query=%5B%22massa%22%5D&filter=%7B%22from%22:0,%22sort%22:0,%22size%22:10,%22esPreference%22:0.45257131604182566%7D
    match filter:
        case 'relevance':
            url="https://mercadao.pt/api/catalogues/6107d28d72939a003ff6bf51/products/search?query=%5B%22{pesquisa}%22%5D&filter=%7B%22from%22:{page},%22sort%22:0,%22size%22:10,%22esPreference%22:0.45257131604182566%7D".format(pesquisa=pesquisa, page=page)
        case 'high-to-low':
            url = "https://mercadao.pt/api/catalogues/6107d28d72939a003ff6bf51/products/search?query=%5B%22{pesquisa}%22%%5D&filter=%7B%22from%22:{page},%22sort%22:%7B%22buyingPrice%22:%22desc%22%7D,%22size%22:10,%22esPreference%22:0.5924943676675563%7D".format(pesquisa=pesquisa, page=page)
        case 'low-to-high':
            url = "https://mercadao.pt/api/catalogues/6107d28d72939a003ff6bf51/products/search?query=%5B%22{pesquisa}%22%5D&filter=%7B%22from%22:{page},%22sort%22:%7B%22buyingPrice%22:%22asc%22%7D,%22size%22:100,%22esPreference%22:0.8036429269732681%7D".format(pesquisa=pesquisa, page=page)
        case 'a-to-z':
            url = "https://mercadao.pt/api/catalogues/6107d28d72939a003ff6bf51/products/search?query=%5B%22{pesquisa}%22%5D&filter=%7B%22from%22:{page},%22sort%22:%7B%22shortDescription.raw%22:%22asc%22%7D,%22size%22:10,%22esPreference%22:0.5924943676675563%7D".format(pesquisa=pesquisa, page=page)
        case 'homePage':
            url = "https://mercadao.pt/api/catalogues/6107d28d72939a003ff6bf51/products/search?query=%5B%22%22%5D&filter=%7B%22from%22:{page},%22sort%22:%7B%22shortDescription.raw%22:%22asc%22%7D,%22size%22:10,%22esPreference%22:0.5924943676675563%7D".format(page=page)



    response = requests.get(url)
    response = response.json()

   
  

    dicti = dict(response['sections'][pesquisa])
    dicti = dicti['products']

    
    

    lista_produtos = []
    index = 0
    for i in dicti:
        link = "https://mercadao.pt/api/catalogues/" + response['sections'][pesquisa]['products'][index]['_source']['catalogueId'] + "/product/" + response['sections'][pesquisa]['products'][index]['_source']['slug']
        index=index+1
        
        nome = i['_source']['firstName']
        price_original = float(i['_source']['regularPrice'])
        price_original = float("{:.2f}".format(price_original))
        price = float(i['_source']['buyingPrice'])
        price = float("{:.2f}".format(price))
        #unitPrice = float(i['_source']['unitPrice'])
        #unitPrice = float("{:.2f}".format(unitPrice))
        capacidade = str(i['_source']['capacity'])
     
       
        capacidade = capacidade.split(" ")
        if(len(capacidade)==1): #se não tiver unidade de medida
            quantidade_u_m = ""
            capacidade = capacidade[0]
        else:
            quantidade_u_m = capacidade[-1]
            capacidade = capacidade[-2]
        
        
        promocao = (i['_source']['promotion'])
     
        if(promocao is not None and promocao['amount'] is not None):
            promocao=float(promocao['amount'])
            tipo = "imediato"
            desconto = dicionarioDesconto([promocao, tipo, price_original])
        else:
            desconto = 0
        marca = i['_source']['brand']['name']
        img = "https://res.cloudinary.com/fonte-online/image/upload/c_fill,h_600,q_auto,w_600/v1/PDO_PROD/"+i['_source']['sku']+"_1"
        
        
        try:
            nome = nome.replace(marca,"").strip()
        except:
            pass
        
        
        

        #preco por unidade e unidade_geral (kg, l, ...)
        
        if(capacidade != ""):
            unitPrice = calculoPrecoQuantidade(price, capacidade, quantidade_u_m)
        else:
            unitPrice = price
        
        unit = getGeneralMeasure(quantidade_u_m)

        lista = [nome, marca, capacidade, price, unitPrice, unit, img, desconto, link, 'pingoDoce', quantidade_u_m]
       
        dicti = criarDicionario(lista)
      
        lista_produtos.append(dicti)
        
        
    return lista_produtos



def mini_preco_produto(link):
    page = requests.get(link)
    soup = bs(page.content,'html.parser')
    soup2 = soup.find('div',class_="product-detail-page container-center")
    soup2 = soup2.find('div', {"id": "nutritionalinformation"})
   
    criarDicionarioPagina(soup2.text, soup2.text)

    
    soup2 = soup2.split("\n")
    #soup = soup.remove("")
    #page = [elem.strip() for elem in soup if elem != '\n']
    
    lista = []
    for i in soup2:
        if(i != '' and i != ' '):
            lista.append(i)
    
    
    new_str = ""
    for i in range(4,len(lista)):
        new_str = new_str + ": "+lista[i] +"\n"
        
    soup3 = soup.findAll("div",class_="form_field-label")
     
    new_text = ""
    for i in soup3:
        new_text = new_text + i.text.strip()
    
    
    return criarDicionarioPagina(new_text, new_str)

       

def miniPreco(pesquisa,page,filter="relevance"):
    match filter:
        case 'relevance':
            html = "https://www.minipreco.pt/search?q={pesquisa}%3Arelevance&page={page}&disp=".format(pesquisa=pesquisa, page=page)
        case 'high-to-low':
            html = "https://www.minipreco.pt/search?q={pesquisa}%3Aprice-desc&page={page}&disp=".format(pesquisa=pesquisa, page=page)
        case 'low-to-high':
            html = "https://www.minipreco.pt/search?q={pesquisa}%3Aprice-asc&page={page}&disp=".format(pesquisa=pesquisa, page=page)
        case 'a-to-z':
            html = "https://www.minipreco.pt/search?q={pesquisa}%3Aname-asc&page={page}&disp=".format(pesquisa=pesquisa, page=page)
        case 'homePage':
            html = "https://www.minipreco.pt/search?q=%3Arelevance&page={page}&disp=".format(page=page)
    page = requests.get(html)
    soup = bs(page.content, 'html.parser')
    link = "https://lojaonline.minipreco.pt/" + soup.find('a', class_='productMainLink')['href']
    soup = soup.find_all('div', class_="prod_grid")
    
  
    
    soup.pop(-1) #ultimo elemento nao conta
    
    lista_produtos = []
    
    for produto in soup:
        img = produto.find('img',class_='lazy')
        img = img['data-original']
        
        
        #nota: marca, nome e quantiade estão na mesma linha, logo é necessário separar
        #marca
        text = produto.find('span', class_='details') #nome com a marca e a unidade_medida
        text = (text.contents[0].strip())
        text = text.split(" ") #separa a string por espaços

        unidade_medida = text[-1] #pega a unidade_medida

        marca = '' #ha produtos sem marca, logo vazio por default
        for subtext in text:
            if(subtext.isupper()): # marcas comecam sempre por letra maiuscula
                marca=marca+' '+subtext
                text.remove(subtext)
        marca.strip() #remove espaços a mais
        
        
        #quantidade
        if(len(text)>2): #existem produtos sem quantidade definida
            quantidade = text[-2]+' '+text[-1]
            text.pop(-1)
            text.pop(-1)
            
            quantidade=onlyNumbers(quantidade)
            if (any(char.isdigit() for char in quantidade)):
                pass
            else:
                quantidade = '0'
           
        else:
            quantidade = ''
        
        #nome
        nome = ' '.join(text)
        
        #preco
        price = produto.find('p', class_='price')
        price = simplifyPrice(price.contents[-1])
  
        
        #preco por unidade
        preco_unidade = produto.find('p', class_='pricePerKilogram')
        preco_unidade, unidade = miniprecoGetUnidadePreco(preco_unidade.contents[-1])
       
       
        #img
        img = produto.find('img', class_='lazy')['data-original']
        
       
        try:
            #desconto
            desc = produto.find('span', class_='promotion_text')        
            if(desc is not None): #produto está em desconto
                desc = int(desc.contents[0].replace('%','').replace('-',''))
                preco_original = price / (1-(desc/100))
                preco_original = round(preco_original,2)
                desc_values = [desc, 'imediato', preco_original]
                desconto_dict = dicionarioDesconto(desc_values)
            else:
                desconto_dict = 0
        
        except:
            desconto_dict = 0
        
        
        
        #construir dicionario
        #print(unidade)
        values = [nome, marca, quantidade, price, preco_unidade, unidade, img, desconto_dict, link, 'miniPreco', unidade_medida]
        
        lista_produtos.append(criarDicionario(values))
            
    return lista_produtos



#devido ao modeo deficiente de como o site esta feito, é necessario obter uma lista de marcas, de modo a extrair estas do nome dos artigos
def auchan_lista_marcas(soup):
    soup = list(soup.find_all('div',class_='auc-search__accordion-body auc-search__filters-body auc-accordion-filters card-body content value'))
    
    soup = list(soup[-1].find_all('span',class_=''))
    
    lista_marcas = []
    
    for i in soup:
        lista_marcas.append(i.contents[0].strip().lower())
    return lista_marcas


def auchan2(pesquisa):
    html = "https://www.auchan.pt/pt/pesquisa?q={pesquisa}&search-button=&lang=null".format(pesquisa=pesquisa)
    
    page = requests.get(html)
    soup = bs(page.content,'html.parser')
    
    lista_marcas = auchan_lista_marcas(soup)

    
    soup = list(soup.find_all('div',class_='product-tile auc-product-tile auc-js-product-tile')) #lista com o codigo relativo a cada produto    
    lista_produtos = []
    for produto in soup:
        subsoup = bs(str(produto),'html.parser')
        
        #link
        link = "https://www.auchan.pt/" + (subsoup.find('a')['href'])
        
        #img
        img = subsoup.find('source',media_='')['data-srcset']
        img=img.split('?')[0]

        #nome (nota: nome ainda nao formatado (ou seja, ainda tem a quantidade e u_m))
        nome = subsoup.find('div', class_='auc-product-tile__name')
        nome = subsoup.find('a',class_='link').contents[0]
        
        
        #marca
        marca = ""
        for marcas in lista_marcas:
            if marcas in nome:
                marca = marcas
                nome = nome.replace(marca, '').strip()
                break
            
        #quantiade e u_m
        subtext = nome.split(" ")[-1]
        quantidade = ''
        if any(char.isnumeric() for char in subtext): #verifica que a palavra tem numeros
            for c in subtext:
                if(c.isnumeric() or c=='x'): #acrescenta o numero ou x à quantidade, e remove da palavra
                    quantidade = quantidade + c
                    subtext = subtext.replace(c,'') #retira do subtext
        subtext=subtext.strip() #subtext = u_m (quantidade retirada)            
        
        #retirar a quantidade e u_m do nome (bem como os duplos espaços)
        nome = nome.replace(quantidade, "")
        nome = nome.replace(subtext,"")
        nome = nome.replace("  "," ")
        
        #preco
        preco = subsoup.find('span',class_='sales')
        preco = bs(str(preco),'html.parser')
        preco = float(preco.find('span',class_='value')['content'])
        
        #desconto
        desc = subsoup.find('span',class_='strike-through list')
        desc = bs(str(desc),'html.parser')
        desc = desc.find('span',class_='value')
        if(desc != None): #produto esta em desconto
            preco_original = float(desc['content'])
            valor = calculoDesconto(preco_original,preco)
            tipo = 'imediato'
            valores = [valor, tipo, preco_original]
            desc = dicionarioDesconto(valores)
        else:
            desc = None


        #preco p\u.m
        preco_u_m = subsoup.find('span', class_='auc-measures--price-per-unit')
        if(preco_u_m != None):
            preco_u_m = preco_u_m.contents[0]
            preco_u_m = simplifyPrice(preco_u_m.split('/')[0])
        else:
            preco_u_m = -1
        
        valores = [nome, marca, quantidade, preco, preco_u_m, subtext, img, desc, link, 'auchan']
        lista_produtos.append(criarDicionario(valores))
        
    return lista_produtos


def auchan_pagina(html):
    response = requests.get(html)
    response = response.json()
    
    sub_dict = response['product']['attributes'][0]['attributes']
    
    info_nutricional = sub_dict[0]['value'][0]
    
    del sub_dict[0]
    
    
    info_adicional = ""
    for dic in sub_dict:
        info_adicional += dic['label'] +": "+ dic['value'][0]+"\n"

    return criarDicionarioPagina(info_adicional, info_nutricional)
    
    
    
    
    
    

def auchan(pesquisa, initial, end, filter="relevance"):
    #https://www.auchan.pt/on/demandware.store/Sites-AuchanPT-Site/pt_PT/Search-UpdateGrid?prefn1=soldInStores&prefv1=000&q=arroz&srule=availability-descending-000&start=0&sz=10
    match filter:
        case 'relevance':
            html = "https://www.auchan.pt/on/demandware.store/Sites-AuchanPT-Site/pt_PT/Search-UpdateGrid?prefn1=soldInStores&prefv1=000&q={pesquisa}&srule=availability-descending-000&start={initial}&sz={end}".format(pesquisa=pesquisa, initial=initial, end=end)
        case 'low-to-high':
            html = "https://www.auchan.pt/on/demandware.store/Sites-AuchanPT-Site/pt_PT/Search-UpdateGrid?prefn1=soldInStores&prefv1=000&q={pesquisa}&srule=price-low-to-high&start={initial}&sz={end}".format(pesquisa=pesquisa, initial=initial, end=end)
        case 'high-to-low':
            html = "https://www.auchan.pt/on/demandware.store/Sites-AuchanPT-Site/pt_PT/Search-UpdateGrid?prefn1=soldInStores&prefv1=000&q={pesquisa}&srule=price-high-to-low&start={initial}&sz={end}".format(pesquisa=pesquisa, initial=initial, end=end)
        case 'a-to-z':
            html = "https://www.auchan.pt/on/demandware.store/Sites-AuchanPT-Site/pt_PT/Search-UpdateGrid?prefn1=soldInStores&prefv1=000&q={pesquisa}&srule=product-name-ascending&start={initial}&sz={end}".format(pesquisa=pesquisa, initial=initial, end=end)
        case 'homePage':
            html = "https://www.auchan.pt/on/demandware.store/Sites-AuchanPT-Site/pt_PT/Search-UpdateGrid?prefn1=soldInStores&prefv1=000&q=&srule=availability-descending-000&start={initial}&sz={end}".format(initial=initial, end=end)

    
    page = requests.get(html)
    soup = bs(page.content,'html.parser')
    
    soup = list(soup.findAll('div', class_="product-tile auc-product-tile auc-js-product-tile"))
    
    lista_produtos = []
    
    for produto_data in soup:
        try:
           subsoup = bs(str(produto_data), 'html.parser')
           produto = json.loads(produto_data['data-gtm'])
           
           
           #link
           link =  "https://www.auchan.pt"+json.loads(produto_data['data-urls'])['quickViewUrl']
           
           #quantidade e u_m
           subtext = produto['name'].split(" ")[-1]
   
           subtext= ""
   
           quantidade = ''
           if any(char.isnumeric() for char in subtext): #verifica que a palavra tem numeros
               for c in subtext:
                   if(c.isnumeric() or c=='x'): #acrescenta o numero ou x à quantidade, e remove da palavra
                       quantidade = quantidade + c
                       subtext = subtext.replace(c,'') #retira do subtext
           elif len(subtext) == 1: #subtext é a unidade de medida
               quantidade = produto['name'].replace(subtext, '').strip().split(" ")[-1]
           else: #produto nao aplica quantidade
               quantidade = ''
           
   
          
                   
               
               
           
           
           subtext=subtext.strip() #subtext = u_m (quantidade retirada) 
           
           #subtext=""
   
   
   
           """
           #nome
           #retirar a quantidade e u_m do nome (bem como os duplos espaços), e separar o nome do resto (marca, quantidade, etc)
           nome = produto['name'].replace(quantidade, "")
           nome = nome.replace(subtext,"")
           nome = nome.replace("  "," ")
           nome = nome.replace(produto['brand'], '').strip()
           nome = nome.replace("  "," ")
           """
           nome = produto['name']
           
           
           
           #preco
           try:
               preco_u_m = subsoup.find('span', class_='auc-measures--price-per-unit').contents[0]
               preco_u_m = onlyNumbers(preco_u_m)
           except: #artigo nao tem preco_u_m
               preco_u_m = produto['price']
               
           
           
           #img
           img = bs(str(subsoup.find('div',class_="image-container auc-product-tile__image-container")),'html.parser')
           img = img.find('source')['data-srcset']
           img = img.split("?")[0]
           
   
   
   
           #desconto
           desconto = bs(str(subsoup.find('div', class_='auc-price__stricked')),'html.parser').find('span',class_='strike-through value')
           if(desconto != None): 
               desc_preco = float(desconto.contents[2].replace('€','').replace(',','.'))
               valor_desc = calculoDesconto(desc_preco, float(produto['price']))
               desconto = dicionarioDesconto([valor_desc, 'imediato', desc_preco])
           else:
               desconto = 0
           
           
           
           #check if string has numbers
   
   
           unit = nome.split(" ")[-1]
           if any(char.isnumeric() for char in unit):
               unit = unit[-1]
   
           unit = getGeneralMeasure(unit)
           
           nome_strip = numberInString(nome.split(" ")[-1])
           if(nome_strip != -1):
               quantidade = nome_strip
           
           valores = [nome, produto['brand'], quantidade, float(produto['price']), preco_u_m, unit, img, desconto, link, 'auchan', subtext]
           lista_produtos.append(criarDicionario(valores)) 
            
        except:
            pass    
        

    return lista_produtos
    


def lLeclerc(pesquisa):
    html = "https://online.e-leclerc.pt/hipermercado-barcelos/pesquisa.php?nome_pesq=arroz"
    page = requests.get(html)
    soup = bs(page.content,'html.parser')
    soup = list(soup.find_all('div',class_='produtos_coluna_cont animationcss'))
    
    for produto in soup:
        nome = produto.find('div',class_='produtos_nome')
        #print(nome.contents[0])
    
    
def froiz(pesquisa):
    html = "https://loja.froiz.com/search.php?q=arroz"
    page = requests.get(html)
    soup = bs(page.content,'html.parser')
    
    soup = list(soup.find_all('div',class_='product'))
    
    for produto in soup:
        #img
        img = "https://loja.froiz.com/" + str(produto.find("img",alt_="")['src'])
        
        #preco, preco original e desconto
        subtext = produto.find("h4",class_="title")
        
        if (len(subtext.contents)>1): #produto está em desconto
            preco = simplifyPrice(subtext.find("span",class_="red-clr").contents[0])
            preco_original = simplifyPrice(subtext.find("small").contents[0])
            valor = calculoDesconto(preco_original,preco)
            lista_desc = [valor, 'imediato', preco_original]
            desc = dicionarioDesconto(lista_desc)
        else:
            preco = simplifyPrice(subtext.find("h4",class_="title").contents[0])
            desc = None
        
