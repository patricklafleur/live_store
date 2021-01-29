defmodule LiveStore.MiddlewareHelpers do
  require Logger

  defmodule ResultDispatcher do
    @spec dispatch_result(
            {:ok, any()} | {:error, any()},
            # state_type
            map(),
            {String.t(), map()},
            (map(), map(), {String.t(), map()} -> map()),
            (any() -> any()),
            (any() -> any())
          ) :: map()
    def dispatch_result(result, state, action, success_fn, failure_fn, dispatch) do
      new_action = result_action(result, action, success_fn, failure_fn)
      dispatch.(state, new_action)
    end

    defp result_action({status, params}, {source_id, _}, success_fn, failure_fn) do
      result_params_factory =
        case status do
          :ok -> success_fn
          :error -> failure_fn
        end

      {result_action_id(status, source_id), result_params_factory.(params)}
    end

    defp result_action_id(:ok, action_id), do: action_id <> ":success"
    defp result_action_id(:error, action_id), do: action_id <> ":failure"
  end

  # TODO how can I check it implements the right callbacks?
  # Should I use a protocol, a behavior?
  def module_to_middleware(middleware_module) do
    fn store ->
      # capture the store, we avoid declaring
      dispatch = LiveStore.get_dispatch(store)
      # the store on each module intercept function

      fn next ->
        fn state, action ->
          middleware_module.before_next(state, action, dispatch)
          |> next.(action)
          |> middleware_module.after_next(action, dispatch)
        end
      end
    end
  end
end
