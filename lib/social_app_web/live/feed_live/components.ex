defmodule SocialAppWeb.FeedLive.Components do
  @moduledoc false
  use SocialAppWeb, :html

  alias SocialApp.Labels
  alias SocialAppWeb.FeedLive.Params

  @mock_suggestions [
    %{id: nil, name: "John Nasti", subtitle: "Position - Club", username: nil},
    %{id: nil, name: "Nome Solthan", subtitle: "Position - Club", username: nil},
    %{id: nil, name: "Aani Radun", subtitle: "Position - Club", username: nil}
  ]

  @mock_talents [
    %{name: "Anthon Furton", speed: "32 km/h", pass: "89%"},
    %{name: "James Holtier", speed: "32 km/h", pass: "89%"},
    %{name: "Mikha Doran", speed: "32 km/h", pass: "89%"}
  ]

  @scout_cards [
    %{
      name: "Anthon Furton",
      subtitle: "Position - Club",
      speed: "32 km/h",
      pass: "7%",
      shot: "88%"
    },
    %{
      name: "James Holtier",
      subtitle: "Position - Club",
      speed: "32",
      pass: "45",
      shot: "86%"
    }
  ]

  def render(assigns) do
    assigns =
      assign(assigns,
        left_nav_items: left_nav_items(assigns.current_user),
        display_suggestions: display_suggestions(assigns.suggestions),
        talent_cards: talent_cards(assigns.suggestions),
        scout_cards: @scout_cards
      )

    ~H"""
    <section class="feed-scene">
      <div class="feed-scene-lights" aria-hidden="true"></div>
      <div class="feed-scene-lines" aria-hidden="true"></div>

      <section class="feed-layout">
        <aside class="feed-sidebar-left">
          <div class="feed-sidebar-left-rail">
            <section class="sidebar-brand-block" aria-label="Identite GoalZone">
              <a href={~p"/"} class="sidebar-brand-logo">GoalZone</a>
              <p class="sidebar-brand-tag">Reseau social football</p>
            </section>

            <section class="panel panel-compact sidebar-panel feed-panel feed-panel-soft">
              <div class="sidebar-panel-header">
                <h2 class="sidebar-title">Navigation</h2>
              </div>
              <nav class="sidebar-nav" aria-label="Navigation principale">
                <a
                  :for={item <- @left_nav_items}
                  href={item.href}
                  class={["sidebar-nav-link", item.active && "sidebar-nav-link-active"]}
                >
                  <span class="sidebar-nav-icon">
                    <.nav_icon name={item.icon} />
                  </span>
                  <span class="sidebar-nav-label">{item.label}</span>
                </a>
              </nav>

              <button type="button" class="btn sidebar-publish-btn" phx-click="open_composer">
                Publier
              </button>
            </section>

            <section class="panel panel-compact sidebar-panel feed-panel feed-panel-soft">
              <p class="label-caps sidebar-account-kicker">Compte</p>
              <div class="account-card-row">
                <div class="account-avatar">{avatar_initial(@current_user.username)}</div>
                <div class="account-details">
                  <p class="account-name">{account_display_name(@current_user)}</p>
                  <p class="account-email">{@current_user.email}</p>
                </div>
              </div>
              <p class="account-status">Profil connecte et pret a publier</p>
              <div class="account-actions">
                <.link href={~p"/users/settings"} class="ghost-link">Settings</.link>
                <.link href={~p"/users/log_out"} method="delete" class="ghost-link">Log out</.link>
              </div>
            </section>
          </div>
        </aside>

        <main class="feed-main-column">
          <section class="panel panel-compact feed-toolbar feed-toolbar-sticky feed-panel">
            <div class="feed-tabs">
              <button
                :for={tab <- @feed_tabs}
                type="button"
                phx-click="set_feed_tab"
                phx-value-tab={tab.value}
                class={["feed-tab", @feed_tab == tab.value && "feed-tab-active"]}
              >
                <span>{tab.label}</span>
              </button>
            </div>

            <form phx-change="set_feed_sort" class="feed-sort-form">
              <label for="feed-sort" class="feed-sort-label">
                <span>Classer</span>
                <span>par</span>
              </label>
              <select id="feed-sort" name="sort" class="field-input feed-sort-select">
                <option
                  :for={sort <- @feed_sorts}
                  value={sort.value}
                  selected={@feed_sort == sort.value}
                >
                  {sort.label}
                </option>
              </select>
            </form>
          </section>

          <section class="panel panel-compact composer-shell feed-panel">
            <div class="composer-top-row">
              <div class="composer-avatar">{avatar_initial(@current_user.username)}</div>
              <button type="button" class="composer-trigger" phx-click="open_composer">
                Partage ton highlight (but, passe cle, arret, dribble)...
              </button>
            </div>
            <div class="composer-actions-row">
              <button type="button" class="composer-pill-action" phx-click="open_composer">
                <.composer_icon name="action" />
                <span>Action</span>
              </button>
              <button
                type="button"
                class="composer-pill-action"
                phx-click="open_composer"
                phx-value-format="video"
              >
                <.composer_icon name="video" />
                <span>Video</span>
              </button>
              <button
                type="button"
                class="composer-pill-action"
                phx-click="open_composer"
                phx-value-format="article"
                phx-value-intention="recruitment"
              >
                <.composer_icon name="analysis" />
                <span>Analyse</span>
              </button>
              <button
                type="button"
                class="composer-pill-action"
                phx-click="open_composer"
                phx-value-format="photo"
              >
                <.composer_icon name="photo" />
                <span>Photo</span>
              </button>
            </div>
          </section>

          <form
            :if={@composer_open}
            phx-submit="create_post"
            phx-change="post_form_changed"
            class="panel stack-md feed-panel feed-composer-form"
          >
            <% post_format = @post_form[:post_format].value || "post" %>
            <% intention = @post_form[:intention].value || "entertainment" %>
            <% structured = Params.structured_intention?(intention) %>

            <div class="composer-head">
              <p class="kicker">Creation</p>
              <button type="button" class="ghost-link" phx-click="close_composer">Fermer</button>
            </div>

            <label class="field-label">Format</label>
            <div class="format-picker">
              <label
                :for={option <- Params.post_format_options()}
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
                    :for={option <- Params.intention_options()}
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
              placeholder={Params.composer_placeholder(post_format, intention)}
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
                  <option
                    value="stat_report"
                    selected={@post_form[:source_type].value == "stat_report"}
                  >
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
            class="panel panel-compact new-posts-banner feed-panel"
          >
            Voir {@pending_new_posts_count} nouveaux posts
          </button>

          <section :if={@posts == []} class="panel feed-hero-card feed-panel">
            <div class="feed-hero-copy">
              <h2 class="feed-hero-title">LE TERRAIN ATTEND</h2>
              <p class="feed-hero-subtitle">Ton premier mouvement</p>
            </div>

            <div class="feed-hero-actions">
              <button
                type="button"
                class="btn hero-action-btn"
                phx-click="open_composer"
                phx-value-intention="showcase"
              >
                Publier un highlight
              </button>
              <a href={~p"/talents"} class="hero-outline-btn hero-gold-btn">Suivre des talents</a>
              <a href={~p"/reseau"} class="hero-outline-btn">Explorer le reseau</a>
            </div>

            <div class="feed-hero-ellipse" aria-hidden="true"></div>
          </section>

          <section :if={@posts == []} class="panel feed-talent-strip feed-panel">
            <div class="feed-strip-head">
              <h2 class="sidebar-title">Talents a suivre</h2>
            </div>

            <div class="talent-strip-grid">
              <article :for={card <- @talent_cards} class="talent-preview-card">
                <button type="button" class="talent-preview-close" aria-label="Fermer">x</button>
                <div class="talent-preview-avatar"></div>
                <div class="talent-preview-copy">
                  <p class="talent-preview-name">{card.name}</p>
                  <p class="talent-preview-kpi">Vitesse: {card.speed}</p>
                  <p class="talent-preview-kpi">Passe: {card.pass}</p>
                </div>
              </article>
            </div>
          </section>

          <div :if={@posts != []} class="feed-stream stack-md">
            <article :for={post <- @posts} class="panel feed-post-card feed-panel">
              <div class="meta-line">@{(post.user && post.user.username) || "inconnu"}</div>
              <div class="status-row">
                <span class="status-pill status-pill-muted">
                  {post_format_label(post.post_format)}
                </span>
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

        <aside class="feed-sidebar-right">
          <div class="feed-sidebar-right-rail">
            <section class="panel panel-compact sidebar-panel feed-panel feed-panel-soft">
              <div class="post-actions">
                <h2 class="sidebar-title">Suggestions a suivre</h2>
              </div>

              <div class="suggestion-list suggestion-list-target">
                <article
                  :for={profile <- @display_suggestions}
                  class="suggestion-item suggestion-item-target"
                >
                  <div class="suggestion-avatar-shell">
                    <div class="suggestion-avatar-shape"></div>
                  </div>
                  <div class="suggestion-main">
                    <p class="suggestion-name">{profile.name}</p>
                    <p class="meta-line">{profile.subtitle}</p>
                  </div>
                  <button
                    type="button"
                    class="follow-chip"
                    phx-click={if profile.id, do: "toggle_follow_user", else: nil}
                    phx-value-user_id={profile.id}
                    disabled={is_nil(profile.id)}
                  >
                    Follow
                  </button>
                </article>
              </div>
            </section>

            <div class="feed-rail-stack">
              <article
                :for={card <- @scout_cards}
                class="panel scout-feature-card feed-panel feed-panel-soft"
              >
                <button type="button" class="scout-dismiss" aria-label="Fermer">x</button>
                <div class="scout-head">
                  <div class="suggestion-avatar-shell scout-avatar-shell">
                    <div class="suggestion-avatar-shape"></div>
                  </div>
                  <div>
                    <p class="suggestion-name">{card.name}</p>
                    <p class="meta-line">{card.subtitle}</p>
                  </div>
                </div>

                <div class="scout-kpi-row">
                  <span>Vitesse: {card.speed}</span>
                  <span>Passe: {card.pass}</span>
                  <span>Passe: {card.shot}</span>
                </div>

                <div class="scout-video-shell">
                  <span class="scout-video-label">Highlight reel</span>
                  <div class="scout-video-thumb">
                    <button type="button" class="scout-video-play" aria-label="Lire"></button>
                  </div>
                </div>
              </article>
            </div>
          </div>
        </aside>
      </section>

      <button type="button" class="feed-coach-pill">
        <span class="feed-coach-icon">
          <.coach_icon />
        </span>
        <span>Coach IA</span>
        <span class="feed-coach-close">x</span>
      </button>
    </section>
    """
  end

  attr :name, :string, required: true

  defp nav_icon(assigns) do
    ~H"""
    <svg :if={@name == "terrain"} viewBox="0 0 24 24" aria-hidden="true">
      <circle cx="12" cy="12" r="8"></circle>
      <path d="M12 4v16M4 12h16"></path>
    </svg>
    <svg :if={@name == "talents"} viewBox="0 0 24 24" aria-hidden="true">
      <path d="m12 3 2.7 5.5 6.1.9-4.4 4.2 1 6-5.4-2.9-5.4 2.9 1-6L3.2 9.4l6.1-.9z"></path>
    </svg>
    <svg :if={@name == "reseau"} viewBox="0 0 24 24" aria-hidden="true">
      <circle cx="8" cy="8" r="3"></circle>
      <circle cx="16" cy="7" r="2.5"></circle>
      <path d="M3.5 18a4.5 4.5 0 0 1 9 0"></path>
      <path d="M13 17a3.7 3.7 0 0 1 7.5 0"></path>
    </svg>
    <svg :if={@name == "messages"} viewBox="0 0 24 24" aria-hidden="true">
      <rect x="3" y="5" width="18" height="14" rx="2"></rect>
      <path d="m5 7 7 6 7-6"></path>
    </svg>
    <svg :if={@name == "alertes"} viewBox="0 0 24 24" aria-hidden="true">
      <path d="M12 4a4 4 0 0 0-4 4v2.2c0 1.3-.4 2.5-1.2 3.5L5.5 15h13l-1.3-1.3a5.3 5.3 0 0 1-1.2-3.5V8a4 4 0 0 0-4-4z">
      </path>
      <path d="M10 18a2 2 0 0 0 4 0"></path>
    </svg>
    <svg :if={@name == "profil"} viewBox="0 0 24 24" aria-hidden="true">
      <circle cx="12" cy="8" r="3.2"></circle>
      <path d="M5 19a7 7 0 0 1 14 0"></path>
    </svg>
    """
  end

  attr :name, :string, required: true

  defp composer_icon(assigns) do
    ~H"""
    <svg :if={@name == "action"} viewBox="0 0 24 24" aria-hidden="true">
      <circle cx="12" cy="12" r="8"></circle>
      <path d="M12 8v8M8 12h8"></path>
    </svg>
    <svg :if={@name == "video"} viewBox="0 0 24 24" aria-hidden="true">
      <path d="M4 7h11a2 2 0 0 1 2 2v6a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2z"></path>
      <path d="m17 10 5-2v8l-5-2z"></path>
    </svg>
    <svg :if={@name == "analysis"} viewBox="0 0 24 24" aria-hidden="true">
      <path d="M4 4h16v16H4z"></path>
      <path d="M8 9h8M8 13h8M8 17h4"></path>
    </svg>
    <svg :if={@name == "photo"} viewBox="0 0 24 24" aria-hidden="true">
      <rect x="3" y="5" width="18" height="14" rx="2"></rect>
      <circle cx="9" cy="10" r="1.6"></circle>
      <path d="m21 15-4.5-4.5L8 19"></path>
    </svg>
    """
  end

  defp coach_icon(assigns) do
    ~H"""
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <circle cx="12" cy="12" r="8"></circle>
      <path d="M12 4v16M4 12h16"></path>
      <path d="m7.5 7.5 9 9M16.5 7.5l-9 9"></path>
    </svg>
    """
  end

  defp left_nav_items(current_user) do
    [
      %{label: "Terrain", icon: "terrain", href: ~p"/", active: true},
      %{
        label: "Talents",
        icon: "talents",
        href: ~p"/talents",
        active: false
      },
      %{
        label: "Reseau",
        icon: "reseau",
        href: ~p"/reseau",
        active: false
      },
      %{
        label: "Messages",
        icon: "messages",
        href: ~p"/messages",
        active: false
      },
      %{
        label: "Alertes",
        icon: "alertes",
        href: ~p"/alertes",
        active: false
      },
      %{
        label: "Profil",
        icon: "profil",
        href: ~p"/profile/#{current_user.username}",
        active: false
      }
    ]
  end

  defp account_display_name(%{username: username}) when is_binary(username) do
    case String.trim(username) do
      "" -> "Mon compte"
      value -> display_name(value)
    end
  end

  defp account_display_name(_), do: "Mon compte"

  defp display_suggestions(users) do
    users
    |> Enum.take(3)
    |> Enum.map(fn user ->
      %{
        id: user.id,
        name: display_name(user.username),
        subtitle: suggestion_subtitle(user)
      }
    end)
    |> pad_with_mock(@mock_suggestions, 3)
  end

  defp talent_cards(users) do
    users
    |> Enum.take(3)
    |> Enum.with_index()
    |> Enum.map(fn {user, index} ->
      mock = Enum.at(@mock_talents, index, List.last(@mock_talents))

      %{
        name: display_name(user.username),
        speed: mock.speed,
        pass: mock.pass
      }
    end)
    |> pad_with_mock(@mock_talents, 3)
  end

  defp pad_with_mock(list, mock, limit) do
    missing = max(limit - length(list), 0)
    list ++ Enum.take(mock, missing)
  end

  defp display_name(nil), do: "GoalZone Talent"

  defp display_name(username) do
    username
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp suggestion_subtitle(user) do
    role = Labels.role_label(user.role)

    case String.trim(user.position || "") do
      "" -> "#{role} - Club"
      position -> "#{position} - #{role}"
    end
  end

  defp structured_post?(post), do: Params.structured_intention?(post.intention)

  defp post_format_label(:post), do: "Post"
  defp post_format_label(:photo), do: "Photo"
  defp post_format_label(:video), do: "Video"
  defp post_format_label(:article), do: "Article"

  defp post_format_label(value) when is_binary(value),
    do: post_format_label(value |> Params.parse_post_format())

  defp post_format_label(_), do: "Post"

  defp intention_label(:entertainment), do: "Divertissement"
  defp intention_label(:showcase), do: "Performance"
  defp intention_label(:recruitment), do: "Recrutement"

  defp intention_label(value) when is_binary(value),
    do: intention_label(Params.parse_intention(value))

  defp intention_label(_), do: "Divertissement"

  defp source_type_label(:highlight_video), do: "Highlight video"
  defp source_type_label(:full_match_video), do: "Match complet"
  defp source_type_label(:live_observation), do: "Observation live"
  defp source_type_label(:stat_report), do: "Rapport stats"

  defp source_type_label(value) when is_binary(value),
    do: source_type_label(parse_source_type(value))

  defp source_type_label(_), do: "Non precise"

  defp parse_source_type("highlight_video"), do: :highlight_video
  defp parse_source_type("full_match_video"), do: :full_match_video
  defp parse_source_type("live_observation"), do: :live_observation
  defp parse_source_type("stat_report"), do: :stat_report
  defp parse_source_type(_), do: :unknown

  defp avatar_initial(nil), do: "U"

  defp avatar_initial(username) when is_binary(username) do
    case String.trim(username) do
      "" -> "U"
      value -> value |> String.first() |> String.upcase()
    end
  end

  defp avatar_initial(_), do: "U"
end
