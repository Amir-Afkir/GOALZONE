defmodule SocialApp.FeedTest do
  use SocialApp.DataCase, async: true

  import SocialApp.AccountsFixtures

  alias SocialApp.{Accounts, Feed, Posts}

  test "fan_out_post broadcasts new posts to online followers" do
    author = user_fixture()
    follower = user_fixture()

    {:ok, _follow} = Accounts.follow_user(follower.id, author.id)

    Phoenix.PubSub.subscribe(SocialApp.PubSub, "user:#{follower.id}")

    {:ok, _presence} =
      SocialAppWeb.Presence.track(self(), "user:#{follower.id}", follower.id, %{
        online_at: DateTime.utc_now()
      })

    {:ok, post} = Posts.create_post(author.id, %{content: "Action decisive"})

    assert :ok = Feed.fan_out_post(post.id)
    assert_receive {:new_post, received_post}
    assert received_post.id == post.id
  end

  test "home_feed_for_user applies tab filters and limits in the query" do
    viewer = user_fixture()
    followed_author = user_fixture()
    ignored_author = user_fixture()

    {:ok, _follow} = Accounts.follow_user(viewer.id, followed_author.id)

    {:ok, showcase_post} =
      Posts.create_post(followed_author.id, %{content: "Highlight", intention: :showcase})

    {:ok, recruitment_post} =
      Posts.create_post(followed_author.id, %{content: "Scout need", intention: :recruitment})

    {:ok, _ignored_post} =
      Posts.create_post(ignored_author.id, %{content: "Outside feed", intention: :showcase})

    mercato_feed = Feed.home_feed_for_user(viewer.id, tab: "mercato", sort: "recent", limit: 5)

    opportunities_feed =
      Feed.home_feed_for_user(viewer.id, tab: "opportunities", sort: "recent", limit: 5)

    assert Enum.map(mercato_feed, & &1.id) == [showcase_post.id]
    assert Enum.map(opportunities_feed, & &1.id) == [recruitment_post.id]

    limited_feed = Feed.home_feed_for_user(viewer.id, tab: "for_you", sort: "recent", limit: 1)
    assert length(limited_feed) == 1
  end
end
