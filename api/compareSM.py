from sqlalchemy import all_
import scrapping_pesquisa

list_functions = [scrapping_pesquisa.continente,scrapping_pesquisa.pingoDoce ]

#certifica-se que as palavras (words) estao na string, independentemente se estao juntas, alternadas, etc
def checkWordsInString(words, string):
    words = words.lower().split(" ")
    string = string.lower()    

    if all(word in string for word in words):
        return True
    return False


def compare_produtos(produto):
    
    if(str(produto['marca']) != '-1'):
        search = "{} {}".format(produto['nome'],produto['marca'])
    else:
        search = produto['nome']
    

    cont = []
    pd= []
    auch = []
        
    try:
        cont = scrapping_pesquisa.continente(search, '0', '30')[0]
    except:
        pass
    print("---------------------------------------------------------------------")
    try:
        pd = scrapping_pesquisa.pingoDoce(search, '0')[0]
    except:
        pass
    print("---------------------------------------------------------------------")
    try:
        auch = scrapping_pesquisa.auchan(search, '0', '30')[0]
    except:
        pass
    print("---------------------------------------------------------------------")
    
    all_sm = [cont, pd, auch]
    
    """
    for sm in all_sm:
        for p in sm:
            
            if (str(p['quantidade']) == '-1' or float(p['quantidade']) == float(produto['quantidade'])) :  
                if(str(produto['marca']) == '-1' or str(p['marca']).lower() == str(produto['marca']).lower()): #verifica se o utilizador pretende comparar com a marca, ou encontrar uma marca mais barata
                    list_produtos.append(p)
                    break
            else:
                print(p['quantidade'])
    """


    """
    page = '0'
    status = True
    while(status):
        try:
            mp = scrapping_pesquisa.miniPreco(search,page, filter='low-to-high')
        except:
            status=False
            pass
        for p in mp:  
            print(p['quantidade'])   
            if (str(p['quantidade']) == '-1' or float(p['quantidade']) == float(produto['quantidade'])) and checkWordsInString(produto['nome'], p['nome']):
                if(str(produto['marca']) == '-1' or str(p['marca']).lower() == str(produto['marca']).lower()): #verifica se o utilizador pretende comparar com a marca, ou encontrar uma marca mais barata
                    list_produtos.append(p)
                    status=False
                    break
        #nao encontrou nenhum artigo (incrementa a pagina)
        page = str(int(page) + 1)
    """  
        
    return all_sm
    


produto = {'nome': 'massa esparguete 71',
           'quantidade': '500',
           'marca': '-1',
           
           }


