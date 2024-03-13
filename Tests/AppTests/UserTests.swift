//
//  File.swift
//  
//
//  Created by Jacob Best on 3/12/24.
//

@testable import App
import XCTVapor

final class UserTests: XCTestCase {
  let usersFirstName = "Griffen"
  let usersLastName = "Best"
  let usersUsername = "gbest"
  let usersURI = "/api/users/"
  var app: Application!
  
  override func setUpWithError() throws {
    app = try Application.testable()
  }
  
  override func tearDownWithError() throws {
    app.shutdown()
  }
  
  func testUsersCanBeRetrievedFromAPI() throws {
    let user = try User.create(firstName: usersFirstName, lastName: usersLastName, username: usersUsername, on: app.db)
    _ = try User.create(on: app.db)
    
    try app.test(.GET, usersURI, afterResponse: { response in
      
      XCTAssertEqual(response.status, .ok)
      let users = try response.content.decode([User.Public].self)
      
      XCTAssertEqual(users.count, 3)
      XCTAssertEqual(users[1].firstName, usersFirstName)
      XCTAssertEqual(users[1].lastName, usersLastName)
      XCTAssertEqual(users[1].username, usersUsername)
      XCTAssertEqual(users[1].id, user.id)
    })
  }
  
  func testUserCanBeSavedWithAPI() throws {
    let user = User(firstName: usersFirstName, lastName: usersLastName, username: usersUsername, password: "password")
    
    try app.test(.POST, usersURI, loggedInRequest: true) { req in
      try req.content.encode(user)
    } afterResponse: { response in
      let receivedUser = try response.content.decode(User.Public.self)
      XCTAssertEqual(receivedUser.firstName, usersFirstName)
      XCTAssertEqual(receivedUser.lastName, usersLastName)
      XCTAssertEqual(receivedUser.username, usersUsername)
      XCTAssertNotNil(receivedUser.id)
      
      try app.test(.GET, usersURI) { secondResponse in
        let users = try secondResponse.content.decode([User.Public].self)
        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(users[1].firstName, usersFirstName)
        XCTAssertEqual(users[1].lastName, usersLastName)
        XCTAssertEqual(users[1].username, usersUsername)
        XCTAssertEqual(users[1].id, receivedUser.id)
      }
    }
  }
  
  func testGettingASingleUserFromTheAPI() throws {
    let user = try User.create(firstName: usersFirstName, lastName: usersLastName, username: usersUsername, on: app.db)
    
    try app.test(.GET, "\(usersURI)\(user.id!)") { response in
      let receivedUser = try response.content.decode(User.Public.self)
      XCTAssertEqual(receivedUser.firstName, usersFirstName)
      XCTAssertEqual(receivedUser.lastName, usersLastName)
      XCTAssertEqual(receivedUser.username, usersUsername)
      XCTAssertEqual(receivedUser.id, user.id)
    }
  }
  
  func testGettingAUsersDecksFromTheAPI() throws {
    let user = try User.create(firstName: usersFirstName, lastName: usersLastName, username: usersUsername, on: app.db)
    
    let deckTitle = "Paint Colors"
    
    let deck1 = try Deck.create(title: deckTitle, user: user, on: app.db)
    _ = try Deck.create(title: "Art Exhibits", user: user, on: app.db)
    
    try app.test(.GET, "\(usersURI)\(user.id!)/decks") { response in
      let decks = try response.content.decode([Deck].self)
      XCTAssertEqual(decks.count, 2)
      XCTAssertEqual(decks[0].id, deck1.id)
      XCTAssertEqual(decks[0].title, deckTitle)
    }
  }
}
