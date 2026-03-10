defmodule SocialAppWeb.FeedLiveTest do
  use SocialAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SocialApp.AccountsFixtures

  alias SocialApp.{Accounts, Posts}

  test "renders followed posts and updates likes without full reload", %{conn: conn} do
    viewer = user_fixture()
    author = user_fixture()

    {:ok, _follow} = Accounts.follow_user(viewer.id, author.id)
    {:ok, post} = Posts.create_post(author.id, %{content: "Grand match ce soir"})

    conn = log_in_user(conn, viewer)
    {:ok, lv, html} = live(conn, ~p"/")
    assert html =~ "Grand match ce soir"

    lv
    |> element("button[phx-click='like'][phx-value-post_id='#{post.id}']")
    |> render_click()

    assert render(lv) =~ "Supporters: 1"
  end
end
