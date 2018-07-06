### Swiftix.io

This is my bachelor project, a ticket/online shop system with api written in Vapor 3. I've developed it while Vapor 3 was in heavy development, beta and without documentation, since then Vapor evolved, but still some packages are in beta. This project may be continued at a point when all necessary packages leaved beta, feel free to contribute. 

Installation: 

You'll need at least Swift 4.1+ / PostgreSQL 9+ / Vapor 3+

The Backend provides the Server part to communicate with Stripe as payment provider, you need a stripe account and secret key from Stripe. You can change the Settings under: /Sources/App/configSecrets/mainConfig.swift

1. Install Vapor: 
```
brew install vapor/tap/vapor
```
2. Create database user: 
```
createuser swiftix
```
3. Create database: 
```
createdb swiftix
```
4. Change folder:
```
cd /swiftix-server
```
5. build:
```
vapor build
```
6. run:
```
vapor run
```
7. open: 
```
open http://0.0.0.0:8080
```



# Api:

##### Users
```
POST api/v1/users/ 
GET api/v1/users/login/
```
##### Stores 
```
GET: api/v1/Stores/
GET: api/v1/Stores/:id/items/
GET: api/v1/Stores/:id/items/:id/products 
```
##### Cart
```
POST: api/v1/cart/add/products/:id 
DELETE: api/v1/cart/remove/products/:id 
GET: api/v1/cart/ 
GET: api/v1/cart/checkout
```
##### Checkout
```
GET: api/v1/checkout/:id/order
```
##### Order
```
GET: api/v1/order/:id/tickets
```
##### Admin
```
POST: api/v1/stores
PATCH: api/v1/stores/:id
DELETE: api/v1/stores/:id 
POST: api/v1/stores/:id/products 
PATCH: api/v1/stores/:id/products/:id 
DELETE: api/v1/stores/:id/products/:id 
POST: api/v1/stores/:id/products/:id/Item 
PATCH: api/v1/stores/:id/products/:id/Item/:id 
DELETE: api/v1/stores/:id/products/:id/Item/:id
```


# Entity Relationship Diagramm: 
![](https://github.com/swiftix-io/swiftix-server/blob/master/erd.png)
