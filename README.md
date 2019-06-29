# Twhelp
A mostly-shitty Twilio CLI app written in Elixir used for:

1. Fetching and displaying (sub)account details
2. Translating/fetching Twilio's error code definitions (there's _hundreds_ of them)

Here's what it looks like:

![Alt text](assets/twhelp-screenshot.png?raw=true "screenshot")

## Build & Run
1. Install Elixir (probably through [asdf](https://asdf-vm.com/))
1. Clone the repo
1. `mix deps.get`
1. `mix escript.build`
1. Run!

_`TWILIO_ACCOUNT_SID` and `TWILIO_AUTH_TOKEN` env vars must be set._

## Notes
I wrote this to get some familiarity with Elixir and `mix`.