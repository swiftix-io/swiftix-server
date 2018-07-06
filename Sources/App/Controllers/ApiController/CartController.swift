import Vapor
import Fluent
import Foundation
import Authentication
final class CartController: RouteCollection {
    
    func boot(router: Router) throws {
        
        router.group("carts") { carts in
            carts.get(use: self.index)
            carts.post(use: self.create)
        }
        router.group("api") { api in
            api.group("v1") { v1 in
                v1.group("cart") { cart in
                    let tokenMiddleware = User.tokenAuthMiddleware()
                    let authGroup = cart.grouped(tokenMiddleware)
                    authGroup.get(use: self.show)
                    authGroup.post("add", Product.parameter, use: self.add)
                    authGroup.delete("remove",Product.parameter, use: self.remove)
                    authGroup.get("checkout", use: self.checkout)
                    authGroup.post("order", use: self.order)
                    authGroup.get("orders", use: self.orders)
                    authGroup.post("tickets", use: self.returnTickets)
                    authGroup.delete(use: self.delete)
                }
            }
        }
        
    }
    
    /// Returns a list of all `Cart`s
    func index(_ req: Request) throws -> Future<[Cart]> {
        return Cart.query(on: req).all()
    }
    
    //    ##################################################################################################
    /// create cart
    func create(_ req: Request) throws -> Future<Cart> {
        return try tokenUser(req: req).flatMap(to: Cart.self) { tokenUser in
            let newCart = try Cart(user: tokenUser)
            return newCart.save(on: req).map(to: Cart.self) { cart in
                return cart
            }
        }
    }
    
    //    ##################################################################################################
    /// Show `Cart`
    func show(_ req: Request) throws -> Future<[Product]> {
        
        return try tokenUser(req: req).flatMap(to: Array<Product>.self) { tokenUser in
            try tokenUser.carts.query(on: req).first().flatMap(to: Array<Product>.self) { cart in
                guard let cart = cart else {
                    throw Abort(.badRequest, reason: "no cart")
                }
                return Product
                    .query(on: req)
                    .join(\CartProductPivot.productId, to: \Product.id)
                    .filter(\CartProductPivot.cartId == cart.id ?? 0)
                    .all()
            }
        }
    }
    
    //    ##################################################################################################
    //Show orders
    func orders(_ req: Request) throws -> Future<[Order]> {
        
        return try tokenUser(req: req).flatMap(to: Array<Order>.self) { tokenUser in
            
            return Order
                .query(on: req)
                .filter(\Order.userId == tokenUser.id!)
                .all()
        }
    }
    
    
    //    ##################################################################################################
    func add(_ req: Request) throws -> Future<HTTPStatus> {
        return try tokenUser(req: req).flatMap(to: CartProductPivot.self) { tokenUser in
            try tokenUser.carts.query(on: req).first().flatMap(to: CartProductPivot.self) { cart in
                if let cart = cart {
                    return try req.parameters.next(Product.self).flatMap(to: CartProductPivot.self) { product in
                        
                        //
                        return CartProductPivot
                            .query(on: req)
                            .filter(\CartProductPivot.cartId == cart.id!)
                            .filter(\CartProductPivot.productId == product.id!).all()
                            .flatMap(to: CartProductPivot.self) { cartProductPivotArray in
                                
                                
                                // checks if there are enough tickets in stock
                                var pq = 0
                                if let productQuantity = product.quantity {
                                    pq = productQuantity
                                } else {
                                    pq = 100
                                }
                                if (cartProductPivotArray.count < pq) && (cartProductPivotArray.count < 50) {
                                    let cartProductPivot = try CartProductPivot(cart, product)
                                    return cartProductPivot.save(on: req)
                                } else {
                                    throw Abort(.badRequest, reason: "no more tickets available")
                                    
                                }
                        }
                    }
                }
                else {
                    return try self.create(req).flatMap(to: CartProductPivot.self) { cart in
                        return try req.parameters.next(Product.self).flatMap(to: CartProductPivot.self) { product in
                            let cartProductPivot = try CartProductPivot(cart, product)
                            return cartProductPivot.save(on: req)
                        }
                    }
                }
            }
            }.transform(to: .ok)
        
    }
    
    
    //    ##################################################################################################
    func remove(_ req: Request) throws -> Future<HTTPStatus> {
        return try tokenUser(req: req).flatMap(to: Void.self) { tokenUser in
            try tokenUser.carts.query(on: req).first().flatMap(to: Void.self) { cart in
                guard let cart = cart else {
                    throw Abort(.badRequest, reason: "no cart")
                }
                return try req.parameters.next(Product.self).flatMap(to: Void.self) { product in
                    if tokenUser.id != cart.userId {
                        throw Abort(HTTPStatus.unauthorized)
                    }
                    return CartProductPivot
                        .query(on: req)
                        .filter(\CartProductPivot.cartId == cart.id!)
                        .filter(\CartProductPivot.productId == product.id!)
                        .first().map(to: Void.self) { cartProductPivot in
                            return _ = CartProductPivot.query(on: req).filter(\CartProductPivot.id == cartProductPivot?.id).delete()
                    }
                }
            }
            }.transform(to: .ok)
    }
    
