# Supermarket_AllInOne
This project consists of three elements:
- Webscrapping of products information from the supermarkets websites, and putting them in a database
- Server/API that will allow to retrieve and send the information
- A android app to visualize the products, as well as compare the price with the other supermarkets

The main purpose of this project was to allow an easy way to verify which supermarket is cheaper for one or several products

# Scrapping
Using the python packages _Beautiful Soup_ and _requests_, the technic used is to get the webpages of the supermarkets, for a certain search parameter, and then scrap the information to the database
One of the supermarkets however has a open API, being used instead of the website

# Server/API
The server is a simple ASGI web server, using the python package _uvicorn_, and the API is build using the _FastAPI_ package. The server receives the requests, directs them to the API, and then returns the results.

# Android APP
A simple APP built in flutter, that allows to:
- Search for products, in all or only some supermarkets
- Compare each individual product to other supermarkets
- Add products to a shopping cart, and then see and compare the final price in several supermarkets
- See which supermarket is the closest to the current location
- See price history (using the database)
