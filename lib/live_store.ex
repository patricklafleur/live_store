defmodule LiveStore do
  require Logger

  @type reducer_params_type :: map()
  @type action_type :: {String.t(), reducer_params_type}
  @type state_type :: map()

  @type reducer_type :: (action_type, state_type -> state_type)
  @type middleware_next_type :: (reducer_type -> reducer_type)
  @type middleware_factory_type :: (store_type -> middleware_next_type)

  @type dispatcher_type :: (action_type -> :ok)

  @opaque store_type :: [
            root_reducer: (action_type, state_type -> state_type),
            dispatcher: (action_type, state_type -> state_type)
          ]

  @doc ~S"""
  Configures and creates a store.

  ## Examples

      iex> LiveStore.new(nil, fn store, action, state -> end)
      {:error, :root_reducer_required}

      iex> LiveStore.new(fn action, state -> state end, nil)
      {:error, :dispatcher_required}

      # iex> LiveStore.new(
      # iex>    fn action, state -> state end,
      # iex>    fn store, action, state -> end
      # iex>  )
      # {:ok, [root_reducer, dispatcher]}
  """
  @spec new(reducer_type, dispatcher_type) :: {:ok, store_type} | {:error, atom()}
  def new(nil, _), do: {:error, :root_reducer_required}
  def new(_, nil), do: {:error, :dispatcher_required}

  def new(root_reducer, dispatcher),
    do: {:ok, [root_reducer: &root_reducer.(&1, &2), dispatcher: dispatcher]}

  @doc ~S"""
  Adds a middleware to the store. Middlewares are executed before
  the reducer that handles the state.

  A middleware function can:
  - execute code before reducers, after reducers or both
  - halt the processing of an action by not calling the next function


  They can be used for *anything related to side effects*:

  - log something to console or a file
  - measure processing time for an action
  - modify an action and/or it's parameters before it's sent to the next function
  - check the security role of a user and stop the processing if forbidden
  - pause/delay an action processing
  - async processing, such as calling an API
  - dispatch additional actions (ex: upon receiving a response)
  - etc

  ## Examples

      iex> store =
      iex> LiveStore.new(fn(action, state) -> state end, fn store, action, state -> end)
      iex> |> LiveStore.apply_middleware(fn store -> fn next -> fn action, state -> next.(action, %{state | a: 10}) end end end)
      iex> |> LiveStore.dispatch({"noop", %{}}, %{a: 0})
      {:ok, %{a: 10}}
  """
  @spec apply_middleware(
          store_type | {:ok, store_type},
          middleware_factory_type
        ) ::
          {:ok, store_type}
  def apply_middleware({:ok, store}, middleware_factory),
    do: apply_middleware(store, middleware_factory)

  def apply_middleware(
        [root_reducer: root_reducer, dispatcher: dispatch] = store,
        middleware_factory
      ) do
    # (store) -> (next_reducer)
    middleware_wrapper = middleware_factory.(store)
    # (next_reducer) -> (action, state)
    new_root_reducer = middleware_wrapper.(root_reducer)
    # (action, state) -> state
    {:ok, [root_reducer: new_root_reducer, dispatcher: dispatch]}
  end

  # def apply_middlewares({:ok, [root_reducer: _, dispatcher: _] = store},
  #                       middlewares) when is_list(middlewares) do
  #   {:ok, apply_middlewares(store, middlewares)}
  # end

  def apply_middlewares(
        {:ok, [root_reducer: _, dispatcher: _]} = store,
        [current_middleware | other_middlewares]
      ) do
    store
    |> apply_middleware(current_middleware)
    |> apply_middlewares(other_middlewares)
  end

  def apply_middlewares({:ok, [root_reducer: _, dispatcher: _]} = store, []) do
    store
  end

  @doc ~S"""
  Dispatch an action to a Store.

  ## Examples

      # iex> store =
      # iex>    LiveStore.new(
      # iex>       fn action, state -> %{state | a: state.a + 5} end,
      # iex>       fn store, action, state -> end
      # iex>    )
      # iex>    |> LiveStore.dispatch({"noop", %{}}, %{a: 5})
      # {:ok, %{a: 10}}
  """
  @spec dispatch(
          store_type | {:ok, store_type},
          state_type,
          action_type
        ) ::
          {:ok, state_type} | {:error, atom()}

  def dispatch({:error, _} = error, _, _), do: error

  def dispatch(
        {:ok, store},
        %{} = state,
        {_, _} = action
      ),
      do: dispatch(store, state, action)

  def dispatch(
        [root_reducer: reducer, dispatcher: _dispatch],
        %{} = state,
        {_, _} = action
      ),
      do: {:ok, reducer.(state, action)}

  def get_dispatch({:ok, [root_reducer: _, dispatcher: _] = store}) do
    get_dispatch(store)
  end

  def get_dispatch([root_reducer: _, dispatcher: dispatch] = store) do
    fn %{} = state, {_, _} = action ->
      dispatch.(store, state, action)
    end
  end

  # def sync_dispatcher(), do:
  #   &(LiveStore.dispatch(&1, &2, &3))

  # def async_send_self_dispatcher() do
  #   fn store, state, action ->
  #     send self(), action
  #   end
  # end
end
