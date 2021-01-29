defmodule LiveStoreTest do
  require Logger
  use ExUnit.Case
  #  doctest LiveStore

  describe "new/2" do
    test "requires a root reducer" do
      assert {:error, :root_reducer_required} = LiveStore.new(nil, nil)
    end

    test "requires a dispatcher" do
      assert {:error, :dispatcher_required} = LiveStore.new(identity_reducer(), nil)
    end

    test "initializes the store" do
      assert {:ok, _} = LiveStore.new(identity_reducer(), sync_dispatcher())
    end
  end

  describe "dispatch/2" do
    test "requires an initialized store" do
      assert {:error, :store_is_nil} = LiveStore.dispatch(nil, {"", %{}}, %{})
    end
  end

  describe "dispatch/2 with identity reducer" do
    test "returns the state unmodified" do
      assert {:ok, %{a: 1}} =
               LiveStore.new(identity_reducer(), sync_dispatcher())
               |> LiveStore.dispatch(%{a: 1}, {"noop", %{}})
    end
  end

  describe "dispatch/2 with IncrementModuleReducer" do
    test "handle(inc) increments by one by default" do
      assert {:ok, %{counter: 2}} =
               LiveStore.new(inc_module_reducer(), sync_dispatcher())
               |> LiveStore.dispatch(%{counter: 1}, {"inc", %{}})
    end

    test "handle(inc) increments with the provided value" do
      assert {:ok, %{counter: 5}} =
               LiveStore.new(inc_module_reducer(), sync_dispatcher())
               |> LiveStore.dispatch(%{counter: 1}, {"inc", %{v: 4}})
    end
  end

  describe "dispatch/2 with negating middleware" do
    test "negates the value sent to the reducer" do
      {:ok, store} = LiveStore.new(inc_by_value_reducer(), sync_dispatcher())
      {:ok, store} = store |> LiveStore.apply_middleware(negate_middleware())
      IO.inspect(store)
      {:ok, %{counter: 4}} = store |> LiveStore.dispatch(%{counter: 5}, {"inc", %{v: 1}})
    end
  end

  describe "dispatch/2 with halting middleware" do
    test "does not call the next function" do
      {:ok, %{counter: 5}} =
        LiveStore.new(inc_by_value_reducer(), sync_dispatcher())
        |> LiveStore.apply_middleware(negate_middleware())
        |> LiveStore.apply_middleware(halting_middleware())
        |> LiveStore.dispatch(%{counter: 5}, {"inc", %{v: 1}})
    end
  end

  describe "store with middleware dispatching" do
    test "handles action synchronously" do
      {:ok, %{counter: 15}} =
        LiveStore.new(inc_module_reducer(), sync_dispatcher())
        |> LiveStore.apply_middleware(dispatch_inc_middleware())
        |> LiveStore.dispatch(%{counter: 0}, {"dec", %{v: 10}})
    end

    test "handles action asynchronously" do
      # 1. The dec action processing is synchronous, returning -10
      # 2. The inc is dispatched asynchronously. When it is concretely
      #    dispatched, the mechanism will pass the latest state the inc
      #    action. Since no other actions were processed, it should still
      #    be -10 in this case, but it could have been modified since the
      #    dispatch was requested.
      check_async_dispatch_execution = fn task ->
        # Here you would assign the latest state for the next dispatch,
        # such as in a LiveView socket.assigns
        assert {:ok, %{counter: 15}} = Task.await(task)
      end

      assert {:ok, %{counter: -10}} =
               LiveStore.new(
                 inc_module_reducer(),
                 async_dispatcher(check_async_dispatch_execution)
               )
               |> LiveStore.apply_middleware(dispatch_inc_middleware())
               |> LiveStore.dispatch(%{counter: 0}, {"dec", %{v: 10}})

      # Action(dec) sync processing is done.
    end
  end

  defp async_dispatcher(execution_callback) do
    fn store, state, {_, _} = action ->
      Task.async(fn ->
        # In a real situation, you would need to pass the latest state
        # stored, for example, in a LiveView socket.assigns.
        # Logger.debug "Processing LiveStore.dispatch(#{inspect(action_name)})..."
        execution_callback.(store |> LiveStore.dispatch(state, action))
      end)

      {:ok, state}
    end
  end

  defp sync_dispatcher() do
    fn store, state, {action_id, _} = action ->
      store |> LiveStore.dispatch(state, action)
    end
  end

  defp dispatch_inc_middleware() do
    fn [root_reducer: _root_reducer, dispatcher: dispatcher] = store ->
      fn next ->
        fn state, {action_id, _} = action ->
          # process the original "dec" action
          state = next.(state, action)

          case action_id == "dec" do
            true ->
              {:ok, state} = store |> dispatcher.(state, {"inc", %{v: 25}})
              state

            false ->
              state
          end
        end
      end
    end
  end

  defp halting_middleware() do
    fn store ->
      fn next ->
        fn state, {_action, %{v: v}} ->
          # does not call the next function, effectively stopping the chain
          # this might be used to call a function that requires a certain security level
          # or some criteria is not met, etc.
          # next.(state)
          state
        end
      end
    end
  end

  defp negate_middleware() do
    fn store ->
      fn next ->
        fn state, {action, %{v: v} = params} ->
          next.(state, {action, %{params | v: -v}})
        end
      end
    end
  end

  defp identity_reducer() do
    fn state, action -> state end
  end

  defp inc_by_value_reducer() do
    fn state, {action, %{v: v}} ->
      %{state | counter: state.counter + v}
    end
  end

  defp inc_module_reducer() do
    &LiveStoreTest.IncrementReducer.handle(&1, &2)
  end

  defmodule IncrementReducer do
    def handle(state, {"dec", %{v: v}} = action), do: state |> add(-v)
    def handle(state, {"dec", _} = action), do: state |> add(-1)

    def handle(state, {"inc", %{v: v}} = action), do: state |> add(v)
    def handle(state, {"inc", _}), do: state |> add(1)

    defp add(%{counter: counter} = state, v), do: %{state | counter: counter + v}
  end
end
