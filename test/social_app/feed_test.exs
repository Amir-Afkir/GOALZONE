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
end
