defmodule SocialAppWeb.FeedLive.Components do
  @moduledoc false
  use SocialAppWeb, :html

  alias SocialApp.Labels
  alias SocialAppWeb.FeedLive.Params

  @mock_mercato [
    %{name: "Anthon Furton", speed: "32 km/h", pass: "89%"},
    %{name: "James Holtier", speed: "32 km/h", pass: "89%"},
    %{name: "Mikha Doran", speed: "32 km/h", pass: "89%"}
  ]

  @mock_radar_items [
    %{
      kicker: "Momentum",
      title: "3 mercato U21 a suivre ce soir",
      meta: "Angleterre · 19:30"
    },
    %{
      kicker: "Mercato",
      title: "Un lateral gauche se libere cet ete",
      meta: "France · Opportunite"
    },
    %{
      kicker: "Radar",
      title: "Un profil explosif attire les scouts",
      meta: "Vitesse 32 km/h · Passe 89%"
    }
  ]

  @composer_actions [
    %{label: "Action", icon: "action", values: []},
    %{label: "Video", icon: "video", values: [format: "video"]},
    %{
      label: "Analyse",
      icon: "analysis",
      values: [format: "article", intention: "recruitment"]
    },
    %{label: "Photo", icon: "photo", values: [format: "photo"]}
  ]

  def render(assigns) do
    assigns = prepare_render_assigns(assigns)

    ~H"""
    <section class="feed-scene">
      <section class="feed-layout">
        <.feed_sidebar_left current_user={@current_user} left_nav_items={@left_nav_items} />

        <main class="feed-main-column">
          <.feed_toolbar
            feed_tab={@feed_tab}
            feed_tabs={@feed_tabs}
            feed_sort={@feed_sort}
            feed_sorts={@feed_sorts}
          />

          <.composer_shell current_user={@current_user} />

          <.feed_composer_form :if={@composer_open} post_form={@post_form} />

          <button
            :if={@pending_new_posts_count > 0}
            type="button"
            phx-click="show_new_posts"
            class="panel panel-compact new-posts-banner feed-panel"
          >
            Voir {@pending_new_posts_count} nouveaux posts
          </button>

          <.empty_feed_hero :if={@posts == []} />
          <.feed_talent_strip :if={@posts == []} talent_cards={@talent_cards} />
          <.feed_stream :if={@posts != []} posts={@posts} shortlist_by_post={@shortlist_by_post} />
        </main>

        <.feed_sidebar_right radar_items={@radar_items} />
      </section>
    </section>
    """
  end

  defp prepare_render_assigns(assigns) do
    assign(assigns,
      left_nav_items: left_nav_items(assigns.current_user),
      talent_cards: talent_cards(assigns.suggestions),
      radar_items: radar_items(assigns.suggestions)
    )
  end

  defp prepare_composer_form_assigns(assigns) do
    post_format = assigns.post_form[:post_format].value || "post"
    intention = assigns.post_form[:intention].value || "entertainment"

    assign(assigns,
      post_format: post_format,
      intention: intention,
      structured: Params.structured_intention?(intention),
      post_format_options: Params.post_format_options(),
      intention_options: Params.intention_options(),
      composer_placeholder: Params.composer_placeholder(post_format, intention)
    )
  end

  attr :current_user, :map, required: true
  attr :left_nav_items, :list, required: true

  defp feed_sidebar_left(assigns) do
    ~H"""
    <aside class="feed-sidebar-left">
      <div class="feed-sidebar-left-rail">
        <section class="sidebar-brand-block" aria-label="Identite GoalZone">
          <a href={~p"/"} class="sidebar-brand-logo">GoalZone</a>
          <p class="sidebar-brand-tag">Reseau social football</p>
        </section>

        <section class="panel panel-compact sidebar-panel feed-panel">
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

          <button
            type="button"
            class="btn feed-cta feed-cta-primary feed-cta-primary-rail sidebar-publish-btn"
            phx-click="open_composer"
          >
            Publier
          </button>
        </section>

        <section class="panel panel-compact sidebar-panel sidebar-account-panel feed-panel">
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
    """
  end

  attr :feed_tab, :string, required: true
  attr :feed_tabs, :list, required: true
  attr :feed_sort, :string, required: true
  attr :feed_sorts, :list, required: true

  defp feed_toolbar(assigns) do
    ~H"""
    <section class="panel panel-compact feed-toolbar feed-toolbar-sticky feed-panel">
      <div
        class="feed-tabs-shell"
        data-feed-tabs-shell
        data-overflowing="false"
        data-can-scroll-left="false"
        data-can-scroll-right="false"
      >
        <button
          type="button"
          class="feed-tabs-arrow feed-tabs-arrow-left"
          data-feed-tabs-arrow="left"
          aria-label="Faire defiler les filtres vers la gauche"
        >
          <.tabs_scroll_arrow direction={:left} />
        </button>

        <div class="feed-tabs-fade feed-tabs-fade-left" aria-hidden="true"></div>
        <div class="feed-tabs-fade feed-tabs-fade-right" aria-hidden="true"></div>

        <div class="feed-tabs" data-feed-tabs role="tablist" aria-label="Filtres du feed">
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

        <button
          type="button"
          class="feed-tabs-arrow feed-tabs-arrow-right"
          data-feed-tabs-arrow="right"
          aria-label="Faire defiler les filtres vers la droite"
        >
          <.tabs_scroll_arrow direction={:right} />
        </button>
      </div>

      <form phx-change="set_feed_sort" class="feed-sort-form">
        <label for="feed-sort" class="feed-sort-label">
          <span>Classer</span>
          <span>par</span>
        </label>
        <select id="feed-sort" name="sort" class="field-input feed-sort-select">
          <option :for={sort <- @feed_sorts} value={sort.value} selected={@feed_sort == sort.value}>
            {sort.label}
          </option>
        </select>
      </form>
    </section>
    """
  end

  attr :direction, :atom, required: true

  defp tabs_scroll_arrow(assigns) do
    ~H"""
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path :if={@direction == :left} d="m14.5 5.5-6 6 6 6"></path>
      <path :if={@direction == :right} d="m9.5 5.5 6 6-6 6"></path>
    </svg>
    """
  end

  attr :current_user, :map, required: true

  defp composer_shell(assigns) do
    assigns = assign(assigns, :composer_actions, @composer_actions)

    ~H"""
    <section class="panel panel-compact composer-shell feed-panel">
      <div class="composer-top-row">
        <div class="composer-avatar">{avatar_initial(@current_user.username)}</div>
        <button type="button" class="composer-trigger" phx-click="open_composer">
          Partage ton highlight (but, passe cle, arret, dribble)...
        </button>
      </div>
      <div class="composer-actions-row">
        <.composer_action_button :for={action <- @composer_actions} action={action} />
      </div>
    </section>
    """
  end

  attr :action, :map, required: true

  defp composer_action_button(assigns) do
    ~H"""
    <button
      type="button"
      class="composer-pill-action"
      phx-click="open_composer"
      phx-value-format={@action.values[:format]}
      phx-value-intention={@action.values[:intention]}
    >
      <.composer_icon name={@action.icon} />
      <span>{@action.label}</span>
    </button>
    """
  end

  attr :post_form, :map, required: true

  defp feed_composer_form(assigns) do
    assigns = prepare_composer_form_assigns(assigns)

    ~H"""
    <form
      phx-submit="create_post"
      phx-change="post_form_changed"
      class="panel stack-md feed-panel feed-composer-form"
    >
      <div class="composer-head">
        <p class="kicker">Creation</p>
        <button type="button" class="ghost-link" phx-click="close_composer">Fermer</button>
      </div>

      <label class="field-label">Format</label>
      <div class="format-picker">
        <label
          :for={option <- @post_format_options}
          class={["format-chip", @post_format == option.value && "format-chip-active"]}
        >
          <input
            type="radio"
            name={@post_form[:post_format].name}
            value={option.value}
            checked={@post_format == option.value}
          />
          <span>{option.label}</span>
        </label>
      </div>

      <div class="filters-grid">
        <label class="field-wrap">
          <span class="field-label">Objectif du contenu</span>
          <select name={@post_form[:intention].name} class="field-input">
            <option
              :for={option <- @intention_options}
              value={option.value}
              selected={@intention == option.value}
            >
              {option.label}
            </option>
          </select>
        </label>

        <label :if={@post_format in ~w(photo video)} class="field-wrap">
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
        placeholder={@composer_placeholder}
      ><%= @post_form[:content].value %></textarea>

      <.structured_form_fields :if={@structured} post_form={@post_form} />

      <div class="post-actions">
        <.button type="submit">Publier</.button>
        <button type="button" class="ghost-link" phx-click="close_composer">Annuler</button>
      </div>
    </form>
    """
  end

  attr :post_form, :map, required: true

  defp structured_form_fields(assigns) do
    assigns = assign(assigns, :source_type_options, source_type_options())

    ~H"""
    <div class="filters-grid">
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
            :for={option <- @source_type_options}
            value={option.value}
            selected={@post_form[:source_type].value == option.value}
          >
            {option.label}
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
    """
  end

  defp empty_feed_hero(assigns) do
    ~H"""
    <section class="panel feed-hero-card feed-panel">
      <div class="feed-hero-copy">
        <h2 class="feed-hero-title">LE TERRAIN ATTEND</h2>
        <p class="feed-hero-subtitle">Ton premier mouvement</p>
      </div>

      <div class="feed-hero-actions">
        <button
          type="button"
          class="btn feed-cta feed-cta-primary hero-action-btn hero-action-btn-primary"
          phx-click="open_composer"
          phx-value-intention="showcase"
        >
          Publier un highlight
        </button>
        <a
          href={~p"/mercato"}
          class="feed-cta feed-cta-secondary hero-action-btn hero-action-btn-secondary"
        >
          Suivre des mercato
        </a>
        <a
          href={~p"/reseau"}
          class="feed-cta feed-cta-utility hero-action-btn hero-action-btn-tertiary"
        >
          Explorer le reseau
        </a>
      </div>
    </section>
    """
  end

  attr :talent_cards, :list, required: true

  defp feed_talent_strip(assigns) do
    ~H"""
    <section class="panel feed-talent-strip feed-panel">
      <div class="feed-strip-head">
        <h2 class="sidebar-title">Mercato a suivre</h2>
      </div>

      <div class="talent-strip-grid">
        <.talent_preview_card :for={card <- @talent_cards} card={card} />
      </div>
    </section>
    """
  end

  attr :card, :map, required: true

  defp talent_preview_card(assigns) do
    ~H"""
    <article class="talent-preview-card">
      <button type="button" class="talent-preview-close" aria-label="Fermer">x</button>
      <div class="talent-preview-avatar"></div>
      <div class="talent-preview-copy">
        <p class="talent-preview-name">{@card.name}</p>
        <p class="talent-preview-kpi">Vitesse: {@card.speed}</p>
        <p class="talent-preview-kpi">Passe: {@card.pass}</p>
      </div>
    </article>
    """
  end

  attr :posts, :list, required: true
  attr :shortlist_by_post, :map, required: true

  defp feed_stream(assigns) do
    ~H"""
    <div class="feed-stream stack-md">
      <.feed_post_card
        :for={post <- @posts}
        post={post}
        shortlist_by_post={@shortlist_by_post}
      />
    </div>
    """
  end

  attr :post, :map, required: true
  attr :shortlist_by_post, :map, required: true

  defp feed_post_card(assigns) do
    ~H"""
    <% shortlist_entry = Map.get(@shortlist_by_post, @post.id) %>
    <article class="panel feed-post-card feed-panel">
      <div class="meta-line">@{(@post.user && @post.user.username) || "inconnu"}</div>
      <div class="status-row">
        <span class="status-pill status-pill-muted">{post_format_label(@post.post_format)}</span>
        <span class="status-pill status-pill-muted">{intention_label(@post.intention)}</span>
        <span
          :if={@post.source_type && @post.source_type != :unknown}
          class="status-pill status-pill-muted"
        >
          Source: {source_type_label(@post.source_type)}
        </span>
        <a
          :if={@post.media_url}
          href={@post.media_url}
          target="_blank"
          rel="noopener noreferrer"
          class="text-link"
        >
          Ouvrir media
        </a>
      </div>
      <p class="post-content">{@post.content}</p>
      <p :if={structured_post?(@post)} class="meta-line">
        {@post.competition || "Match"} {if @post.opponent, do: "· vs #{@post.opponent}", else: ""}
        {if @post.match_minute, do: "· #{@post.match_minute}'", else: ""}
      </p>
      <div class="post-actions">
        <.button class="btn-like" phx-click="like" phx-value-post_id={@post.id}>
          Supporters: {@post.likes_count}
        </.button>
        <button class="ghost-link" phx-click="toggle_shortlist" phx-value-post_id={@post.id}>
          {if shortlist_entry, do: "Retirer pipeline", else: "Ajouter pipeline"}
        </button>
        <button
          :if={shortlist_entry}
          class="ghost-link"
          phx-click="advance_stage"
          phx-value-post_id={@post.id}
        >
          Etape: {Labels.stage_label(shortlist_entry.stage)}
        </button>
        <a href={~p"/posts/#{@post.id}"} class="text-link">Debrief</a>
        <a href={~p"/profile/#{@post.user.username}"} class="text-link">Profil</a>
      </div>
    </article>
    """
  end

  attr :radar_items, :list, required: true

  defp feed_sidebar_right(assigns) do
    ~H"""
    <aside class="feed-sidebar-right">
      <div class="feed-sidebar-right-rail">
        <div class="right-search-sticky">
          <section class="panel panel-compact sidebar-panel right-search-panel feed-panel">
            <form class="right-search-form" role="search">
              <label class="right-search-shell" for="feed-right-search">
                <span class="sr-only">Rechercher un talent, un club ou un poste</span>
                <span class="right-search-icon">
                  <.search_icon />
                </span>
                <input
                  id="feed-right-search"
                  name="feed-right-search"
                  type="text"
                  inputmode="search"
                  autocapitalize="none"
                  autocomplete="off"
                  spellcheck="false"
                  class="right-search-input"
                  aria-label="Rechercher un talent, un club ou un poste"
                  placeholder="Rechercher un talent, un club, un poste..."
                />
              </label>
            </form>
          </section>
        </div>

        <section class="panel panel-compact sidebar-panel right-premium-panel feed-panel">
          <p class="label-caps right-premium-kicker">GoalZone Premium</p>
          <h2 class="right-premium-title">Passe en mode elite</h2>
          <p class="right-premium-copy">
            Radar plus fin, veille recrutement et dossiers joueurs prioritaires.
          </p>
          <.link href={~p"/users/settings"} class="btn feed-cta feed-cta-secondary right-premium-cta">
            Passer Premium
          </.link>
        </section>

        <section class="panel panel-compact sidebar-panel right-radar-panel feed-panel">
          <div class="post-actions">
            <h2 class="sidebar-title">Sur le radar</h2>
          </div>

          <div class="right-radar-list">
            <.radar_item :for={item <- @radar_items} item={item} />
          </div>
        </section>

        <section class="panel panel-compact sidebar-panel right-coach-panel feed-panel">
          <div class="right-coach-head">
            <span class="right-coach-icon">
              <.coach_icon />
            </span>
            <div class="right-coach-copy-block">
              <p class="label-caps right-coach-kicker">Coach IA</p>
              <h2 class="right-coach-title">Besoin d'un repere ?</h2>
            </div>
          </div>

          <p class="right-coach-copy">
            Si tu decouvres GoalZone, je t'explique rapidement ou tu es et quoi faire ici.
          </p>

          <div class="right-coach-actions">
            <button type="button" class="btn feed-cta feed-cta-utility right-coach-cta">
              Comprendre la page
            </button>
          </div>
        </section>
      </div>
    </aside>
    """
  end

  attr :item, :map, required: true

  defp radar_item(assigns) do
    ~H"""
    <article class="radar-item">
      <p class="radar-item-kicker">{@item.kicker}</p>
      <p class="radar-item-title">{@item.title}</p>
      <p class="radar-item-meta">{@item.meta}</p>
    </article>
    """
  end

  attr :name, :string, required: true

  defp nav_icon(assigns) do
    ~H"""
    <svg :if={@name == "terrain"} viewBox="0 0 24 24" aria-hidden="true">
      <circle cx="12" cy="12" r="8"></circle>
      <path d="M12 4v16M4 12h16"></path>
    </svg>
    <svg :if={@name == "mercato"} viewBox="0 0 24 24" aria-hidden="true">
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

  defp search_icon(assigns) do
    ~H"""
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <circle cx="11" cy="11" r="6"></circle>
      <path d="m20 20-4.2-4.2"></path>
    </svg>
    """
  end

  defp left_nav_items(current_user) do
    [
      %{label: "Terrain", icon: "terrain", href: ~p"/", active: true},
      %{
        label: "Mercato",
        icon: "mercato",
        href: ~p"/mercato",
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

  defp talent_cards(users) do
    users
    |> Enum.take(3)
    |> Enum.with_index()
    |> Enum.map(fn {user, index} ->
      mock = Enum.at(@mock_mercato, index, List.last(@mock_mercato))

      %{
        name: display_name(user.username),
        speed: mock.speed,
        pass: mock.pass
      }
    end)
    |> pad_with_mock(@mock_mercato, 3)
  end

  defp radar_items(users) do
    users
    |> Enum.take(3)
    |> Enum.with_index()
    |> Enum.map(fn {user, index} ->
      mock = Enum.at(@mock_radar_items, index, List.last(@mock_radar_items))

      %{
        kicker: mock.kicker,
        title: radar_title(index, user),
        meta: suggestion_subtitle(user)
      }
    end)
    |> pad_with_mock(@mock_radar_items, 3)
  end

  defp pad_with_mock(list, mock, limit) do
    missing = max(limit - length(list), 0)
    list ++ Enum.take(mock, missing)
  end

  defp source_type_options do
    [
      %{value: "highlight_video", label: "Video highlight"},
      %{value: "full_match_video", label: "Video match complet"},
      %{value: "live_observation", label: "Observation live"},
      %{value: "stat_report", label: "Rapport stats"},
      %{value: "unknown", label: "Non precise"}
    ]
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

  defp radar_title(0, user), do: "#{display_name(user.username)} monte en puissance"
  defp radar_title(1, user), do: "#{display_name(user.username)} attire des regards"
  defp radar_title(_, user), do: "#{display_name(user.username)} reste sur le radar"

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
