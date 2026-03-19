defmodule SocialAppWeb.PageShellComponents do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: SocialAppWeb.Endpoint,
    router: SocialAppWeb.Router,
    statics: SocialAppWeb.static_paths()

  def assign_shell(socket, active_nav, page_context) do
    assign(socket,
      page_context: page_context,
      layout_variant: :feed,
      nav_variant: :sidebar,
      shell_variant: :full,
      active_nav: active_nav
    )
  end

  attr :current_user, :any, default: nil
  attr :active_nav, :atom, default: :terrain
  attr :left_rail_cta, :map, default: %{}
  attr :right_rail, :map, default: %{}
  slot :inner_block, required: true

  def goalzone_shell(assigns) do
    assigns = prepare_shell_assigns(assigns)

    ~H"""
    <section class="feed-scene">
      <section class={["feed-layout", @hide_right_rail && "feed-layout-no-right"]}>
        <.shell_sidebar_left
          current_user={@current_user}
          left_nav_items={@left_nav_items}
          nav_title={@nav_title}
          left_rail_cta={@left_rail_cta}
        />

        <main class="feed-main-column goalzone-page-main">
          {render_slot(@inner_block)}
        </main>

        <.shell_sidebar_right
          :if={!@hide_right_rail}
          search_placeholder={@search_placeholder}
          premium_kicker={@premium_kicker}
          premium_title={@premium_title}
          premium_copy={@premium_copy}
          premium_cta_to={@premium_cta_to}
          premium_cta_label={@premium_cta_label}
          radar_title={@radar_title}
          radar_items={@radar_items}
          coach={@coach}
          hide_search_panel={@hide_search_panel}
          hide_premium_panel={@hide_premium_panel}
          hide_radar_panel={@hide_radar_panel}
          hide_coach_panel={@hide_coach_panel}
        />
      </section>
    </section>
    """
  end

  attr :current_user, :any, default: nil
  attr :left_nav_items, :list, required: true
  attr :nav_title, :string, required: true
  attr :left_rail_cta, :map, required: true

  defp shell_sidebar_left(assigns) do
    assigns = assign(assigns, :guest_mode?, is_nil(assigns.current_user))

    ~H"""
    <aside class="feed-sidebar-left">
      <div class="feed-sidebar-left-rail">
        <section class="sidebar-brand-block" aria-label="Identite GoalZone">
          <a href={~p"/"} class="sidebar-brand-logo">GoalZone</a>
          <p class="sidebar-brand-tag">Reseau social football</p>
        </section>

        <section class="panel panel-compact sidebar-panel feed-panel">
          <div class="sidebar-panel-header">
            <h2 class="sidebar-title">{@nav_title}</h2>
          </div>

          <nav
            class={["sidebar-nav", @guest_mode? && "sidebar-nav-auth"]}
            aria-label="Navigation principale"
          >
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

          <.left_rail_cta cta={@left_rail_cta} />
        </section>

        <section class="panel panel-compact sidebar-panel sidebar-account-panel feed-panel">
          <%= if @current_user do %>
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
          <% else %>
            <p class="label-caps sidebar-account-kicker">Starter kit</p>
            <div class="account-card-row">
              <div class="account-avatar">G</div>
              <div class="account-details">
                <p class="account-name">Bienvenue sur GoalZone</p>
                <p class="account-email">Un terrain clair pour publier, suivre et connecter</p>
              </div>
            </div>
            <p class="account-status">
              Commence par creer un compte, puis reviens sur le terrain pour publier un premier
              highlight.
            </p>
            <div class="account-actions">
              <.link href={~p"/users/register"} class="ghost-link">Register</.link>
              <.link href={~p"/users/log_in"} class="ghost-link">Log in</.link>
            </div>
          <% end %>
        </section>
      </div>
    </aside>
    """
  end

  attr :cta, :map, required: true

  defp left_rail_cta(assigns) do
    ~H"""
    <button
      :if={@cta.type == :event}
      type="button"
      class="btn feed-cta feed-cta-primary feed-cta-primary-rail sidebar-publish-btn"
      phx-click={@cta.event}
    >
      {@cta.label}
    </button>

    <.link
      :if={@cta.type == :link}
      href={@cta.href}
      class="btn feed-cta feed-cta-primary feed-cta-primary-rail sidebar-publish-btn"
    >
      {@cta.label}
    </.link>
    """
  end

  attr :search_placeholder, :string, required: true
  attr :premium_kicker, :string, required: true
  attr :premium_title, :string, required: true
  attr :premium_copy, :string, required: true
  attr :premium_cta_to, :string, required: true
  attr :premium_cta_label, :string, required: true
  attr :radar_title, :string, required: true
  attr :radar_items, :list, required: true
  attr :coach, :map, required: true
  attr :hide_search_panel, :boolean, required: true
  attr :hide_premium_panel, :boolean, required: true
  attr :hide_radar_panel, :boolean, required: true
  attr :hide_coach_panel, :boolean, required: true

  defp shell_sidebar_right(assigns) do
    ~H"""
    <aside class="feed-sidebar-right">
      <div class="feed-sidebar-right-rail">
        <section
          :if={!@hide_search_panel}
          class="panel panel-compact sidebar-panel right-search-panel feed-panel"
        >
          <form class="right-search-form" role="search">
            <label class="right-search-shell" for="page-right-search">
              <span class="right-search-icon">
                <.search_icon />
              </span>
              <input
                id="page-right-search"
                name="page-right-search"
                type="search"
                class="right-search-input"
                placeholder={@search_placeholder}
              />
            </label>
          </form>
        </section>

        <section
          :if={!@hide_premium_panel}
          class="panel panel-compact sidebar-panel right-premium-panel feed-panel"
        >
          <p class="label-caps right-premium-kicker">{@premium_kicker}</p>
          <h2 class="right-premium-title">{@premium_title}</h2>
          <p class="right-premium-copy">{@premium_copy}</p>
          <.link href={@premium_cta_to} class="btn feed-cta feed-cta-secondary right-premium-cta">
            {@premium_cta_label}
          </.link>
        </section>

        <section
          :if={!@hide_radar_panel}
          class="panel panel-compact sidebar-panel right-radar-panel feed-panel"
        >
          <div class="post-actions">
            <h2 class="sidebar-title">{@radar_title}</h2>
          </div>

          <div class="right-radar-list">
            <.radar_item :for={item <- @radar_items} item={item} />
          </div>
        </section>

        <section
          :if={!@hide_coach_panel}
          class="panel panel-compact sidebar-panel right-coach-panel feed-panel"
        >
          <div class="right-coach-head">
            <span class="right-coach-icon">
              <.coach_icon />
            </span>
            <div class="right-coach-copy-block">
              <p class="label-caps right-coach-kicker">Coach IA</p>
              <h2 class="right-coach-title">{@coach.title}</h2>
            </div>
          </div>

          <p class="right-coach-copy">{@coach.copy}</p>

          <div class="right-coach-actions">
            <.coach_cta coach={@coach} />
          </div>
        </section>
      </div>
    </aside>
    """
  end

  attr :coach, :map, required: true

  defp coach_cta(assigns) do
    ~H"""
    <button
      :if={is_nil(@coach[:cta_to])}
      type="button"
      class="btn feed-cta feed-cta-utility right-coach-cta"
    >
      {@coach.cta_label}
    </button>

    <.link
      :if={!is_nil(@coach[:cta_to])}
      href={@coach.cta_to}
      class="btn feed-cta feed-cta-utility right-coach-cta"
    >
      {@coach.cta_label}
    </.link>
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
    <svg :if={@name == "login"} viewBox="0 0 24 24" aria-hidden="true">
      <path d="M10 6H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h4"></path>
      <path d="M14 8l4 4-4 4"></path>
      <path d="M8 12h10"></path>
    </svg>
    <svg :if={@name == "register"} viewBox="0 0 24 24" aria-hidden="true">
      <circle cx="10" cy="8" r="3"></circle>
      <path d="M4 19a6 6 0 0 1 12 0"></path>
      <path d="M19 8v6"></path>
      <path d="M16 11h6"></path>
    </svg>
    <svg :if={@name == "recovery"} viewBox="0 0 24 24" aria-hidden="true">
      <circle cx="12" cy="12" r="8"></circle>
      <path d="M12 8v5"></path>
      <path d="M12 16h.01"></path>
    </svg>
    <svg :if={@name == "confirm"} viewBox="0 0 24 24" aria-hidden="true">
      <rect x="3" y="5" width="18" height="14" rx="2"></rect>
      <path d="m5 8 6.5 5 7.5-6"></path>
      <path d="m16 11 2 2 3-4"></path>
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

  defp avatar_initial(nil), do: "U"

  defp avatar_initial(username) when is_binary(username) do
    username
    |> String.trim()
    |> String.first()
    |> case do
      nil -> "U"
      first -> String.upcase(first)
    end
  end

  defp avatar_initial(_), do: "U"

  defp prepare_shell_assigns(assigns) do
    active_nav = assigns.active_nav
    right_rail = assigns.right_rail || %{}

    assign(assigns,
      hide_right_rail: Map.get(right_rail, :hide, false),
      nav_title: if(assigns.current_user, do: "Navigation", else: "Acces"),
      left_nav_items: left_nav_items(assigns.current_user, active_nav),
      left_rail_cta: build_left_rail_cta(assigns.current_user, active_nav, assigns.left_rail_cta),
      search_placeholder:
        Map.get(right_rail, :search_placeholder, search_placeholder(active_nav)),
      premium_kicker: Map.get(right_rail, :premium_kicker, "GoalZone Premium"),
      premium_title: Map.get(right_rail, :premium_title, premium_title(active_nav)),
      premium_copy: Map.get(right_rail, :premium_copy, premium_copy(active_nav)),
      premium_cta_to: Map.get(right_rail, :premium_cta_to, premium_cta_to(assigns.current_user)),
      premium_cta_label: Map.get(right_rail, :premium_cta_label, premium_cta_label(active_nav)),
      radar_title: Map.get(right_rail, :radar_title, radar_title(active_nav)),
      radar_items: Map.get(right_rail, :radar_items, default_radar_items(active_nav)),
      coach: build_coach(active_nav, assigns.current_user, Map.get(right_rail, :coach, %{})),
      hide_search_panel: Map.get(right_rail, :hide_search_panel, false),
      hide_premium_panel: Map.get(right_rail, :hide_premium_panel, false),
      hide_radar_panel: Map.get(right_rail, :hide_radar_panel, false),
      hide_coach_panel: Map.get(right_rail, :hide_coach_panel, false)
    )
  end

  defp build_left_rail_cta(_current_user, _active_nav, %{type: _type} = custom_cta),
    do: custom_cta

  defp build_left_rail_cta(current_user, _active_nav, _custom_cta)
       when not is_nil(current_user) do
    %{type: :link, label: "Publier sur terrain", href: ~p"/"}
  end

  defp build_left_rail_cta(_current_user, :register, _custom_cta) do
    %{type: :link, label: "Log in", href: ~p"/users/log_in"}
  end

  defp build_left_rail_cta(_current_user, _active_nav, _custom_cta) do
    %{type: :link, label: "Register", href: ~p"/users/register"}
  end

  defp build_coach(active_nav, current_user, custom_coach) do
    default = default_coach(active_nav, current_user)

    Map.merge(default, custom_coach)
  end

  defp left_nav_items(current_user, active_nav) when not is_nil(current_user) do
    [
      %{label: "Terrain", icon: "terrain", href: ~p"/", active: active_nav == :terrain},
      %{label: "Mercato", icon: "mercato", href: ~p"/mercato", active: active_nav == :mercato},
      %{label: "Reseau", icon: "reseau", href: ~p"/reseau", active: active_nav == :reseau},
      %{
        label: "Messages",
        icon: "messages",
        href: ~p"/messages",
        active: active_nav == :messages
      },
      %{label: "Alertes", icon: "alertes", href: ~p"/alertes", active: active_nav == :alertes},
      %{
        label: "Profil",
        icon: "profil",
        href: ~p"/profile/#{current_user.username}",
        active: active_nav == :profil
      }
    ]
  end

  defp left_nav_items(_current_user, active_nav) do
    [
      %{
        label: "Register",
        icon: "register",
        href: ~p"/users/register",
        active: active_nav == :register
      },
      %{label: "Log in", icon: "login", href: ~p"/users/log_in", active: active_nav == :login},
      %{
        label: "Reset",
        icon: "recovery",
        href: ~p"/users/reset_password",
        active: active_nav == :recovery
      },
      %{
        label: "Confirm",
        icon: "confirm",
        href: ~p"/users/confirm",
        active: active_nav == :confirm
      }
    ]
  end

  defp premium_title(:mercato), do: "Passe en scouting avance"
  defp premium_title(:messages), do: "Passe en suivi elite"
  defp premium_title(:alertes), do: "Passe en veille prioritaire"
  defp premium_title(:profil), do: "Passe en profil premium"
  defp premium_title(_active_nav), do: "Passe en mode elite"

  defp premium_copy(:mercato) do
    "Debloque des filtres plus fins et une veille recrutement plus rapide."
  end

  defp premium_copy(:messages) do
    "Structure tes suivis, tes priorites de relance et tes conversations critiques."
  end

  defp premium_copy(:alertes) do
    "Trie les signaux chauds avant les autres et garde une inbox plus actionnable."
  end

  defp premium_copy(:profil) do
    "Mets en avant tes preuves, ta disponibilite et ta credibilite recrutement."
  end

  defp premium_copy(_active_nav) do
    "Radar plus fin, veille recrutement et dossiers joueurs prioritaires."
  end

  defp premium_cta_to(nil), do: ~p"/users/register"
  defp premium_cta_to(_current_user), do: ~p"/users/settings"

  defp premium_cta_label(nil), do: "Creer mon compte"
  defp premium_cta_label(_active_nav), do: "Passer Premium"

  defp radar_title(:messages), do: "Threads a activer"
  defp radar_title(:alertes), do: "Priorites du jour"
  defp radar_title(:profil), do: "Points a verifier"
  defp radar_title(:recovery), do: "Bonnes pratiques"
  defp radar_title(:confirm), do: "Avant d'entrer"
  defp radar_title(_active_nav), do: "Sur le radar"

  defp search_placeholder(:mercato), do: "Rechercher un role, une region, un niveau..."
  defp search_placeholder(:messages), do: "Rechercher un thread, un scout, un club..."
  defp search_placeholder(:alertes), do: "Rechercher une alerte ou une action..."
  defp search_placeholder(:profil), do: "Rechercher un joueur, un coach, une preuve..."
  defp search_placeholder(:recovery), do: "Retrouver un acces, un email, un lien..."
  defp search_placeholder(:confirm), do: "Retrouver une confirmation ou un compte..."
  defp search_placeholder(_active_nav), do: "Rechercher un talent, un club, un poste..."

  defp default_radar_items(:mercato) do
    [
      %{
        kicker: "Filtre",
        title: "Cible un role avant d'ouvrir trop de profils",
        meta: "Commence simple"
      },
      %{
        kicker: "Region",
        title: "Croise zone geographique et niveau reel",
        meta: "Qualification rapide"
      },
      %{
        kicker: "Action",
        title: "Passe du tri au contact en moins de 2 clics",
        meta: "Mercato -> reseau"
      }
    ]
  end

  defp default_radar_items(:reseau) do
    [
      %{
        kicker: "Connect",
        title: "Ajoute des profils complementaires",
        meta: "Clubs, scouts, agents"
      },
      %{kicker: "Qualif", title: "Lis le headline avant de connecter", meta: "Evite le bruit"},
      %{kicker: "Suite", title: "Passe ensuite par la messagerie", meta: "1 relation -> 1 thread"}
    ]
  end

  defp default_radar_items(:messages) do
    [
      %{
        kicker: "Thread",
        title: "Un message = une intention claire",
        meta: "Prochaine etape explicite"
      },
      %{
        kicker: "Relance",
        title: "Garde les conversations courtes et utiles",
        meta: "Moins de friction"
      },
      %{
        kicker: "Contact",
        title: "Pars du reseau pour ouvrir les bons fils",
        meta: "Connexions d'abord"
      }
    ]
  end

  defp default_radar_items(:alertes) do
    [
      %{kicker: "Inbox", title: "Traite le non lu avant le reste", meta: "Priorite terrain"},
      %{
        kicker: "Signal",
        title: "Ouvre vite les likes, follows et messages chauds",
        meta: "Temps reel"
      },
      %{
        kicker: "Action",
        title: "Une alerte utile doit declencher un geste",
        meta: "Lire puis agir"
      }
    ]
  end

  defp default_radar_items(:profil) do
    [
      %{
        kicker: "Bio",
        title: "Lis la promesse du profil avant toute action",
        meta: "30 secondes max"
      },
      %{
        kicker: "Preuves",
        title: "Valide source, niveau et disponibilite",
        meta: "Qualification"
      },
      %{kicker: "Next", title: "Puis contacte ou ajoute au reseau", meta: "Decision claire"}
    ]
  end

  defp default_radar_items(:register) do
    [
      %{
        kicker: "Setup",
        title: "Cree ton compte pour revenir sur le terrain",
        meta: "Point de depart"
      },
      %{kicker: "Objectif", title: "Publie vite un premier highlight", meta: "Activation rapide"},
      %{kicker: "Suite", title: "Puis explore mercato et reseau", meta: "Parcours MVP"}
    ]
  end

  defp default_radar_items(:login) do
    [
      %{
        kicker: "Retour",
        title: "Reconnecte-toi pour reprendre ton flux",
        meta: "Terrain, messages, alertes"
      },
      %{
        kicker: "Acces",
        title: "Verifie email et mot de passe avant tout",
        meta: "Connexion simple"
      },
      %{
        kicker: "Suite",
        title: "Une fois entre, reviens publier ou repondre",
        meta: "Actions utiles"
      }
    ]
  end

  defp default_radar_items(:recovery) do
    [
      %{
        kicker: "Reset",
        title: "Demande le lien sur la bonne boite mail",
        meta: "Acces securise"
      },
      %{
        kicker: "Token",
        title: "Utilise le lien recu sans attendre",
        meta: "Expiration possible"
      },
      %{
        kicker: "Retour",
        title: "Reconnecte-toi ensuite pour revenir au terrain",
        meta: "Flux normal"
      }
    ]
  end

  defp default_radar_items(:confirm) do
    [
      %{
        kicker: "Email",
        title: "Confirme l'adresse qui portera ton compte",
        meta: "Etape requise"
      },
      %{kicker: "Suite", title: "Apres confirmation, connecte-toi", meta: "Acces au produit"},
      %{
        kicker: "Objectif",
        title: "Le terrain reste la page de reference",
        meta: "Publier, suivre, connecter"
      }
    ]
  end

  defp default_radar_items(_active_nav) do
    [
      %{kicker: "Momentum", title: "3 mercato U21 a suivre ce soir", meta: "Angleterre · 19:30"},
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
  end

  defp default_coach(:mercato, _current_user) do
    %{
      title: "Filtre peu, qualifie vite",
      copy:
        "Sur Mercato, resserre d'abord les profils cibles puis ouvre seulement les plus credibles.",
      cta_to: ~p"/reseau",
      cta_label: "Voir le reseau"
    }
  end

  defp default_coach(:reseau, _current_user) do
    %{
      title: "Construis le premier cercle",
      copy: "Ici, l'objectif est de transformer des profils interessants en connexions actives.",
      cta_to: ~p"/messages",
      cta_label: "Ouvrir messages"
    }
  end

  defp default_coach(:messages, _current_user) do
    %{
      title: "Fais avancer le thread",
      copy:
        "Chaque message doit pousser vers une prochaine etape claire, pas juste maintenir la discussion.",
      cta_to: ~p"/mercato",
      cta_label: "Trouver un contact"
    }
  end

  defp default_coach(:alertes, _current_user) do
    %{
      title: "Traite l'inbox d'abord",
      copy:
        "Les alertes sont ton inbox d'actions. Ouvre le non lu puis decide tout de suite quoi faire.",
      cta_to: ~p"/messages",
      cta_label: "Voir messages"
    }
  end

  defp default_coach(:profil, current_user) do
    cta_to =
      if current_user do
        ~p"/profile/#{current_user.username}"
      else
        ~p"/users/register"
      end

    %{
      title: "Lis, qualifie, puis agis",
      copy:
        "Le profil doit te donner assez d'infos pour contacter, suivre ou revenir au reseau sans hesitation.",
      cta_to: cta_to,
      cta_label: if(current_user, do: "Voir mon profil", else: "Creer un compte")
    }
  end

  defp default_coach(:register, _current_user) do
    %{
      title: "Entre sur le terrain",
      copy:
        "Cree ton compte maintenant, puis reviens sur le terrain pour publier un premier highlight.",
      cta_to: ~p"/users/log_in",
      cta_label: "Deja inscrit ?"
    }
  end

  defp default_coach(:login, _current_user) do
    %{
      title: "Reprends ton flux",
      copy:
        "Reconnecte-toi pour retrouver ton terrain, tes messages et tes alertes sans perdre le rythme.",
      cta_to: ~p"/users/register",
      cta_label: "Creer un compte"
    }
  end

  defp default_coach(:recovery, _current_user) do
    %{
      title: "Recupere l'acces proprement",
      copy:
        "Demande le lien, mets a jour ton mot de passe, puis reconnecte-toi avant de reprendre ton flux.",
      cta_to: ~p"/users/log_in",
      cta_label: "Retour login"
    }
  end

  defp default_coach(:confirm, _current_user) do
    %{
      title: "Confirme puis connecte-toi",
      copy:
        "Une fois l'email confirme, le plus utile est de revenir sur le terrain pour activer ton compte.",
      cta_to: ~p"/users/log_in",
      cta_label: "Log in"
    }
  end

  defp default_coach(_active_nav, _current_user) do
    %{
      title: "Besoin d'un repere ?",
      copy: "Si tu decouvres GoalZone, je t'explique rapidement ou tu es et quoi faire ici.",
      cta_to: nil,
      cta_label: "Comprendre la page"
    }
  end

  defp account_display_name(%{username: username}) when is_binary(username) do
    case String.trim(username) do
      "" -> "Mon compte"
      value -> display_name(value)
    end
  end

  defp account_display_name(_), do: "Mon compte"

  defp display_name(username) do
    username
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
