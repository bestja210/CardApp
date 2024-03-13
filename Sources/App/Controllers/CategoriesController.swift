//
//  File.swift
//  
//
//  Created by Jacob Best on 2/21/24.
//

import Vapor

struct CategoriesController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let categoriesRoute = routes.grouped("api","categories")
    categoriesRoute.get(use: getAllHandler)
    categoriesRoute.get(":categoryID", use: getHandler)
    categoriesRoute.get(":categoryID", "decks", use: getDecksHandler)
    categoriesRoute.get("decks", "users", use: getAllCategoriesWithDecksAndUsers)
    categoriesRoute.get("decks", "cards", use: getAllCategoriesWithDecksAndCards)
    
    let tokenAuthMiddleware = Token.authenticator()
    let guardAuthMiddleware = User.guardMiddleware()
    let tokenAuthGroup = categoriesRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
    tokenAuthGroup.post(use: createHandler)
  }
  
  func createHandler(_ req: Request) throws -> EventLoopFuture<Category> {
    let category = try req.content.decode(Category.self)
    return category.save(on: req.db).map { category }
  }
  
  func getAllHandler(_ req: Request) -> EventLoopFuture<[Category]> {
    Category.query(on: req.db).all()
  }
  
  func getHandler(_ req: Request) -> EventLoopFuture<Category> {
    Category.find(req.parameters.get("categoryID"), on: req.db).unwrap(or: Abort(.notFound))
  }
  
  func getDecksHandler(_ req: Request) -> EventLoopFuture<[Deck]> {
    Category.find(req.parameters.get("categoryID"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .flatMap { category in
        category.$decks.get(on: req.db)
      }
  }
  
  func getAllCategoriesWithDecksAndUsers(_ req: Request) -> EventLoopFuture<[CategoryWithDecks<DeckWithUser>]> {
    Category.query(on: req.db).with(\.$decks) { decks in
      decks.with(\.$user)
    }.all().map { categories in
      categories.map { category in
        let categoryDecks = category.decks.map {
          DeckWithUser(
            id: $0.id,
            title: $0.title,
            user: $0.user.convertToPublic())
        }
        return CategoryWithDecks(id: category.id, name: category.name, decks: categoryDecks)
      }
    }
  }
  
  func getAllCategoriesWithDecksAndCards(_ req: Request) -> EventLoopFuture<[CategoryWithDecks<DeckWithCards>]> {
    Category.query(on: req.db).with(\.$decks) { decks in
      decks.with(\.$cards)
    }.all().map { categories in
      categories.map { category in
        let categoryDecks = category.decks.map {
          DeckWithCards(
            id: $0.id,
            title: $0.title,
            cards: $0.cards)
        }
        return CategoryWithDecks(id: category.id, name: category.name, decks: categoryDecks)
      }
    }
  }
}

struct CategoryWithDecks<Deck: Content>: Content {
  let id: UUID?
  let name: String
  let decks: [Deck]
}

struct DeckWithUser: Content {
  let id: UUID?
  let title: String
  let user: User.Public
}

