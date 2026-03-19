defmodule SocialAppWeb.MercatoLiveTest do
  use SocialAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SocialApp.AccountsFixtures

  alias SocialApp.{Accounts, Posts}

  test "shows three announcements by default and reveals more results", %{conn: conn} do
    viewer =
      scouting_user_fixture(
        %{role: :scout, region: "Casablanca", headline: "Scout local", confidence_score: 62},
        %{username: "viewer_scout"}
      )

    author =
      scouting_user_fixture(
        %{role: :club, region: "Casablanca", headline: "Club U21", confidence_score: 78},
        %{username: "club_casa"}
      )

    for index <- 1..4 do
      {:ok, _post} =
        Posts.create_post(author.id, %{
          content: "Annonce #{index}",
          post_format: :article,
          intention: :recruitment,
          source_type: :live_observation,
          confidence_score: index
        })
    end

    conn = log_in_user(conn, viewer)
    {:ok, lv, html} = live(conn, ~p"/mercato")

    assert html =~ "Recherche par poste, niveau, club..."
    assert html =~ "Offres a la une"
    assert html =~ "Annonce 4"
    refute html =~ "Annonce 1"
    assert has_element?(lv, "button", "Filtres")
    assert has_element?(lv, "button", "Voir tout")

    html =
      lv
      |> element("button[phx-click='show_more_announcements']")
      |> render_click()

    assert html =~ "Annonce 1"
    assert has_element?(lv, "button", "Voir moins")
  end

  test "filtering announcements updates the visible shortlist", %{conn: conn} do
    viewer =
      scouting_user_fixture(
        %{role: :scout, region: "Casablanca", headline: "Scout local"},
        %{username: "viewer_filter"}
      )

    casa_author =
      scouting_user_fixture(
        %{role: :club, region: "Casablanca", level: :elite, availability: :open},
        %{username: "casa_author"}
      )

    paris_author =
      scouting_user_fixture(
        %{role: :coach, region: "Paris", level: :espoir, availability: :monitoring},
        %{username: "paris_author"}
      )

    {:ok, _post} =
      Posts.create_post(casa_author.id, %{
        content: "Besoin elite a Casablanca.",
        post_format: :article,
        intention: :recruitment
      })

    {:ok, _post} =
      Posts.create_post(paris_author.id, %{
        content: "Besoin espoir a Paris.",
        post_format: :article,
        intention: :recruitment
      })

    conn = log_in_user(conn, viewer)
    {:ok, lv, _html} = live(conn, ~p"/mercato")

    lv
    |> element("button[phx-click='open_filters_modal']")
    |> render_click()

    html =
      lv
      |> form(".mercato-filter-form",
        filters: %{
          "q" => "",
          "region" => "Casablanca",
          "role" => "club",
          "level" => "elite",
          "availability" => "open"
        }
      )
      |> render_submit()

    assert html =~ "Besoin elite a Casablanca"
    refute html =~ "Besoin espoir a Paris"
  end

  test "searching announcements by keyword narrows the list", %{conn: conn} do
    viewer =
      scouting_user_fixture(
        %{role: :scout, region: "Casablanca", headline: "Scout terrain"},
        %{username: "viewer_search"}
      )

    winger_author =
      scouting_user_fixture(
        %{role: :club, region: "Casablanca", level: :elite, availability: :open},
        %{username: "winger_author"}
      )

    keeper_author =
      scouting_user_fixture(
        %{role: :club, region: "Rabat", level: :confirme, availability: :open},
        %{username: "keeper_author"}
      )

    {:ok, _post} =
      Posts.create_post(winger_author.id, %{
        content: "Recherche ailier rapide pour integrer le groupe U21.",
        post_format: :article,
        intention: :recruitment
      })

    {:ok, _post} =
      Posts.create_post(keeper_author.id, %{
        content: "Recherche gardien pour renforcer le groupe senior.",
        post_format: :article,
        intention: :recruitment
      })

    conn = log_in_user(conn, viewer)
    {:ok, lv, _html} = live(conn, ~p"/mercato")

    lv
    |> element("form.mercato-search-form")
    |> render_change(%{
      "filters" => %{
        "q" => "ailier",
        "region" => "",
        "role" => "",
        "level" => "",
        "availability" => ""
      }
    })

    assert has_element?(lv, ".mercato-announcement-item", "Recherche ailier rapide")
    refute has_element?(lv, ".mercato-announcement-item", "Recherche gardien pour renforcer")
  end

  test "publishing an announcement updates profile metadata and creates a recruitment post", %{
    conn: conn
  } do
    viewer = user_fixture(%{username: "publisher_viewer"})

    conn = log_in_user(conn, viewer)
    {:ok, lv, _html} = live(conn, ~p"/mercato")

    lv
    |> element("button.mercato-publish-cta")
    |> render_click()

    html =
      lv
      |> form(".mercato-publish-form",
        announcement: %{
          region: "Marseille",
          role: "player",
          level: "elite",
          availability: "open",
          content: "Je cherche un club ambitieux pour la prochaine saison."
        }
      )
      |> render_submit()

    updated_user = Accounts.get_user!(viewer.id)
    [latest_post | _] = Posts.list_posts_by_user(viewer.id, 1)

    assert html =~ "Annonce publiee"
    assert updated_user.region == "Marseille"
    assert updated_user.level == :elite
    assert updated_user.availability == :open
    assert latest_post.intention == :recruitment
    assert latest_post.post_format == :article
    assert latest_post.content == "Je cherche un club ambitieux pour la prochaine saison."
    assert has_element?(lv, ~s|a[href="/posts/#{latest_post.id}"]|, "Voir l'annonce")
  end

  defp scouting_user_fixture(profile_attrs, registration_attrs) do
    user = user_fixture(registration_attrs)
    {:ok, updated_user} = Accounts.update_user(user, profile_attrs)
    updated_user
  end
end
