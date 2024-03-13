//
//  File.swift
//  
//
//  Created by Jacob Best on 3/12/24.
//

@testable import App
import Fluent
import Vapor

extension User {
  static func create(
    firstName: String = "Alyssa",
    lastName: String = "Best",
    username: String? = nil,
    on database: Database
  ) throws -> User {
    let createUsername: String
    if let suppliedUsername = username {
      createUsername = suppliedUsername
    } else {
      createUsername = UUID().uuidString
    }
    
    let password = try Bcrypt.hash("password")
    let user = User(
      firstName: firstName,
      lastName: lastName,
      username: createUsername,
      password: password)
    try user.save(on: database).wait()
    return user
  }
}

extension Deck {
  static func create(
    title: String = "Math",
    user: User? = nil,
    on database: Database
  ) throws -> Deck {
    var decksUser = user
    
    if decksUser == nil {
      decksUser = try User.create(on: database)
    }
    
    let deck = Deck(
      title: title,
      userID: decksUser!.id!)
    try deck.save(on: database).wait()
    return deck
  }
}

extension App.Category {
  static func create(
    name: String = "Random",
    on database: Database
  ) throws -> App.Category {
    let category = Category(name: name)
    try category.save(on: database).wait()
    return category
  }
}

extension Card {
  static func create(
    front: String = "What is 1 + 1",
    back: String = "2",
    on database: Database
  ) throws -> Card {
    let card = Card(front: front, back: back)
    try card.save(on: database).wait()
    return card
  }
}

