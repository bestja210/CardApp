//
//  File.swift
//  
//
//  Created by Jacob Best on 3/12/24.
//

@testable import App
import XCTVapor

final class CardTests: XCTestCase {
  let cardsURI = "/api/cards/"
  let cardFront = "Who Was The 41st President of the USA"
  let cardBack = "George W. Bush"
  var app: Application!
  
  override func setUp() {
    app = try! Application.testable()
  }
  
  override func tearDown() {
    app.shutdown()
  }
  
  func testCardsCanBeRetrievedFromAPI() throws {
    let card = try Card.create(front: cardFront, back: cardBack, on: app.db)
    _ = try Card.create(on: app.db)
    
    try app.test(.GET, cardsURI) { response in
      let cards = try response.content.decode([Card].self)
      XCTAssertEqual(cards.count, 2)
      XCTAssertEqual(cards[0].front, cardFront)
      XCTAssertEqual(cards[0].back, cardBack)
      XCTAssertEqual(cards[0].id, card.id)
    }
  }
  
  func testCardCanBeSavedWithAPI() throws {
    let card = Card(front: cardFront, back: cardBack)
    
    try app.test(.POST, cardsURI, loggedInRequest: true) { request in
      try request.content.encode(card)
    } afterResponse: { response in
      let receivedCard = try response.content.decode(Card.self)
      XCTAssertEqual(receivedCard.front, cardFront)
      XCTAssertEqual(receivedCard.back, cardBack)
      XCTAssertNotNil(receivedCard.id)
      
      try app.test(.GET, cardsURI) { response in
        let cards = try response.content.decode([Card].self)
        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards[0].front, cardFront)
        XCTAssertEqual(cards[0].back, cardBack)
        XCTAssertEqual(cards[0].id, receivedCard.id)
      }
    }
  }
  
  func testGettingASingleCardFromTheAPI() throws {
    let card = try Card.create(front: cardFront, back: cardBack, on: app.db)
    
    try app.test(.GET, "\(cardsURI)\(card.id!)") { response in
      let returnedCard = try response.content.decode(Card.self)
      XCTAssertEqual(returnedCard.front, cardFront)
      XCTAssertEqual(returnedCard.back, cardBack)
      XCTAssertEqual(returnedCard.id, card.id)
    }
  }
  
  func testCardsDecks() throws {
    let deck = try Deck.create(on: app.db)
    let deck2 = try Deck.create(title: "Education", on: app.db)
    
    let card = try Card.create(front: cardFront, back: cardBack, on: app.db)
    
    try app.test(.POST, "\(cardsURI)\(card.id!)/decks/\(deck.id!)", loggedInRequest: true)
    try app.test(.POST, "\(cardsURI)\(card.id!)/decks/\(deck2.id!)", loggedInRequest: true)
    
    try app.test(.GET, "\(cardsURI)\(card.id!)/decks") { response in
      let decks = try response.content.decode([Deck].self)
      XCTAssertEqual(decks.count, 2)
      XCTAssertEqual(decks[0].id, deck.id)
      XCTAssertEqual(decks[0].title, deck.title)
      XCTAssertEqual(decks[1].id, deck2.id)
      XCTAssertEqual(decks[1].title, deck2.title)
    }
    
    try app.test(.DELETE, "\(cardsURI)\(card.id!)/decks/\(deck.id!)", loggedInRequest: true)
    
    try app.test(.GET, "\(cardsURI)\(card.id!)/decks") { response in
      let newDecks = try response.content.decode([Deck].self)
      XCTAssertEqual(newDecks.count, 1)
    }
  }
}
