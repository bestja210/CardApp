//
//  File.swift
//  
//
//  Created by Jacob Best on 3/12/24.
//

import Fluent
import Vapor

struct CreateAdminUser: Migration {
  func prepare(on database: any Database) -> EventLoopFuture<Void> {
    let passwordHash: String
    do {
      passwordHash = try Bcrypt.hash("password")
    } catch {
      return database.eventLoop.future(error: error)
    }
    let user = User(firstName: "Admin", lastName: "1", username: "admin1", password: passwordHash, userType: .admin)
    return user.save(on: database)
  }
  
  func revert(on database: any Database) -> EventLoopFuture<Void> {
    User.query(on: database).filter(\.$username == "admin1").delete()
  }
}


