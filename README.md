# Uno

A small Uno game built to show how to model a domain with Funx.

This project keeps the domain model explicit and composable:

- `Uno.Game` is the aggregate root: a plain struct plus pure state transitions, updated with optics
- `Uno.Rules` is domain policy: predicates, Eq, and Ord that define what counts as playable, how to rank plays, and when the game ends
- `Uno.Validator.*` are domain constraints: reusable validators such as current turn, game not over, and valid play
- `Uno.Service` is an application service: loads the aggregate, validates, applies pure transformations, then persists

The UI is a Phoenix LiveView that renders the current state and sends player intents as events.

## Run locally

- Run `mix setup` to install and set up dependencies
- Start the Phoenix endpoint with `mix phx.server`
  - or inside IEx with `iex -S mix phx.server`

Then visit `http://localhost:4000`.

To jump straight into the game, visit `http://localhost:4000/game`.

## Project layout

- `lib/uno/game.ex`: aggregate root and state transitions
- `lib/uno/rules.ex`: domain rules: predicates and ordering
- `lib/uno/validator/*.ex`: domain validators
- `lib/uno/games.ex`: application service entry points
- `lib/uno_web/live/game/*`: LiveView UI

