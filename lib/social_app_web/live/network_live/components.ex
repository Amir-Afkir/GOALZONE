defmodule SocialAppWeb.NetworkLive.Components do
  @moduledoc false
  use SocialAppWeb, :html

  def render(assigns) do
    ~H"""
    <.goalzone_shell current_user={@current_user} active_nav={@active_nav}>
      <section class="stack-lg network-page">
        <.page_header />

        <.profiles_panel
          title={"Radar reseau (#{length(@suggestion_cards)})"}
          kicker="Radar reseau"
          subtitle=""
          profiles={@visible_suggestion_cards}
          total_count={length(@suggestion_cards)}
          action_label="Connecter"
          empty_title="Aucun profil prioritaire"
          empty_copy="Le radar est calme. Reviens depuis Mercato ou enrichis ton profil pour faire remonter des profils plus qualifies."
          card_variant="prospect"
          collapsible={true}
          expanded={@show_all_suggestions}
        />

        <.profiles_panel
          title="Connexions"
          kicker="Connexions"
          subtitle=""
          profiles={@connection_cards}
          total_count={length(@connection_cards)}
          action_label="Retirer"
          empty_title="Aucune connexion active"
          empty_copy="Ajoute un premier profil utile puis bascule directement vers les messages."
          card_variant="active"
          collapsible={false}
          expanded={true}
        />
      </section>
    </.goalzone_shell>
    """
  end

  defp page_header(assigns) do
    ~H"""
    <section class="mercato-hero-stack">
      <section class="panel panel-compact feed-toolbar feed-panel mercato-title-card">
        <div class="mercato-title-ribbon">
          <span class="mercato-title-accent">Reseau</span>
          <span class="mercato-title-text">Construis ton premier cercle utile</span>
        </div>
      </section>
    </section>
    """
  end

  attr :title, :string, required: true
  attr :kicker, :string, required: true
  attr :subtitle, :string, default: nil
  attr :profiles, :list, required: true
  attr :total_count, :integer, required: true
  attr :action_label, :string, required: true
  attr :empty_title, :string, required: true
  attr :empty_copy, :string, required: true
  attr :card_variant, :string, required: true
  attr :collapsible, :boolean, required: true
  attr :expanded, :boolean, required: true

  defp profiles_panel(assigns) do
    ~H"""
    <section
      class={[
        "panel feed-panel network-board-panel",
        @card_variant in ["prospect", "active"] && "network-board-panel-prospect"
      ]}
    >
      <div
        class={[
          "network-board-head",
          @card_variant in ["prospect", "active"] && "network-board-head-compact"
        ]}
      >
        <div>
          <p :if={@card_variant not in ["prospect", "active"]} class="kicker">{@kicker}</p>
          <h2 class="network-board-title">{@title}</h2>
          <p :if={@subtitle} class="section-subtitle network-board-subtitle">{@subtitle}</p>
        </div>

        <div
          class={[
            "network-board-actions",
            @card_variant in ["prospect", "active"] && "network-board-actions-compact"
          ]}
        >
          <button
            :if={@collapsible && @total_count > 3 && !@expanded}
            type="button"
            class="ghost-link network-header-link"
            phx-click="show_all_suggestions"
          >
            Voir tout
          </button>

          <button
            :if={@collapsible && @total_count > 3 && @expanded}
            type="button"
            class="ghost-link network-header-link"
            phx-click="show_less_suggestions"
          >
            Voir moins
          </button>
        </div>
      </div>

      <div
        :if={@profiles != []}
        class={[
          "network-card-list",
          @card_variant in ["prospect", "active"] && "network-card-list-flat"
        ]}
      >
        <.profile_card
          :for={profile <- @profiles}
          profile={profile}
          action_label={@action_label}
          card_variant={@card_variant}
        />
      </div>

      <div
        :if={@collapsible && @total_count > 3 && @card_variant != "prospect"}
        class="network-board-footer"
      >
        <button
          :if={!@expanded}
          type="button"
          class="ghost-link network-footer-link"
          phx-click="show_all_suggestions"
        >
          Voir tout
        </button>

        <button
          :if={@expanded}
          type="button"
          class="ghost-link network-footer-link"
          phx-click="show_less_suggestions"
        >
          Voir moins
        </button>
      </div>

      <article :if={@profiles == []} class="network-empty-state">
        <p class="kicker">{@empty_title}</p>
        <p class="section-subtitle">{@empty_copy}</p>
      </article>
    </section>
    """
  end

  attr :profile, :map, required: true
  attr :action_label, :string, required: true
  attr :card_variant, :string, required: true

  defp profile_card(assigns) do
    ~H"""
    <article
      class={[
        "network-card",
        @card_variant == "prospect" && "network-card-prospect-flat",
        @card_variant == "active" && "network-card-active-flat"
      ]}
    >
      <div :if={@card_variant in ["prospect", "active"]} class="network-card-avatar" aria-hidden="true">
        {String.first(@profile.username) |> String.upcase()}
      </div>

      <div class="network-card-main">
        <div class="network-card-copy">
          <div class="network-card-title-row">
            <a href={@profile.profile_href} class="network-card-title">@{@profile.username}</a>
          </div>

          <p :if={@card_variant == "prospect"} class="network-card-detail">
            {@profile.role} · {@profile.level} · {@profile.region}
          </p>

          <p :if={@card_variant == "active"} class="network-card-detail">
            {@profile.role} · {@profile.level} · {@profile.region}
          </p>

          <p :if={@profile.headline} class={["network-card-headline", @card_variant == "prospect" && "network-card-headline-compact"]}>
            {@profile.headline}
          </p>

          <p :if={@card_variant == "prospect" && @profile.meta} class="network-card-meta">
            {@profile.meta}
          </p>

          <p :if={@card_variant == "active" && @profile.meta} class="network-card-meta">
            {@profile.meta}
          </p>
        </div>
      </div>

      <div class="network-card-actions">
        <button
          type="button"
          class={["btn feed-cta", @card_variant == "prospect" && "feed-cta-primary", @card_variant == "active" && "feed-cta-secondary"]}
          phx-click="toggle_follow"
          phx-value-user_id={@profile.id}
        >
          {@action_label}
        </button>

        <a
          :if={@card_variant == "active"}
          href={~p"/messages"}
          class="ghost-link network-message-link"
        >
          Envoyer un message
        </a>
      </div>
    </article>
    """
  end
end
