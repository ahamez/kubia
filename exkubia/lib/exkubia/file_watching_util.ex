defmodule Exkubia.FileWatchingUtil do
  @spec modifed?(list(atom())) :: boolean()
  def modifed?(events) do
    Enum.find(events, &(&1 == :created or &1 == :renamed or &1 == :modified)) != nil
  end
end
