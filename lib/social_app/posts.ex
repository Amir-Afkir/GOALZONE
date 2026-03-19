defmodule SocialApp.Posts do
  @moduledoc """
  Contexte posts, likes et commentaires.
  """

  import Ecto.Query, warn: false
  alias SocialApp.Repo
  alias SocialApp.Feed
  alias SocialApp.Notifications
  alias SocialApp.Posts.{Post, Like, Comment}

  def list_recent_posts(limit \\ 20) do
    from(p in Post, order_by: [desc: p.inserted_at], limit: ^limit, preload: [:user])
    |> Repo.all()
  end

  def list_recruitment_posts(filters \\ %{}, opts \\ []) do
    exclude_user_id = Keyword.get(opts, :exclude_user_id)
    limit = Keyword.get(opts, :limit, 12)
    viewer_region = Keyword.get(opts, :viewer_region)

    Post
    |> join(:inner, [p], u in assoc(p, :user))
    |> where([p, _u], p.intention == :recruitment)
    |> maybe_exclude_post_author(exclude_user_id)
    |> apply_recruitment_filters(filters)
    |> apply_recruitment_order(viewer_region)
    |> preload([_p, u], user: u)
    |> limit(^limit)
    |> Repo.all()
  end

  def count_recruitment_posts(filters \\ %{}, opts \\ []) do
    exclude_user_id = Keyword.get(opts, :exclude_user_id)

    Post
    |> join(:inner, [p], u in assoc(p, :user))
    |> where([p, _u], p.intention == :recruitment)
    |> maybe_exclude_post_author(exclude_user_id)
    |> apply_recruitment_filters(filters)
    |> select([p, _u], count(p.id))
    |> Repo.one()
  end

  def list_posts_by_user(user_id, limit \\ 30) do
    from(p in Post,
      where: p.user_id == ^user_id,
      order_by: [desc: p.inserted_at],
      preload: [:user],
      limit: ^limit
    )
    |> Repo.all()
  end

  def get_post!(id) do
    Post
    |> Repo.get!(id)
    |> Repo.preload([:user, comments: :user])
  end

  def create_post(user_id, attrs) do
    attrs = attrs |> Map.new() |> Map.put(:user_id, user_id)

    Repo.transaction(fn ->
      case %Post{} |> Post.changeset(attrs) |> Repo.insert() do
        {:ok, post} ->
          Feed.fan_out_post_async(post)
          post

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  def like_post(user_id, post_id) do
    Repo.transaction(fn ->
      now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

      {inserted_rows, _} =
        Repo.insert_all(
          Like,
          [%{user_id: user_id, post_id: post_id, inserted_at: now}],
          on_conflict: :nothing,
          conflict_target: [:user_id, :post_id]
        )

      if inserted_rows == 1 do
        from(p in Post, where: p.id == ^post_id)
        |> Repo.update_all(inc: [likes_count: 1])
      end

      post = Repo.get!(Post, post_id)

      if inserted_rows == 1 and post.user_id != user_id do
        _ =
          Notifications.create_notification(%{
            user_id: post.user_id,
            origin_user_id: user_id,
            post_id: post_id,
            type: :like
          })
      end

      Phoenix.PubSub.broadcast(
        SocialApp.PubSub,
        "post:#{post_id}",
        {:post_liked, post_id, post.likes_count}
      )

      post
    end)
  end

  def add_comment(user_id, post_id, attrs) do
    attrs =
      attrs
      |> Map.new()
      |> Map.put(:user_id, user_id)
      |> Map.put(:post_id, post_id)

    case %Comment{} |> Comment.changeset(attrs) |> Repo.insert() do
      {:ok, comment} ->
        post = Repo.get!(Post, post_id)

        if post.user_id != user_id do
          _ =
            Notifications.create_notification(%{
              user_id: post.user_id,
              origin_user_id: user_id,
              post_id: post_id,
              type: :comment
            })
        end

        Phoenix.PubSub.broadcast(
          SocialApp.PubSub,
          "post:#{post_id}",
          {:comment_created, post_id, comment.id}
        )

        {:ok, comment}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def list_comments(post_id, limit \\ 50) do
    from(c in Comment,
      where: c.post_id == ^post_id,
      order_by: [asc: c.inserted_at],
      preload: [:user],
      limit: ^limit
    )
    |> Repo.all()
  end

  defp maybe_exclude_post_author(query, nil), do: query

  defp maybe_exclude_post_author(query, user_id) do
    from([p, u] in query, where: u.id != ^user_id)
  end

  defp apply_recruitment_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:q, q}, acc when is_binary(q) and q != "" ->
        pattern = "%#{q}%"

        from([p, u] in acc,
          where:
            ilike(p.content, ^pattern) or ilike(u.username, ^pattern) or
              ilike(u.headline, ^pattern) or ilike(u.position, ^pattern) or
              ilike(u.region, ^pattern) or ilike(p.competition, ^pattern) or
              ilike(p.opponent, ^pattern)
        )

      {:region, region}, acc when is_binary(region) and region != "" ->
        from([_p, u] in acc, where: u.region == ^region)

      {:role, role}, acc when role in [:player, :coach, :agent, :scout, :club] ->
        from([_p, u] in acc, where: u.role == ^role)

      {:level, level}, acc when level in [:espoir, :confirme, :elite] ->
        from([_p, u] in acc, where: u.level == ^level)

      {:availability, availability}, acc when availability in [:open, :monitoring, :closed] ->
        from([_p, u] in acc, where: u.availability == ^availability)

      _, acc ->
        acc
    end)
  end

  defp apply_recruitment_order(query, viewer_region) do
    from([p, u] in query,
      order_by: [
        desc: fragment("CASE WHEN ? = 'open' THEN 1 ELSE 0 END", u.availability),
        desc:
          fragment(
            "CASE WHEN COALESCE(?, '') <> '' AND ? = ? THEN 1 ELSE 0 END",
            u.region,
            u.region,
            ^viewer_region
          ),
        desc: fragment("COALESCE(?, 0)", p.confidence_score),
        desc: p.inserted_at
      ]
    )
  end
end
