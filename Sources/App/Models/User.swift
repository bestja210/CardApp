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
  
  @Field(key: "username")
  var username: String
  
  @Field(key: "password")
  var password: String
  
  @Children(for: \.$user)
  var decks: [Deck]
  
  @Timestamp(key: "deleted_at", on: .delete)
  var deletedAt: Date?
  
  @Enum(key: "userType")
  var userType: UserType
  
  init() {}
  
  init(id: UUID? = nil, firstName: String, lastName: String, username: String, password: String, userType: UserType = .standard) {
    self.firstName = firstName
    self.lastName = lastName
    self.username = username
    self.password = password
    self.userType = userType
  }
  
  final class Public: Content {
    var id: UUID?
    var firstName: String
    var lastName: String
    var username: String
    
    init(id: UUID?, firstName: String, lastName: String, username: String) {
      self.id = id
      self.firstName = firstName
      self.lastName = lastName
      self.username = username
    }
  }
}

extension User {
  func convertToPublic() -> User.Public {
    return User.Public(id: id, firstName: firstName, lastName: lastName, username: username)
  }
}

extension Collection where Element: User {
  func convertToPublic() -> [User.Public] {
    return self.map { $0.convertToPublic() }
  }
}

extension EventLoopFuture where Value: User {
  func convertToPublic() -> EventLoopFuture<User.Public> {
    return self.map { user in
      return user.convertToPublic()
    }
  }
}

extension EventLoopFuture where Value == Array<User> {
  func convertToPublic() -> EventLoopFuture<[User.Public]> {
    return self.map { $0.convertToPublic() }
  }
}

extension User: ModelAuthenticatable {
  static var usernameKey = \User.$username
  static var passwordHashKey = \User.$password
  
  func verify(password: String) throws -> Bool {
    try Bcrypt.verify(password, created: self.password)
  }
}

extension User: ModelCredentialsAuthenticatable {}