    //    ##################################################################################################
    
    func checkout (req: Request) throws -> Future<Checkout> {
        
        return try tokenUser(req: req).flatMap(to: Checkout.self) { tokenUser in
            try tokenUser.carts.query(on: req).first().flatMap(to: Checkout.self) { cart in
                guard let cart = cart else {
                    throw Abort(.badRequest, reason: "no cart")
                }
                
                _ = Checkout
                    .query(on: req)
                    .join(\CheckoutProductPivot.checkoutId, to: \Checkout.id)
                    .filter(\Checkout.cartId == cart.id!)
                    .all().map(to: Array<Checkout>.self) { checkout in
                        
                        //deletes all products of all previous checkouts from user
                        _ = checkout.map {checkout in
                            _ = CheckoutProductPivot
                                .query(on: req)
                                //MARK: safety unwrap
                                .filter(\CheckoutProductPivot.checkoutId == checkout.id!)
                                .delete()
                        }
                        return checkout
                    }.map(to: Array<Checkout>.self) { checkout in
                        
                        //delete all previous checkouts
                        _ = Checkout
                            .query(on: req)
                            .filter(\Checkout.cartId == cart.id!)
                            .delete()
                        return checkout
                }
                
                //create new checkout
                return Product
                    .query(on: req)
                    .filter(\CartProductPivot.cartId == cart.id ?? 0)
                    .join(\CartProductPivot.productId, to: \Product.id)
                    .all().flatMap(to: Checkout.self) { products in
                        
                        
                        
                        
                        //calculate price
                        let total = products.map { product in
                            product.price
                            }.reduce(0) { $0 + $1 }
                        
                        
                        let newCheckout = try Checkout(cart: cart, total: total)
                        
                        let checkout = newCheckout.save(on: req).map(to: Checkout.self) { checkout in
                            
                            return checkout
                        }
                        
                        return self.checkPrivot(checkout: checkout, req: req)
                }
                
            }
        }
    }
    //    ##################################################################################################
    
    func checkPrivot(checkout: Future<Checkout>, req: Request)  -> Future<Checkout> {
        
        return checkout.flatMap(to: Checkout.self) { checkout in
            
            Product
                .query(on: req)
                .filter(\CartProductPivot.cartId == checkout.cartId)
                .join(\CartProductPivot.productId, to: \Product.id)
                .all().map(to: Checkout.self) { products in
                    
                    
                    _ = try products.map { product in
                        _ = try CheckoutProductPivot(checkout, product).save(on: req)
                    }
                    return checkout
            }
        }
    }
    
    
    //    ##################################################################################################
    
