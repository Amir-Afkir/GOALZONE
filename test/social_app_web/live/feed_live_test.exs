defmodule SocialAppWeb.FeedLiveTest do
  use SocialAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SocialApp.AccountsFixtures

  alias SocialApp.{Accounts, Posts}

  test "renders feed shell sections for an empty feed", %{conn: conn} do
    user = user_fixture()

    conn = log_in_user(conn, user)
    {:ok, lv, _html} = live(conn, ~p"/")

    assert has_element?(lv, ".feed-layout")
    assert has_element?(lv, ".feed-sidebar-left .sidebar-brand-logo", "GoalZone")
    assert has_element?(lv, ".feed-sidebar-left .sidebar-title", "Navigation")
    assert has_element?(lv, ".composer-shell .composer-trigger", "Partage ton highlight")
    assert has_element?(lv, ".feed-hero-card .feed-hero-title", "LE TERRAIN ATTEND")
    assert has_element?(lv, ".right-search-panel .right-search-input")
    assert has_element?(lv, ".right-premium-panel .right-premium-title", "Passe en mode elite")
    assert has_element?(lv, ".right-radar-panel .sidebar-title", "Sur le radar")
    assert has_element?(lv, ".radar-item", "mercato U21 a suivre ce soir")

    assert has_element?(
             lv,
             ".right-coach-panel .right-coach-title",
             "Besoin d'un repere ?"
           )

    assert has_element?(lv, ".right-coach-panel .right-coach-cta", "Comprendre la page")
  end

  test "opens the composer form with prefilled format and intention from quick actions", %{
    conn: conn
  } do
    user = user_fixture()

    conn = log_in_user(conn, user)
    {:ok, lv, _html} = live(conn, ~p"/")

    refute has_element?(lv, ".feed-composer-form")

    lv
    |> element(
      "button.composer-pill-action[phx-value-format='article'][phx-value-intention='recruitment']"
    )
    |> render_click()

    assert has_element?(lv, ".feed-composer-form")

    assert has_element?(
             lv,
             "input[type='radio'][name='post[post_format]'][value='article'][checked]"
           )

    assert has_element?(lv, "option[value='recruitment'][selected]", "Recruter / scouter")
  end

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
