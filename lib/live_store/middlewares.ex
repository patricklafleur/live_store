defmodule LiveStore.Middleware do
  require Logger

  def log_action() do
    fn _store ->
      fn next ->
        fn %{} = state, {_, _} = action ->
          Logger.info("dispatching action #{inspect(action)}...")
          new_state = next.(state, action)
          Logger.debug("processed action #{inspect(action)}.")
          new_state
        end
      end
    end
  end

  def log_state() do
    fn _store ->
      fn next ->
        fn %{} = state, {_, _} = action ->
          Logger.debug("state before processing #{inspect(state, pretty: true)}.")
          new_state = next.(state, action)
          Logger.debug("state after processing #{inspect(state, pretty: true)}.")
          new_state
        end
      end
    end
  end

  def diff_state() do
    fn _store ->
      fn next ->
        fn %{} = state, {_, _} = action ->
          Logger.debug("[middleware#diff_state]")
          new_state = next.(state, action)
          diff = MapDiff.diff(Map.from_struct(state), Map.from_struct(new_state))
          Logger.debug("states diff for action #{inspect(action)}:\n")
          Logger.debug("[added]\n#{inspect(diff[:added], pretty: true)}\n", ansi_color: :green)
          Logger.debug("[removed]\n#{inspect(diff[:added], pretty: true)}\n", ansi_color: :orange)
          new_state
        end
      end
    end
  end
end
