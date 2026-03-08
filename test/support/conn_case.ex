defmodule SocialAppWeb.ConnCase do
  @moduledoc """
  Test setup for connection-dependent cases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint SocialAppWeb.Endpoint

      use SocialAppWeb, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import SocialAppWeb.ConnCase
    end
  end

  setup tags do
    SocialApp.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = SocialApp.AccountsFixtures.user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  @doc """
  Logs the given `user` into the `conn`.
  """
  def log_in_user(conn, user) do
    token = SocialApp.Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end
end
