defmodule SocialAppWeb.FeedLive do
  use SocialAppWeb, :live_view

  alias SocialApp.{Accounts, Feed, Posts, Recruitment}
  alias SocialApp.Repo
  alias SocialAppWeb.Presence
  alias SocialAppWeb.FeedLive.{Components, Params, Stream}

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id
    post_form_values = Params.default_post_form_values()

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SocialApp.PubSub, "user:#{user_id}")
      Presence.track(self(), "user:#{user_id}", user_id, %{online_at: DateTime.utc_now()})
    end

    {:ok,
     assign(socket,
       page_context: "Terrain",
       use_sidebar_nav: true,
       use_wide_layout: true,
       hide_app_header: true,
       mini_coach: nil,
       current_user_id: user_id,
       composer_open: false,
       pending_new_posts_count: 0,
       feed_tab: Params.parse_feed_tab("for_you"),
       feed_sort: Params.parse_feed_sort("relevance"),
       feed_tabs: Params.feed_tabs(),
       feed_sorts: Params.feed_sorts(),
       followed_user_ids: [],
       posts: [],
       suggestions: [],
       post_form_values: post_form_values,
       post_form: to_form(post_form_values, as: :post),
       shortlist_by_post: %{}
     )
     |> load_initial_feed()}
  end

  @impl true
  def handle_event("open_composer", params, socket) do
    values =
      socket.assigns.post_form_values
      |> Params.override_format(params["format"])
      |> Params.override_intention(params["intention"])

    {:noreply,
     socket
     |> assign(:composer_open, true)
     |> assign_post_form(values)}
  end

  @impl true
  def handle_event("close_composer", _params, socket) do
    {:noreply, assign(socket, :composer_open, false)}
  end

  @impl true
  def handle_event("post_form_changed", %{"post" => post_params}, socket) do
    {:noreply,
     socket
     |> assign(:composer_open, true)
     |> assign_post_form(post_params)}
  end

  @impl true
  def handle_event("create_post", %{"post" => post_params}, socket) do
    attrs = Params.build_post_attrs(post_params)

    case Posts.create_post(socket.assigns.current_user_id, attrs) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> assign(:composer_open, false)
         |> assign(:pending_new_posts_count, 0)
         |> assign_post_form(Params.default_post_form_values())
         |> reload_posts()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Impossible de publier le post")}
    end
  end

  @impl true
  def handle_event("set_feed_tab", %{"tab" => tab}, socket) do
    {:noreply,
     socket
     |> assign(:feed_tab, Params.parse_feed_tab(tab))
     |> assign(:pending_new_posts_count, 0)
     |> reload_posts()}
  end

  @impl true
  def handle_event("set_feed_sort", %{"sort" => sort}, socket) do
    {:noreply,
     socket
     |> assign(:feed_sort, Params.parse_feed_sort(sort))
     |> assign(:pending_new_posts_count, 0)
     |> reload_posts()}
  end

  @impl true
  def handle_event("show_new_posts", _params, socket) do
    {:noreply,
     socket
     |> assign(:pending_new_posts_count, 0)
     |> reload_posts()}
  end

  @impl true
  def handle_event("like", %{"post_id" => post_id}, socket) do
    with {:ok, parsed_id} <- parse_required_id(post_id),
         {:ok, post} <- Posts.like_post(socket.assigns.current_user_id, parsed_id) do
      {:noreply, apply_like_update(socket, post.id, post.likes_count || 0)}
    else
      {:error, :invalid_id} ->
        {:noreply, put_flash(socket, :error, "Action invalide")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Impossible de traiter le like")}
    end
  end

  @impl true
  def handle_event("toggle_follow_user", %{"user_id" => user_id}, socket) do
    with {:ok, parsed_id} <- parse_required_id(user_id) do
      current_user_id = socket.assigns.current_user_id

      if parsed_id in socket.assigns.followed_user_ids do
        _ = Accounts.unfollow_user(current_user_id, parsed_id)
      else
        _ = Accounts.follow_user(current_user_id, parsed_id)
      end

      {:noreply,
       socket
       |> reload_follow_state()
       |> reload_posts()}
    else
      {:error, :invalid_id} ->
        {:noreply, put_flash(socket, :error, "Action invalide")}
    end
  end

  @impl true
  def handle_event("toggle_shortlist", %{"post_id" => post_id}, socket) do
    with {:ok, parsed_id} <- parse_required_id(post_id),
         _ <- Recruitment.toggle_shortlist(socket.assigns.current_user_id, parsed_id) do
      {:noreply, update_shortlist_entry(socket, parsed_id)}
    else
      {:error, :invalid_id} ->
        {:noreply, put_flash(socket, :error, "Action invalide")}
    end
  end

  @impl true
  def handle_event("advance_stage", %{"post_id" => post_id}, socket) do
    with {:ok, parsed_id} <- parse_required_id(post_id),
         _ <- Recruitment.advance_stage(socket.assigns.current_user_id, parsed_id) do
      {:noreply, update_shortlist_entry(socket, parsed_id)}
    else
      {:error, :invalid_id} ->
        {:noreply, put_flash(socket, :error, "Action invalide")}
    end
  end

  @impl true
  def handle_info({:new_post, post}, socket) do
    post = maybe_preload_post_user(post)

    if Stream.post_matches_tab?(
         post,
         socket.assigns.feed_tab,
         socket.assigns.current_user_id,
         socket.assigns.followed_user_ids
       ) do
      {:noreply, update(socket, :pending_new_posts_count, &(&1 + 1))}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:post_liked, post_id, likes_count}, socket) do
    {:noreply, apply_like_update(socket, post_id, likes_count)}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns), do: Components.render(assigns)

  defp load_initial_feed(socket) do
    socket
    |> reload_follow_state()
    |> reload_posts()
    |> reload_shortlist()
  end

  defp reload_follow_state(socket) do
    user_id = socket.assigns.current_user_id
    followed_ids = Accounts.list_followed_ids(user_id)

    suggestions =
      Accounts.list_directory(%{}, exclude_user_id: user_id, limit: 120)
      |> Enum.reject(&(&1.id in followed_ids))
      |> Enum.take(8)

    socket
    |> assign(:followed_user_ids, followed_ids)
    |> assign(:suggestions, suggestions)
  end

  defp reload_posts(socket) do
    user_id = socket.assigns.current_user_id
    followed_ids = socket.assigns.followed_user_ids
    tab = Params.parse_feed_tab(socket.assigns.feed_tab)
    sort = Params.parse_feed_sort(socket.assigns.feed_sort)

    posts =
      Feed.home_feed_for_user(user_id, limit: 80)
      |> Stream.filter_feed_tab(tab, user_id, followed_ids)
      |> Stream.sort_feed(sort)
      |> Enum.take(20)

    socket
    |> assign(:feed_tab, tab)
    |> assign(:feed_sort, sort)
    |> assign(:posts, posts)
  end

  defp reload_shortlist(socket) do
    shortlist =
      Recruitment.list_entries(socket.assigns.current_user_id, limit: 200)
      |> Map.new(fn entry -> {entry.post_id, entry} end)

    assign(socket, :shortlist_by_post, shortlist)
  end

  defp assign_post_form(socket, values) do
    values = Params.normalize_post_form_values(values)

    socket
    |> assign(:post_form_values, values)
    |> assign(:post_form, to_form(values, as: :post))
  end

  defp apply_like_update(socket, post_id, likes_count) do
    updated_posts =
      socket.assigns.posts
      |> Enum.map(fn post ->
        if post.id == post_id do
          %{post | likes_count: likes_count}
        else
          post
        end
      end)
      |> Stream.sort_feed(socket.assigns.feed_sort)
      |> Enum.take(20)

    assign(socket, :posts, updated_posts)
  end

  defp update_shortlist_entry(socket, post_id) do
    entry = Recruitment.get_entry(socket.assigns.current_user_id, post_id)

    shortlist_by_post =
      case entry do
        nil -> Map.delete(socket.assigns.shortlist_by_post, post_id)
        _ -> Map.put(socket.assigns.shortlist_by_post, post_id, entry)
      end

    assign(socket, :shortlist_by_post, shortlist_by_post)
  end

  defp parse_required_id(value) do
    case Params.parse_id(value) do
      nil -> {:error, :invalid_id}
      id -> {:ok, id}
    end
  end

  defp maybe_preload_post_user(post) do
    if Ecto.assoc_loaded?(post.user) do
      post
    else
      Repo.preload(post, :user)
    end
  end
end
