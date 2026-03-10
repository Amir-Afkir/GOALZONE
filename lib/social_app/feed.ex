defmodule SocialApp.Feed do
  @moduledoc """
  Contexte de generation de feed et fan-out.
  """

  import Ecto.Query, warn: false
  require Logger

  alias SocialApp.Repo
  alias SocialApp.Accounts
  alias SocialApp.Accounts.Follow
  alias SocialApp.Feed.FanOutWorker
  alias SocialApp.Posts.Post

  def home_feed_for_user(user_id, opts \\ [])

  def home_feed_for_user(nil, opts) do
    limit = Keyword.get(opts, :limit, 20)
    SocialApp.Posts.list_recent_posts(limit)
  end

  def home_feed_for_user(user_id, opts) do
    limit = Keyword.get(opts, :limit, 20)

    from(p in Post,
      left_join: f in Follow,
      on: f.followed_id == p.user_id and f.follower_id == ^user_id,
      where: p.user_id == ^user_id or not is_nil(f.follower_id),
      order_by: [desc: p.inserted_at],
      preload: [:user],
      limit: ^limit
    )
    |> Repo.all()
  end

  def fan_out_post_async(post) do
    case Oban.insert(FanOutWorker.new(%{post_id: post.id})) do
      {:ok, _job} ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to enqueue feed fan-out for post #{post.id}: #{inspect(reason)}")
        :ok
    end
  end

  def fan_out_post(post_id) when is_integer(post_id) do
    case Repo.get(Post, post_id) do
      nil -> {:error, :post_not_found}
      %Post{} = post -> fan_out_post(post)
    end
  end

  def fan_out_post(%Post{} = post) do
    do_fan_out_post(post)
    :ok
  end

  defp do_fan_out_post(post) do
    post = Repo.preload(post, :user)

    Accounts.list_followers(post.user_id)
    |> Enum.each(fn follower ->
      if online_user?(follower.id) do
        Phoenix.PubSub.broadcast(SocialApp.PubSub, "user:#{follower.id}", {:new_post, post})
      end
    end)
  end

  defp online_user?(user_id) do
    SocialAppWeb.Presence.list("user:#{user_id}") != %{}
  end
end
