//
//  File.swift
//  
//
//  Created by Jacob Best on 2/7/24.
//

import Vapor
import Fluent

final class User: Model, Content {
  static let schema = "users"
  
  @ID
  var id: UUID?
  
  @Field(key: "firstName")
  var firstName: String
  
  @Field(key: "lastName")
  var lastName: String
  
  @OptionalField(key: "middleName")
  var middleName: String?
  
  @Field(key: "username")
  var username: String
  
  @Field(key: "email")
  var email: String
  
  @Field(key: "password")
  var password: String
  
  init() {}
  
  init(id: UUID? = nil, firstName: String, middleName: String? = nil, lastName: String, username: String, email: String, password: String) {
    self.id = id
    self.firstName = firstName
    self.middleName = middleName
    self.lastName = lastName
    self.username = username
    self.email = email
    self.password = password
  }
}
