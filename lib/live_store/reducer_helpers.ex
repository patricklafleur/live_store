defmodule LiveStore.Reducer.Helpers do
  require Logger

  # TODO is there a way we could specify a behavior or callback
  # instead of checking manually? Or a @spec?
  # Should I use a protocol, a behavior?
  # @spec reducer_module()
  def module_to_reducer(reducer_module) do
    &reducer_module.handle(&1, &2)
  end

  def identity() do
    fn state, _action -> state end
  end

  def pullback(reducer, attr_name) do
    fn state, action ->
      new_sub_state =
        state
        |> Map.get(attr_name)
        |> reducer.(action)

      state |> Map.put(attr_name, new_sub_state)
    end
  end

  def combine(first_reducer_fn, second_reducer_fn) do
    fn state, action ->
      first_reducer_fn.(state, action)
      |> second_reducer_fn.(action)
    end
  end
end
