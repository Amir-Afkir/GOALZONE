defmodule SocialAppWeb.FeedLive.Stream do
  @moduledoc false

  alias SocialAppWeb.FeedLive.Params

  def filter_feed_tab(posts, "for_you", _user_id, _followed_ids), do: posts

  def filter_feed_tab(posts, "following", user_id, followed_ids) do
    Enum.filter(posts, fn post -> post.user_id == user_id or post.user_id in followed_ids end)
  end

  def filter_feed_tab(posts, "mercato", _user_id, _followed_ids) do
    Enum.filter(posts, &(post_intention(&1) == :showcase))
  end

  def filter_feed_tab(posts, "opportunities", _user_id, _followed_ids) do
    Enum.filter(posts, &(post_intention(&1) == :recruitment))
  end

  def filter_feed_tab(posts, _tab, _user_id, _followed_ids), do: posts

  def sort_feed(posts, "recent"), do: posts

  def sort_feed(posts, "relevance") do
    Enum.sort_by(posts, fn post -> {relevance_score(post), post.inserted_at} end, :desc)
  end

  def sort_feed(posts, _), do: posts

  def post_matches_tab?(post, tab, user_id, followed_ids) do
    post_matches_tab_inner?(post, Params.parse_feed_tab(tab), user_id, followed_ids)
  end

  defp post_matches_tab_inner?(post, "for_you", _user_id, _followed_ids), do: not is_nil(post)

  defp post_matches_tab_inner?(post, "following", user_id, followed_ids) do
    post.user_id == user_id or post.user_id in followed_ids
  end

  defp post_matches_tab_inner?(post, "mercato", _user_id, _followed_ids),
    do: post_intention(post) == :showcase

  defp post_matches_tab_inner?(post, "opportunities", _user_id, _followed_ids),
    do: post_intention(post) == :recruitment

  defp post_matches_tab_inner?(post, _tab, _user_id, _followed_ids), do: not is_nil(post)

  defp relevance_score(post) do
    intent_boost =
      case post_intention(post) do
        :showcase -> 4
        :recruitment -> 3
        _ -> 1
      end

    freshness_boost = if recent_post?(post), do: 2, else: 0
    (post.likes_count || 0) * 3 + intent_boost + freshness_boost
  end

  defp recent_post?(%{inserted_at: %DateTime{} = inserted_at}) do
    DateTime.diff(DateTime.utc_now(), inserted_at, :hour) <= 24
  end

  defp recent_post?(%{inserted_at: %NaiveDateTime{} = inserted_at}) do
    now = DateTime.utc_now() |> DateTime.to_naive()
    NaiveDateTime.diff(now, inserted_at, :hour) <= 24
  end

  defp recent_post?(_), do: false

  defp post_intention(%{intention: value}) when is_binary(value),
    do: Params.parse_intention(value)

  defp post_intention(%{intention: value}) when is_atom(value), do: value
  defp post_intention(_), do: :entertainment
end
