defmodule SocialAppWeb.FeedLive do
  use SocialAppWeb, :live_view

  alias SocialApp.{Accounts, Feed, Labels, Posts, Recruitment}
  alias SocialApp.Repo
  alias SocialAppWeb.Presence

  @post_format_values ~w(post photo video article)
  @intention_values ~w(entertainment showcase recruitment)

  @feed_tabs [
    %{value: "for_you", label: "Pour vous"},
    %{value: "following", label: "Abonnes"},
    %{value: "talents", label: "Talents"},
    %{value: "opportunities", label: "Opportunites"}
  ]
  @feed_tab_values Enum.map(@feed_tabs, & &1.value)

  @feed_sorts [
    %{value: "relevance", label: "Pertinence"},
    %{value: "recent", label: "Recent"}
  ]
  @feed_sort_values Enum.map(@feed_sorts, & &1.value)

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id
    post_form_values = default_post_form_values()

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
       mini_coach: %{
         page: "terrain",
         where: "Terrain (feed principal)",
         goal: "Voir du contenu foot, puis publier en quelques secondes",
         next: "Clique sur 'Quoi de neuf ?' pour commencer.",
         cta_to: ~p"/talents",
         cta_label: "Ouvrir talents"
       },
       current_user_id: user_id,
       composer_open: false,
       pending_new_posts_count: 0,
       feed_tab: "for_you",
       feed_sort: "relevance",
       followed_user_ids: [],
       posts: [],
       suggestions: [],
       post_form_values: post_form_values,
       post_form: to_form(post_form_values, as: :post),
       shortlist_by_post: %{}
     )
     |> refresh_feed()}
  end

  @impl true
  def handle_event("open_composer", params, socket) do
    values =
      socket.assigns.post_form_values
      |> maybe_override_format(params["format"])
      |> maybe_override_intention(params["intention"])

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
    attrs = build_post_attrs(post_params)

    case Posts.create_post(socket.assigns.current_user_id, attrs) do
      {:ok, post} ->
        post = Repo.preload(post, :user)

        {:noreply,
         socket
         |> update(:posts, fn posts -> [post | posts] end)
         |> assign(:composer_open, false)
         |> assign(:pending_new_posts_count, 0)
         |> assign_post_form(default_post_form_values())
         |> refresh_feed()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Impossible de publier le post")}
    end
  end

  @impl true
  def handle_event("set_feed_tab", %{"tab" => tab}, socket) do
    {:noreply,
     socket
     |> assign(:feed_tab, parse_feed_tab(tab))
     |> assign(:pending_new_posts_count, 0)
     |> refresh_feed()}
  end

  @impl true
  def handle_event("set_feed_sort", %{"sort" => sort}, socket) do
    {:noreply,
     socket
     |> assign(:feed_sort, parse_feed_sort(sort))
     |> assign(:pending_new_posts_count, 0)
     |> refresh_feed()}
  end

  @impl true
  def handle_event("show_new_posts", _params, socket) do
    {:noreply,
     socket
     |> assign(:pending_new_posts_count, 0)
     |> refresh_feed()}
  end

  @impl true
  def handle_event("like", %{"post_id" => post_id}, socket) do
    _ = Posts.like_post(socket.assigns.current_user_id, String.to_integer(post_id))
    {:noreply, refresh_feed(socket)}
  end

  @impl true
  def handle_event("toggle_follow_user", %{"user_id" => user_id}, socket) do
    user_id = String.to_integer(user_id)
    current_user_id = socket.assigns.current_user_id

    if user_id in socket.assigns.followed_user_ids do
      _ = Accounts.unfollow_user(current_user_id, user_id)
    else
      _ = Accounts.follow_user(current_user_id, user_id)
    end

    {:noreply, refresh_feed(socket)}
  end

  @impl true
  def handle_event("toggle_shortlist", %{"post_id" => post_id}, socket) do
    post_id = String.to_integer(post_id)
    _ = Recruitment.toggle_shortlist(socket.assigns.current_user_id, post_id)

    {:noreply, refresh_feed(socket)}
  end

  @impl true
  def handle_event("advance_stage", %{"post_id" => post_id}, socket) do
    post_id = String.to_integer(post_id)
    _ = Recruitment.advance_stage(socket.assigns.current_user_id, post_id)

    {:noreply, refresh_feed(socket)}
  end

  @impl true
  def handle_info({:new_post, post}, socket) do
    post = Repo.preload(post, :user)

    if post_matches_tab?(
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
  def handle_info({:post_liked, _post_id, _likes_count}, socket) do
    {:noreply, refresh_feed(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="feed-layout">
      <aside class="feed-sidebar-left stack-md">
        <section class="sidebar-brand-block" aria-label="Identite GoalZone">
          <a href={~p"/"} class="sidebar-brand-logo">GoalZone</a>
          <p class="sidebar-brand-tag">Reseau social football</p>
        </section>

        <section class="panel panel-compact sidebar-panel">
          <h2 class="sidebar-title">Navigation</h2>
          <nav class="sidebar-nav">
            <a href={~p"/"} class="sidebar-nav-link sidebar-nav-link-active">Terrain</a>
            <a href={~p"/talents"} class="sidebar-nav-link">Talents</a>
            <a href={~p"/reseau"} class="sidebar-nav-link">Reseau</a>
            <a href={~p"/messages"} class="sidebar-nav-link">Messages</a>
            <a href={~p"/alertes"} class="sidebar-nav-link">Alertes</a>
            <a href={~p"/profile/#{@current_user.username}"} class="sidebar-nav-link">Profil</a>
          </nav>

          <button type="button" class="btn sidebar-publish-btn" phx-click="open_composer">
            Publier
          </button>
        </section>

        <section class="panel panel-compact sidebar-panel">
          <p class="label-caps">Compte</p>
          <p class="meta-line">{@current_user.email}</p>
          <div class="post-actions">
            <.link href={~p"/users/settings"} class="ghost-link">Settings</.link>
            <.link href={~p"/users/log_out"} method="delete" class="ghost-link">Log out</.link>
          </div>
        </section>
      </aside>

      <main class="feed-main-column stack-md">
        <section class="panel panel-compact feed-toolbar feed-toolbar-sticky">
          <div class="feed-tabs">
            <button
              :for={tab <- feed_tabs()}
              type="button"
              phx-click="set_feed_tab"
              phx-value-tab={tab.value}
              class={["feed-tab", @feed_tab == tab.value && "feed-tab-active"]}
            >
              {tab.label}
            </button>
          </div>

          <form phx-change="set_feed_sort" class="feed-sort-form">
            <label for="feed-sort" class="meta-line">Classer par</label>
            <select id="feed-sort" name="sort" class="field-input feed-sort-select">
              <option
                :for={sort <- feed_sorts()}
                value={sort.value}
                selected={@feed_sort == sort.value}
              >
                {sort.label}
              </option>
            </select>
          </form>
        </section>

        <section class="panel panel-compact composer-shell">
          <div class="composer-top-row">
            <div class="composer-avatar">{avatar_initial(@current_user.username)}</div>
            <button type="button" class="composer-trigger" phx-click="open_composer">
              Quoi de neuf sur le terrain ?
            </button>
            <div class="composer-inline-actions">
              <button
                type="button"
                class="composer-icon-action composer-icon-video"
                phx-click="open_composer"
                phx-value-format="video"
                aria-label="Video highlight"
                title="Video highlight"
                data-tooltip="Video highlight"
              >
                <svg viewBox="0 0 24 24" aria-hidden="true">
                  <path d="M5 6h9a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2z" />
                  <path d="M16 10.5 21 8v8l-5-2.5z" />
                </svg>
              </button>
              <button
                type="button"
                class="composer-icon-action composer-icon-photo"
                phx-click="open_composer"
                phx-value-format="photo"
                aria-label="Photo du terrain"
                title="Photo du terrain"
                data-tooltip="Photo du terrain"
              >
                <svg viewBox="0 0 24 24" aria-hidden="true">
                  <rect x="3" y="5" width="18" height="14" rx="2" ry="2" />
                  <circle cx="9" cy="10" r="1.8" />
                  <path d="m21 15-4.5-4.5L8 19" />
                </svg>
              </button>
              <button
                type="button"
                class="composer-icon-action composer-icon-article"
                phx-click="open_composer"
                phx-value-format="article"
                aria-label="Rediger un article"
                title="Rediger un article"
                data-tooltip="Rediger un article"
              >
                <svg viewBox="0 0 24 24" aria-hidden="true">
                  <path d="M8 4h10l3 3v13a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z" />
                  <path d="M18 4v4h4" />
                  <path d="M10 12h8M10 16h8M10 8h4" />
                </svg>
              </button>
            </div>
          </div>
        </section>

        <form
          :if={@composer_open}
          phx-submit="create_post"
          phx-change="post_form_changed"
          class="panel stack-md"
        >
          <% post_format = @post_form[:post_format].value || "post" %>
          <% intention = @post_form[:intention].value || "entertainment" %>
          <% structured = structured_intention?(intention) %>

          <div class="composer-head">
            <p class="kicker">Creation</p>
            <button type="button" class="ghost-link" phx-click="close_composer">Fermer</button>
          </div>

          <label class="field-label">Format</label>
          <div class="format-picker">
            <label
              :for={option <- post_format_options()}
              class={["format-chip", post_format == option.value && "format-chip-active"]}
            >
              <input
                type="radio"
                name={@post_form[:post_format].name}
                value={option.value}
                checked={post_format == option.value}
              />
              <span>{option.label}</span>
            </label>
          </div>

          <div class="filters-grid">
            <label class="field-wrap">
              <span class="field-label">Objectif du contenu</span>
              <select name={@post_form[:intention].name} class="field-input">
                <option
                  :for={option <- intention_options()}
                  value={option.value}
                  selected={intention == option.value}
                >
                  {option.label}
                </option>
              </select>
            </label>

            <label :if={post_format in ~w(photo video)} class="field-wrap">
              <span class="field-label">Lien media</span>
              <input
                type="url"
                name={@post_form[:media_url].name}
                value={@post_form[:media_url].value}
                class="field-input"
                placeholder="https://..."
              />
            </label>
          </div>

          <label class="field-label" for="new_post">Description</label>
          <textarea
            id="new_post"
            name={@post_form[:content].name}
            rows="4"
            maxlength="500"
            class="composer-textarea"
            placeholder={composer_placeholder(post_format, intention)}
          ><%= @post_form[:content].value %></textarea>

          <div :if={structured} class="filters-grid">
            <label class="field-wrap">
              <span class="field-label">Competition</span>
              <input
                name={@post_form[:competition].name}
                value={@post_form[:competition].value}
                class="field-input"
              />
            </label>
            <label class="field-wrap">
              <span class="field-label">Adversaire</span>
              <input
                name={@post_form[:opponent].name}
                value={@post_form[:opponent].value}
                class="field-input"
              />
            </label>
            <label class="field-wrap">
              <span class="field-label">Minute</span>
              <input
                type="number"
                min="0"
                max="130"
                name={@post_form[:match_minute].name}
                value={@post_form[:match_minute].value}
                class="field-input"
              />
            </label>
            <label class="field-wrap">
              <span class="field-label">Source</span>
              <select name={@post_form[:source_type].name} class="field-input">
                <option
                  value="highlight_video"
                  selected={@post_form[:source_type].value == "highlight_video"}
                >
                  Video highlight
                </option>
                <option
                  value="full_match_video"
                  selected={@post_form[:source_type].value == "full_match_video"}
                >
                  Video match complet
                </option>
                <option
                  value="live_observation"
                  selected={@post_form[:source_type].value == "live_observation"}
                >
                  Observation live
                </option>
                <option value="stat_report" selected={@post_form[:source_type].value == "stat_report"}>
                  Rapport stats
                </option>
                <option value="unknown" selected={@post_form[:source_type].value == "unknown"}>
                  Non precise
                </option>
              </select>
            </label>
            <label class="field-wrap">
              <span class="field-label">Confiance (%)</span>
              <input
                type="number"
                min="0"
                max="100"
                name={@post_form[:confidence_score].name}
                value={@post_form[:confidence_score].value}
                class="field-input"
              />
            </label>
          </div>

          <div class="post-actions">
            <.button type="submit">Publier</.button>
            <button type="button" class="ghost-link" phx-click="close_composer">Annuler</button>
          </div>
        </form>

        <button
          :if={@pending_new_posts_count > 0}
          type="button"
          phx-click="show_new_posts"
          class="panel panel-compact new-posts-banner"
        >
          Voir {@pending_new_posts_count} nouveaux posts
        </button>

        <section :if={@posts == []} class="panel stack-md feed-empty-state">
          <h2 class="section-title">{empty_state_title(@feed_tab)}</h2>
          <p class="section-subtitle">{empty_state_hint(@feed_tab)}</p>
          <div class="post-actions">
            <button type="button" class="btn" phx-click="open_composer" phx-value-intention="showcase">
              Publier un highlight
            </button>
            <a href={~p"/talents"} class="ghost-link">Suivre des talents</a>
            <a href={~p"/reseau"} class="ghost-link">Explorer le reseau</a>
          </div>
        </section>

        <div :if={@posts != []} class="feed-stream stack-md">
          <article :for={post <- @posts} class="panel feed-post-card">
            <div class="meta-line">@{(post.user && post.user.username) || "inconnu"}</div>
            <div class="status-row">
              <span class="status-pill status-pill-muted">{post_format_label(post.post_format)}</span>
              <span class="status-pill status-pill-muted">{intention_label(post.intention)}</span>
              <span
                :if={post.source_type && post.source_type != :unknown}
                class="status-pill status-pill-muted"
              >
                Source: {source_type_label(post.source_type)}
              </span>
              <a
                :if={post.media_url}
                href={post.media_url}
                target="_blank"
                rel="noopener noreferrer"
                class="text-link"
              >
                Ouvrir media
              </a>
            </div>
            <p class="post-content">{post.content}</p>
            <p :if={structured_post?(post)} class="meta-line">
              {post.competition || "Match"} {if post.opponent, do: "· vs #{post.opponent}", else: ""}
              {if post.match_minute, do: "· #{post.match_minute}'", else: ""}
            </p>
            <div class="post-actions">
              <.button class="btn-like" phx-click="like" phx-value-post_id={post.id}>
                Supporters: {post.likes_count}
              </.button>
              <button class="ghost-link" phx-click="toggle_shortlist" phx-value-post_id={post.id}>
                {if Map.has_key?(@shortlist_by_post, post.id),
                  do: "Retirer pipeline",
                  else: "Ajouter pipeline"}
              </button>
              <button
                :if={Map.has_key?(@shortlist_by_post, post.id)}
                class="ghost-link"
                phx-click="advance_stage"
                phx-value-post_id={post.id}
              >
                Etape: {Labels.stage_label(@shortlist_by_post[post.id].stage)}
              </button>
              <a href={~p"/posts/#{post.id}"} class="text-link">Debrief</a>
              <a href={~p"/profile/#{post.user.username}"} class="text-link">Profil</a>
            </div>
          </article>
        </div>
      </main>

      <aside class="feed-sidebar-right stack-md">
        <section class="panel panel-compact sidebar-panel">
          <div class="post-actions">
            <h2 class="sidebar-title">Suggestions a suivre</h2>
            <span class="meta-line">{length(@suggestions)}</span>
          </div>

          <div class="suggestion-list">
            <article :for={user <- @suggestions} class="suggestion-item">
              <div class="suggestion-main">
                <a href={~p"/profile/#{user.username}"} class="text-link">@{user.username}</a>
                <p class="meta-line">
                  {Labels.role_label(user.role)} · {Labels.level_label(user.level)}
                </p>
                <p class="meta-line">{fallback_headline(user.headline)}</p>
              </div>
              <button class="ghost-link" phx-click="toggle_follow_user" phx-value-user_id={user.id}>
                {if user.id in @followed_user_ids, do: "Suivi", else: "Suivre"}
              </button>
            </article>
          </div>

          <p :if={@suggestions == []} class="meta-line">Aucune suggestion pour le moment.</p>
        </section>
      </aside>
    </section>
    """
  end

  defp refresh_feed(socket) do
    user_id = socket.assigns.current_user_id
    followed_ids = Accounts.list_followed_ids(user_id)
    tab = parse_feed_tab(socket.assigns.feed_tab)
    sort = parse_feed_sort(socket.assigns.feed_sort)

    all_posts = Feed.home_feed_for_user(user_id, limit: 80)

    posts =
      all_posts
      |> filter_feed_tab(tab, user_id, followed_ids)
      |> sort_feed(sort)
      |> Enum.take(20)

    shortlist =
      Recruitment.list_entries(user_id, limit: 200)
      |> Map.new(fn entry -> {entry.post_id, entry} end)

    suggestions =
      Accounts.list_directory(%{}, exclude_user_id: user_id, limit: 120)
      |> Enum.reject(&(&1.id in followed_ids))
      |> Enum.take(8)

    socket
    |> assign(:feed_tab, tab)
    |> assign(:feed_sort, sort)
    |> assign(:followed_user_ids, followed_ids)
    |> assign(:posts, posts)
    |> assign(:suggestions, suggestions)
    |> assign(:shortlist_by_post, shortlist)
  end

  defp assign_post_form(socket, values) do
    values = normalize_post_form_values(values)

    socket
    |> assign(:post_form_values, values)
    |> assign(:post_form, to_form(values, as: :post))
  end

  defp build_post_attrs(params) do
    intention = parse_intention(params["intention"])
    structured = structured_intention?(intention)

    %{
      content: String.trim(params["content"] || ""),
      post_format: parse_post_format(params["post_format"]),
      intention: intention,
      media_url: blank_to_nil(params["media_url"]),
      competition: if(structured, do: blank_to_nil(params["competition"]), else: nil),
      opponent: if(structured, do: blank_to_nil(params["opponent"]), else: nil),
      match_minute: if(structured, do: parse_int(params["match_minute"]), else: nil),
      source_type: if(structured, do: parse_source_type(params["source_type"]), else: :unknown),
      confidence_score: if(structured, do: parse_int(params["confidence_score"]), else: nil),
      verification_status: :self_declared
    }
  end

  defp default_post_form_values do
    %{
      "content" => "",
      "post_format" => "post",
      "intention" => "entertainment",
      "media_url" => "",
      "competition" => "",
      "opponent" => "",
      "match_minute" => "",
      "source_type" => "highlight_video",
      "confidence_score" => ""
    }
  end

  defp normalize_post_form_values(params) do
    params = params || %{}
    Map.merge(default_post_form_values(), Map.new(params))
  end

  defp maybe_override_format(values, nil), do: values

  defp maybe_override_format(values, format) do
    Map.put(values, "post_format", format |> parse_post_format() |> Atom.to_string())
  end

  defp maybe_override_intention(values, nil), do: values

  defp maybe_override_intention(values, intention) do
    Map.put(values, "intention", intention |> parse_intention() |> Atom.to_string())
  end

  defp feed_tabs, do: @feed_tabs
  defp feed_sorts, do: @feed_sorts

  defp post_format_options do
    [
      %{value: "post", label: "Post"},
      %{value: "photo", label: "Photo"},
      %{value: "video", label: "Video"},
      %{value: "article", label: "Article"}
    ]
  end

  defp intention_options do
    [
      %{value: "entertainment", label: "Divertir"},
      %{value: "showcase", label: "Me faire reperer"},
      %{value: "recruitment", label: "Recruter / scouter"}
    ]
  end

  defp empty_state_title("following"), do: "Ton fil Abonnes est vide pour le moment"
  defp empty_state_title("talents"), do: "Aucun talent actif sur ce filtre"
  defp empty_state_title("opportunities"), do: "Aucune opportunite visible pour l'instant"
  defp empty_state_title(_), do: "Le terrain attend ton premier mouvement"

  defp empty_state_hint("following"),
    do: "Suis plus de profils pour alimenter ton fil personnalise."

  defp empty_state_hint("talents"),
    do: "Publie en mode performance ou suis des joueurs pour remplir cet onglet."

  defp empty_state_hint("opportunities"),
    do: "Publie une recherche ciblee pour declencher des contacts."

  defp empty_state_hint(_),
    do: "Commence par publier un highlight puis connecte-toi a des profils pertinents."

  defp filter_feed_tab(posts, "for_you", _user_id, _followed_ids), do: posts

  defp filter_feed_tab(posts, "following", user_id, followed_ids) do
    Enum.filter(posts, fn post -> post.user_id == user_id or post.user_id in followed_ids end)
  end

  defp filter_feed_tab(posts, "talents", _user_id, _followed_ids) do
    Enum.filter(posts, &(post_intention(&1) == :showcase))
  end

  defp filter_feed_tab(posts, "opportunities", _user_id, _followed_ids) do
    Enum.filter(posts, &(post_intention(&1) == :recruitment))
  end

  defp filter_feed_tab(posts, _tab, _user_id, _followed_ids), do: posts

  defp sort_feed(posts, "recent"), do: posts

  defp sort_feed(posts, "relevance") do
    Enum.sort_by(posts, fn post -> {relevance_score(post), post.inserted_at} end, :desc)
  end

  defp sort_feed(posts, _), do: posts

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

  defp post_matches_tab?(post, tab, user_id, followed_ids) do
    post_matches_tab_inner?(post, parse_feed_tab(tab), user_id, followed_ids)
  end

  defp post_matches_tab_inner?(post, "for_you", _user_id, _followed_ids), do: not is_nil(post)

  defp post_matches_tab_inner?(post, "following", user_id, followed_ids) do
    post.user_id == user_id or post.user_id in followed_ids
  end

  defp post_matches_tab_inner?(post, "talents", _user_id, _followed_ids),
    do: post_intention(post) == :showcase

  defp post_matches_tab_inner?(post, "opportunities", _user_id, _followed_ids),
    do: post_intention(post) == :recruitment

  defp post_matches_tab_inner?(post, _tab, _user_id, _followed_ids), do: not is_nil(post)

  defp post_intention(%{intention: value}) when is_binary(value), do: parse_intention(value)
  defp post_intention(%{intention: value}) when is_atom(value), do: value
  defp post_intention(_), do: :entertainment

  defp composer_placeholder("article", _),
    do: "Partage une analyse, une histoire de match ou ton point de vue football..."

  defp composer_placeholder("photo", _),
    do: "Decris la photo: contexte, energie du moment, ce qu'on doit regarder..."

  defp composer_placeholder("video", "showcase"),
    do: "Explique l'action: contexte, decision prise, impact sur le jeu..."

  defp composer_placeholder("video", "recruitment"),
    do: "Explique ce que le recruteur doit observer sur cette video..."

  defp composer_placeholder(_, "recruitment"),
    do: "Decris le profil recherche ou l'opportunite (poste, niveau, criteres)..."

  defp composer_placeholder(_, "showcase"),
    do: "Decris l'action ou la performance que tu veux mettre en avant..."

  defp composer_placeholder(_, _),
    do: "Partage un moment foot marquant pour la communaute..."

  defp parse_int(nil), do: nil
  defp parse_int(""), do: nil

  defp parse_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} -> parsed
      _ -> nil
    end
  end

  defp parse_int(value) when is_integer(value), do: value
  defp parse_int(_), do: nil

  defp parse_source_type("highlight_video"), do: :highlight_video
  defp parse_source_type("full_match_video"), do: :full_match_video
  defp parse_source_type("live_observation"), do: :live_observation
  defp parse_source_type("stat_report"), do: :stat_report
  defp parse_source_type(_), do: :unknown

  defp parse_post_format(value) when value in @post_format_values, do: String.to_atom(value)
  defp parse_post_format(_), do: :post

  defp parse_intention(value) when value in @intention_values, do: String.to_atom(value)
  defp parse_intention(_), do: :entertainment

  defp parse_feed_tab(value) when value in @feed_tab_values, do: value
  defp parse_feed_tab(_), do: "for_you"

  defp parse_feed_sort(value) when value in @feed_sort_values, do: value
  defp parse_feed_sort(_), do: "relevance"

  defp structured_intention?(value) when is_binary(value), do: value in ~w(showcase recruitment)
  defp structured_intention?(value), do: value in [:showcase, :recruitment]

  defp structured_post?(post), do: structured_intention?(post.intention)

  defp post_format_label(:post), do: "Post"
  defp post_format_label(:photo), do: "Photo"
  defp post_format_label(:video), do: "Video"
  defp post_format_label(:article), do: "Article"

  defp post_format_label(value) when is_binary(value),
    do: post_format_label(parse_post_format(value))

  defp post_format_label(_), do: "Post"

  defp intention_label(:entertainment), do: "Divertissement"
  defp intention_label(:showcase), do: "Performance"
  defp intention_label(:recruitment), do: "Recrutement"
  defp intention_label(value) when is_binary(value), do: intention_label(parse_intention(value))
  defp intention_label(_), do: "Divertissement"

  defp source_type_label(:highlight_video), do: "Highlight video"
  defp source_type_label(:full_match_video), do: "Match complet"
  defp source_type_label(:live_observation), do: "Observation live"
  defp source_type_label(:stat_report), do: "Rapport stats"

  defp source_type_label(value) when is_binary(value),
    do: source_type_label(parse_source_type(value))

  defp source_type_label(_), do: "Non precise"

  defp avatar_initial(nil), do: "U"

  defp avatar_initial(username) when is_binary(username) do
    case String.trim(username) do
      "" -> "U"
      value -> value |> String.first() |> String.upcase()
    end
  end

  defp avatar_initial(_), do: "U"

  defp fallback_headline(nil), do: "Profil en cours de qualification"
  defp fallback_headline(""), do: "Profil en cours de qualification"
  defp fallback_headline(value), do: value

  defp blank_to_nil(nil), do: nil

  defp blank_to_nil(value) do
    value = String.trim(value)
    if value == "", do: nil, else: value
  end
end
