//
//  File.swift
//  
//
//  Created by Jacob Best on 2/7/24.
//

import Vapor
import Fluent

struct UsersController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let userRoute = routes.grouped("api", "users")
    
    userRoute.post(use: createHandler)
    userRoute.get(use: getAllHandler)
  }
  
  func createHandler(_ req: Request) throws -> EventLoopFuture<User> {
    let user = try req.content.decode(User.self)
    return user.save(on: req.db).map { user }
  }
  
  func getAllHandler(_ req: Request) -> EventLoopFuture<[User]> {
    User.query(on: req.db).all()
  }
}
