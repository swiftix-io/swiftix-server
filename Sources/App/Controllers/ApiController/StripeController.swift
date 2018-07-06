import Foundation
import Vapor

final class StripeController: RouteCollection {
    
    func boot(router: Router) throws {
        router.group("api") { api in
            api.group("v1") { v1 in
                v1.group("stripe") { stripe in
                    stripe.post(use: self.stripe)
                }
            }
        }
    }
    
    struct StripeStruct: Content {
        var source: String
        var amount: Int
        var currency: String?
        var description: String?
    }
    
    
    //    ##################################################################################################
    // stripe
    func stripe(_ req: Request) throws -> Future<Response> {
        
        return try req.content.decode(StripeStruct.self).flatMap(to: Response.self) { stripeStruct in
            
            let url = URL(string: constants.STRIPE_CHARGES_URL)
            let body = HTTPBody(string: "amount=\(stripeStruct.amount)&currency=\(stripeStruct.currency ?? "eur")&description=\(stripeStruct.description ?? "")&source=\(stripeStruct.source)")
            
            let httpRequest = HTTPRequest(method: .POST, url: url!, headers: ["authorization": "Bearer \(constants.STRIPE_SK)", "contentType": "application/x-www-form-urlencoded"], body: body)
            let request = Request(http: httpRequest, using: req)
            
            return try req.client().send(request).map(to: Response.self) { response in
            print(response)
            return response
        }
    }
}
    
} // class end

