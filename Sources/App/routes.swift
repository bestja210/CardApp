import Fluent
import Vapor

func routes(_ app: Application) throws {
  app.get("hello") { req -> String in
    return "Hello, world!"
  }
  
  let usersController = UsersController()
  try app.register(collection: usersController)
  
  let decksController = DecksController()
  try app.register(collection: decksController)
  
  let categoriesController = CategoriesController()
  try app.register(collection: categoriesController)
  
  let cardsController = CardsController()
  try app.register(collection: cardsController)
}
