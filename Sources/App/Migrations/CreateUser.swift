//
//  File.swift
//  
//
//  Created by Jacob Best on 2/7/24.
//

import Fluent


struct CreateUser: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    database.schema("users")
      .id()
      .field("firstName", .string, .required)
      .field("lastName", .string, .required)
      .field("middleName", .string)
      .field("username", .string, .required)
      .field("email", .string, .required)
      .field("password", .string, .required)
      .create()
  }
  
  func revert(on database: Database) -> EventLoopFuture<Void> {
    database.schema("users").delete()
  }
}
