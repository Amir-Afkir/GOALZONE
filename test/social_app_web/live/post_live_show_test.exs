defmodule SocialAppWeb.PostLiveShowTest do
  use SocialAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SocialApp.AccountsFixtures

  test "redirects safely when post id is invalid", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)

    assert {:error, {:live_redirect, %{to: "/"}}} = live(conn, ~p"/posts/not-a-number")
  end
end
