//
//  File.swift
//  
//
//  Created by Jacob Best on 3/12/24.
//

@testable import App
import XCTVapor

final class CategoryTests: XCTestCase {
  let categoriesURI = "/api/categories/"
  let categoryName = "Art"
  var app: Application!
  
  override func setUp() {
    app = try! Application.testable()
  }
  
  override func tearDown() {
    app.shutdown()
  }
  
  func testCategoriesCanBeRetrievedFromAPI() throws {
    let category = try Category.create(name: categoryName, on: app.db)
    _ = try Category.create(on: app.db)
    
    try app.test(.GET, categoriesURI) { response in
      let categories = try response.content.decode([App.Category].self)
      XCTAssertEqual(categories.count, 2)
      XCTAssertEqual(categories[0].name, categoryName)
      XCTAssertEqual(categories[0].id, category.id)
    }
  }
  
  func testCategoryCanBeSavedWithAPI() throws {
    let category = Category(name: categoryName)
    
    try app.test(.POST, categoriesURI, loggedInRequest: true, beforeRequest: { request in
      try request.content.encode(category)
    }, afterResponse: { response in
      let receivedCategory = try response.content.decode(Category.self)
      XCTAssertEqual(receivedCategory.name, categoryName)
      XCTAssertNotNil(receivedCategory.id)
      
      try app.test(.GET, categoriesURI, afterResponse: { response in
        let categories = try response.content.decode([App.Category].self)
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories[0].name, categoryName)
        XCTAssertEqual(categories[0].id, receivedCategory.id)
      })
    })
  }
  
  func testGettingASingleCategoryFromTheAPI() throws {
    let category = try Category.create(name: categoryName, on: app.db)
    
    try app.test(.GET, "\(categoriesURI)\(category.id!)", afterResponse: { response in
      let returnedCategory = try response.content.decode(Category.self)
      XCTAssertEqual(returnedCategory.name, categoryName)
      XCTAssertEqual(returnedCategory.id, category.id)
    })
  }
  
  func testGettingACategoriesDeckFromTheAPI() throws {
    let deckTitle = "Artists"
    let deck = try Deck.create(title: deckTitle, on: app.db)
    let deck2 = try Deck.create(on: app.db)
    
    let category = try Category.create(name: categoryName, on: app.db)
    
    try app.test(.POST, "api/decks/\(deck.id!)/categories/\(category.id!)", loggedInRequest: true)
    try app.test(.POST, "api/decks/\(deck2.id!)/categories/\(category.id!)", loggedInRequest: true)
    
    try app.test(.GET, "\(categoriesURI)\(category.id!)/decks", afterResponse: { response in
      let decks = try response.content.decode([Deck].self)
      XCTAssertEqual(decks.count, 2)
      XCTAssertEqual(decks[0].id, deck.id)
      XCTAssertEqual(decks[0].title, deckTitle)
    })
  }
}