    //reduce quantity on product table after order
    func reduceQuantity(req: Request, products: [Product]) throws {
        
        var productArray: [Product] = products
        
        guard let firstProduct = productArray.first else {
            throw Abort(.badRequest, reason: "no product")
        }
        
        _ = Product.query(on: req).filter(\Product.id == firstProduct.id).first().flatMap(to: Product.self) { dbProduct in
            guard let dbProduct = dbProduct else {
                throw Abort(.badRequest, reason: "no product")
            }
            firstProduct.quantity = dbProduct.quantity!-1
            return firstProduct.update(on: req).map(to: Product.self) { product in
                if productArray.count > 0 {
                    productArray.remove(at: 0)
                    _ = try self.reduceQuantity(req: req, products: productArray)
                }
                return product
            }
        }
    }
    
    
    
    
    
    
    //    ##################################################################################################
    
    struct Check: Content {
        var checkout: checkoutIdType
    }
    
    //    ##################################################################################################
    // generates/stores an order
    func order (req: Request) throws -> Future<Order> {
        
        return try tokenUser(req: req).flatMap(to: Order.self) { tokenUser in
            
            return try req.content.decode(Check.self).flatMap(to: Order.self) { checkout in
                
                return Product
                    .query(on: req)
                    
                    .join(\CheckoutProductPivot.productId, to: \Product.id)
                    .filter(\CheckoutProductPivot.checkoutId == checkout.checkout)
                    .all().flatMap(to: Order.self) { products in
                        _ = try self.reduceQuantity(req: req, products: products)
                        
                        let total = products.map { product in
                            product.price
                            }.reduce(0) { $0 + $1 }
                        
                        let order = try Order (user: tokenUser, total: total)
                        
                        if total <= 0{
                            throw Abort(.badRequest, reason: "no tickets")
                            
                        }
                        let o = order.save(on: req).map(to: Order.self) { order in
                            
                            return order
                        }
                        
                        
                        return try self.delete(req).flatMap(to: Order.self) { _ in
                            
                            
                            return try self.makeTickets(order: o, req: req)
                        }
                }
                
            }
        }
    }
    
    
    //    ##################################################################################################
    //generates/stores the tickets of an order
    func makeTickets(order: Future<Order>, req: Request) throws  -> Future<Order> {
        
        return try req.content.decode(Check.self).flatMap(to: Order.self) { checkout in
            return order.flatMap(to: Order.self) { order in
                return Product
                    .query(on: req)
                    .filter(\CheckoutProductPivot.checkoutId == checkout.checkout)
                    .join(\CheckoutProductPivot.productId, to: \Product.id)
                    .all().map(to: Order.self) { products in
                        _ = try products.map { product in
                            try Ticket(order: order, product: product).save(on: req)
                        }
                        return order
                }
            }
        }
    }
    
    struct OrderId: Content {
        var orderId: idType
    }
    
    
    //    ##################################################################################################
    // returns the tickets of an order
    func returnTickets(req: Request) throws  -> Future<[Ticket]> {
        return try req.content.decode(OrderId.self).flatMap(to: Array<Ticket>.self) { orderId in
            
            return Ticket
                .query(on: req)
                .filter(\Ticket.orderId == orderId.orderId)
                .all()
        }
        
    }
    
    
    //    ##################################################################################################
    /// Deletes a `Cart`
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        
        return try tokenUser(req: req).flatMap(to: Void.self) { tokenUser in
            return try tokenUser.carts.query(on: req).first().flatMap(to: Void.self) { cart in
                if let cart = cart {
                    
                    return CartProductPivot.query(on: req).filter(\CartProductPivot.cartId == cart.id!).delete().map(to: Void.self) { _ in
                        
                    }
                    
                } else {
                    throw Abort(.badRequest, reason: "no cart")
                }
            }
            }.transform(to: .ok)
    }
}


