# 3CG Battle

This is a game that was inspired by other games like Hearthstone, SmashUp, NovaIsland, and Defiance for the core gameplay idea alongside some Greek Mythology was how this game idea came to be.

## Core play loop

This game is a strategy card game where you have 3 zones where you can use 4 character cards from Greek mythology and have them go against an opposing squad for a battle to the death. Their victory is based on overall team power level.

## Rules

The players have a given amount of mana and depending on the amount they are granted gives them the ability to summon these figures to the battle zones with each round increasing their mana pools. Each player is granted points based on the number of battles they win and whoever reaches an X number of points shall be declared victorious. 

## Game handling

This game was written in Lua using LOVE2D and the cards were handled via a CSV file imported by a spreadsheet. I needed a little help from chatgpt to learn how to do that in lua.

## Patterns used

### Sequencing Patterns

Game Loops were used to handle the whole game to keep track of turns and cycles of the game while playing.

### Design Patterns

- **Flyweight** was used while implementing cards to keep things consistent and tunable like with all the cards with the use of the csv it is easily editable.
- **Prototype** was used to create new instances of objects like cards and decks.
- **States** are used to check on the game to see what “state” it is in like in the code there is a win state lose state tie state. Its purpose is to check on the game and create a response as needed.

## Conclusion

This was a very interesting project to work on, it took a lot of time to get this even working but I have a newfound appreciation for card games and all these patterns when it comes to game development.

## Credits

This project was done by Suramya with some help from chat gpt to clean up code and format this beautiful readme file.
