//
//  File.swift
//  
//
//  Created by Jacob Best on 3/12/24.
//

@testable import App
import XCTVapor

final class DeckTests: XCTestCase {
  let decksURI = "/api/decks/"
  let deckTitle = "Networking"
  var app: Application!
  
  override func setUp() {
    app = try! Application.testable()
  }
  
  override func tearDown() {
    app.shutdown()
  }
  
  func testDecksCanBeRetrievedFromAPI() throws {
    let deck1 = try Deck.create(title: deckTitle, on: app.db)
    _ = try Deck.create(on: app.db)
    
    try app.test(.GET, decksURI) { response in
      let decks = try response.content.decode([Deck].self)
      XCTAssertEqual(decks.count, 2)
      XCTAssertEqual(decks[0].title, deckTitle)
      XCTAssertEqual(decks[0].id, deck1.id)
    }
  }
  
  func testDeckCanBeSavedWithAPI() throws {
    let user = try User.create(on: app.db)
    let createDeckData = CreateDeckData(title: deckTitle)
    
    try app.test(.POST, decksURI, loggedInUser: user) { request in
      try request.content.encode(createDeckData)
    } afterResponse: { response in
      let receivedDeck = try response.content.decode(Deck.self)
      XCTAssertEqual(receivedDeck.title, deckTitle)
      XCTAssertNotNil(receivedDeck.id)
      XCTAssertEqual(receivedDeck.$user.id, user.id)
      
      try app.test(.GET, decksURI) { allDecksResponse in
        let decks = try allDecksResponse.content.decode([Deck].self)
        XCTAssertEqual(decks.count, 1)
        XCTAssertEqual(decks[0].title, deckTitle)
        XCTAssertEqual(decks[0].id, receivedDeck.id)
        XCTAssertEqual(decks[0].$user.id, user.id)
      }
    }
  }
  
  func testGettingASingleDeckFromTheAPI() throws {
    let deck = try Deck.create(title: deckTitle, on: app.db)
    
    try app.test(.GET, "\(decksURI)\(deck.id!)") { response in
      let returnedDeck = try response.content.decode(Deck.self)
      XCTAssertEqual(returnedDeck.title, deckTitle)
      XCTAssertEqual(returnedDeck.id, deck.id)
    }
  }
  
  func testUpdatingADeck() throws {
    let deck = try Deck.create(title: deckTitle, on: app.db)
    let newUser = try User.create(on: app.db)
    let newTitle = "Computer Sceince"
    let updatedDeckData = CreateDeckData(title: newTitle)
    
    try app.test(.PUT, "\(decksURI)\(deck.id!)", loggedInUser: newUser) { request in
      try request.content.encode(updatedDeckData)
    }
    
    try app.test(.GET, "\(decksURI)\(deck.id!)") { response in
      let returnedDeck = try response.content.decode(Deck.self)
      XCTAssertEqual(returnedDeck.title, newTitle)
      XCTAssertEqual(returnedDeck.$user.id, newUser.id)
    }
  }
  
  func testDeletingADeck() throws {
    let deck = try Deck.create(on: app.db)
    
    try app.test(.GET, decksURI) { response in
      let decks = try response.content.decode([Deck].self)
      XCTAssertEqual(decks.count, 1)
    }
    
    try app.test(.DELETE, "\(decksURI)\(deck.id!)", loggedInRequest: true)
    
    try app.test(.GET, decksURI) { response in
      let decks = try response.content.decode([Deck].self)
      XCTAssertEqual(decks.count, 0)
    }
  }
  
  func testSearchDeckTitle() throws {
    let deck = try Deck.create(title: deckTitle, on: app.db)
    
    try app.test(.GET, "\(decksURI)search?term=Networking") { response in
      let decks = try response.content.decode([Deck].self)
      XCTAssertEqual(decks.count, 1)
      XCTAssertEqual(decks[0].id, deck.id)
      XCTAssertEqual(decks[0].title, deckTitle)
    }
  }
  
  func testGetFirstDeck() throws {
    let deck = try Deck.create(title: deckTitle, on: app.db)
    _ = try Deck.create(on: app.db)
    _ = try Deck.create(on: app.db)
    
    try app.test(.GET, "\(decksURI)first") { response in
      let firstDeck = try response.content.decode(Deck.self)
      XCTAssertEqual(firstDeck.id, deck.id)
      XCTAssertEqual(firstDeck.title, deckTitle)
    }
  }
  
  func testSortingDeck() throws {
    let title2 = "Genetics"
    let deck1 = try Deck.create(title: deckTitle, on: app.db)
    let deck2 = try Deck.create(title: title2, on: app.db)
    
    try app.test(.GET, "\(decksURI)sorted") { response in
      let sortedDecks = try response.content.decode([Deck].self)
      XCTAssertEqual(sortedDecks[0].id, deck2.id)
      XCTAssertEqual(sortedDecks[1].id, deck1.id)
    }
  }
  
  func testGettingADecksUser() throws {
    let user = try User.create(on: app.db)
    let deck = try Deck.create(user: user, on: app.db)
    
    try app.test(.GET, "\(decksURI)\(deck.id!)/user") { response in
      let decksUser = try response.content.decode(User.Public.self)
      XCTAssertEqual(decksUser.id, user.id)
      XCTAssertEqual(decksUser.firstName, user.firstName)
      XCTAssertEqual(decksUser.lastName, user.lastName)
      XCTAssertEqual(decksUser.username, user.username)
    }
  }
  
  func testDecksCategories() throws {
    let category = try Category.create(on: app.db)
    let category2 = try Category.create(name: "Educational", on: app.db)
    
    let deck = try Deck.create(on: app.db)
    
    try app.test(.POST, "\(decksURI)\(deck.id!)/categories/\(category.id!)", loggedInRequest: true)
    try app.test(.POST, "\(decksURI)\(deck.id!)/categories/\(category2.id!)", loggedInRequest: true)
    
    try app.test(.GET, "\(decksURI)\(deck.id!)/categories") { response in
      let categories = try response.content.decode([App.Category].self)
      XCTAssertEqual(categories.count, 2)
      XCTAssertEqual(categories[0].id, category.id)
      XCTAssertEqual(categories[0].name, category.name)
      XCTAssertEqual(categories[1].id, category2.id)
      XCTAssertEqual(categories[1].name, category2.name)
    }
    
    try app.test(.DELETE, "\(decksURI)\(deck.id!)/categories/\(category.id!)", loggedInRequest: true)
    
    try app.test(.GET, "\(decksURI)\(deck.id!)/categories") { response in
      let newCategories = try response.content.decode([App.Category].self)
      XCTAssertEqual(newCategories.count, 1)
    }
  }
}
