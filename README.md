# LiveStore
## State management made easy for LiveView

A Redux like architecture implementation developped for Elixir. This library manages *state on the server side*. 

Keep in mind, this is a functional core (I am still new at this thing, so please be kind with me!). I took the simplest approach, inspired by the "Do Fun Things with big, loud worker-bees" mantra. 

This library is still new, I created the project on January, 26. It should be considered as alpha quality.

## The approach

The library does not blindly port JS/Redux to Elixir, I tried to maximize Elixir features to the best of my knowledge: pattern matching, function composition, etc. 

Since LiveView already are a process, I avoided dependencies on GenServers, Agent and the like. 

There is no coupling to LiveView: socket, etc. Nothing prevents to use the library in a GenServer or in a distributed process. 

## Applications using LiveStore

- Clusterfuck (a yet to be released) family organizer - this is the application LiveStore was developped for
- Harmony, a chore manager for kids and parents
- Presidentz, the card game (currently being ported to LiveStore)

## Getting started

### Prerequesites

Add this dependency to your `mix.exs` file:


```elixir
def deps do
  [
    {:live_store, "~> 0.1.0"}
  ]
end
```

NOTE: The project will be published to hex when it is more stable.

### Usage

TODO

## Concepts

### State

A __structure or a map__ containing the whole data for the view or the application. Let's call it the application state, so people already familiar with Redux are not confused. 

An application state can be composed of multiple substates, usually representing the data of a feature/module. An application state could contain data related to authentication, a list of todos, etc.

### Action

An __action represents__ a command that could potentially apply a mutation to the state of the application. In LiveStore, a command is represented by a tuple `{action_id, %{} = parameters}`. Here are some examples:

To authenticate a user:

`{"user:login", %{username: "bob", password: "secret123"}}`

To save a todo:

`{"task:create", %{description: "Master Elixir", done: false}}`

An action does not implement the logic, it's merely a description of what to accomplish.

### Reducer

A function or a module able to mutate state according to some actions. Usually, you will have a reducer for each state defined in the app.

TODO

### Store

The store is your starting point to `dispatch` an action. The store merely acts as a facade/gateway, it does not implement the processing itself.

TODO


#### Middleware

TODO

## Examples

For the time being, you can refer to tests.

## Contributing

TODO
