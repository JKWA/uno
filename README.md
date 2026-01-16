# Uno

A small Uno game built to explore modeling a domain with Funx.

## Run locally

* Run `mix setup` to install and set up dependencies
* Start the Phoenix endpoint with `mix phx.server`

  * or in IEx with `iex -S mix phx.server`

Then visit `http://localhost:4000`.

## Project layout

* `lib/uno/card.ex`: card struct and helpers
* `lib/uno/hand.ex`: hand management
* `lib/uno/game.ex`: aggregate root and state transitions
* `lib/uno/rules.ex`: domain rules: predicates and ordering
* `lib/uno/action/*.ex`: action modules (draw, skip, reverse, etc.)
* `lib/uno/validator/*.ex`: domain validators
* `lib/uno/service.ex`: application service entry points
* `lib/uno/bot.ex`: bot player logic
* `lib/uno/store.ex`: game state storage
* `lib/uno_web/components/*`: UI components
* `lib/uno_web/live/game/*`: LiveView UI

## Invariants

If any of these conditions are violated, the state is impossible. This indicates a bug and the process should crash.

* Game creation must be valid
* Discard pile is never empty
* Every player must have a hand
* A played card must exist in the player’s hand
* Draw effects will have enough cards after reshuffle
