import requests
from requests.structures import CaseInsensitiveDict


ip = requests.get('https://api.ipify.org').content.decode('utf8')
ipv6 = requests.get("http://ipify.org").content.decode('utf8')


url = "https://api.dynu.com/v2/dns/9717720"

headers = CaseInsensitiveDict()
headers["accept"] = "application/json"
headers["API-Key"] = "3g5X46YeY663U443454YUf53555c33VY"
headers["Authorization"] = "Bearer VQBpAHgAOABJAEEAQgBtAEEARwBJAEEAWgBnAEEAMwBBAEQAVQBBAFoAUQBBADQAQQBHAFUAQQBMAFEAQQB4AEEARABnAEEATwBBAEEAMQBBAEMAMABBAE4AQQBBAHcAQQBEAGsAQQBPAEEAQQB0AEEARwBJAEEATQBBAEEAMQBBAEcATQBBAEwAUQBBAHgAQQBEAEUAQQBOAGcAQgBpAEEARABVAEEATQBBAEIAagBBAEQAWQBBAFkAUQBCAGsAQQBEAEUAQQBaAEEAQQA3AEEARwBjAEEATgBnAEIAVwBBAEYAWQBBAFkAZwBBADEAQQBGAFkAQQBXAGcAQQB6AEEARwBFAEEATgBBAEIAYQBBAEcAVQBBAE4AUQBBADIAQQBEAFkAQQBWAHcAQQB6AEEARgBnAEEATgBRAEEAegBBAEcAVQBBAE4AZwBBADEAQQBEAE0AQQBaAFEAQgBVAEEARgBVAEEATQB3AEEAMgBBAEQAcwBBAE4AQQBBAHYAQQBEAEkAQQBNAGcAQQB2AEEARABJAEEATQBnAEEAZwBBAEQAYwBBAE8AZwBBAHkAQQBEAEUAQQBPAGcAQQB4AEEARABJAEEASQBBAEIAQgBBAEUAMABBAE8AdwBCAFYAQQBIAE0AQQBaAFEAQgB5AEEAQQB8AHwA"
headers["Content-Type"] = "application/json"

data = '{{"name":"somedomain.com","group":"office","ipv4Address":"{}","ipv6Address":"{}","ttl":90,"ipv4":true,"ipv6":true,"ipv4WildcardAlias":true,"ipv6WildcardAlias":true,"allowZoneTransfer":false,"dnssec":false}}'.format(ip, ipv6)
#data = ' {{"asd" : {name}'.format(name="asd")


resp = requests.post(url, headers=headers, data=data)

#print(resp.status_code)

