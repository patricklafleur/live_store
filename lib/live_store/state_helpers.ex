defmodule StateHelpers do
  def keep_if_true(true, source, _), do: source
  def keep_if_true(false, _, updated), do: updated

  def replace_if_true(true, _, updated), do: updated
  def replace_if_true(false, source, _), do: source

  def matching_id() do
    fn e1, e2 -> e1.id == e2.id end
  end

  def replace_one(elements, match_fn, replacement) do
    case Enum.find_index(elements, & match_fn.(&1, replacement)) do
      nil   -> elements
      index -> List.replace_at(elements, index, replacement)
    end
  end

  def replace_if(elements, match_fn, updated) do
    elements |> Enum.map(&replace_if_true(match_fn.(&1, updated), &1, updated))
  end
end
