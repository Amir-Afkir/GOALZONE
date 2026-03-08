defmodule SocialApp.DataCase do
  @moduledoc """
  Test setup for data access layer.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias SocialApp.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import SocialApp.DataCase
    end
  end

  setup tags do
    setup_sandbox(tags)
  end

  @doc """
  Transform changeset errors into a map of messages.
  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(SocialApp.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end
end
