defmodule SocialAppWeb.MercatoLive.Components do
  @moduledoc false
  use SocialAppWeb, :html

  alias SocialApp.Labels

  attr :publish_notice, :map, default: nil

  def page_header(assigns) do
    ~H"""
    <section class="mercato-hero-stack">
      <section class="panel panel-compact feed-toolbar feed-panel mercato-title-card">
        <div class="mercato-title-ribbon">
          <span class="mercato-title-accent">Mercato</span>
          <span class="mercato-title-text">Trouver votre prochain defi</span>
        </div>
      </section>

      <section class="panel panel-compact composer-shell feed-panel mercato-intro-shell">
        <p class="mercato-intro-question">Tu cherches un nouveau club ou un nouveau joueur ?</p>

        <div class="mercato-intro-actions-row">
          <button
            type="button"
            class="btn feed-cta feed-cta-primary mercato-intro-primary mercato-publish-cta"
            phx-click="open_publish_modal"
            phx-value-role="club"
          >
            Publier une offre
          </button>

          <button
            type="button"
            class="btn feed-cta feed-cta-secondary mercato-intro-secondary"
            phx-click="open_publish_modal"
            phx-value-role="player"
          >
            Deposer ma candidature
          </button>
        </div>

        <div :if={@publish_notice} class="mercato-publish-note mercato-publish-inline-note">
          <p class="meta-line">
            Annonce publiee.
            <a href={~p"/posts/#{@publish_notice.post_id}"} class="text-link">Voir l'annonce</a>
          </p>
        </div>
      </section>
    </section>
    """
  end

  attr :filter_form, :any, required: true
  attr :filters_button_label, :string, required: true
  attr :active_filter_labels, :list, required: true
  attr :announcements, :list, required: true
  attr :announcement_total, :integer, required: true
  attr :show_all_announcements, :boolean, required: true

  def results_panel(assigns) do
    assigns =
      assign(
        assigns,
        :filter_chip_labels,
        if(assigns.active_filter_labels == [],
          do: ["Poste", "Niveau", "Localisation", "Disponibilite"],
          else: assigns.active_filter_labels
        )
      )

    ~H"""
    <section class="panel feed-panel mercato-panel mercato-results-panel mercato-board-panel">
      <div class="mercato-board-top">
        <div class="mercato-search-row mercato-search-row-board">
          <form phx-change="filter" phx-submit="filter" class="mercato-search-form">
            <input
              type="hidden"
              name={@filter_form[:region].name}
              value={@filter_form[:region].value}
            />
            <input type="hidden" name={@filter_form[:role].name} value={@filter_form[:role].value} />
            <input type="hidden" name={@filter_form[:level].name} value={@filter_form[:level].value} />

            <input
              type="hidden"
              name={@filter_form[:availability].name}
              value={@filter_form[:availability].value}
            />

            <label class="field-wrap mercato-search-field mercato-search-shell">
              <span class="mercato-search-icon">⌕</span>
              <input
                type="text"
                name={@filter_form[:q].name}
                value={@filter_form[:q].value}
                class="field-input mercato-search-input mercato-search-input-board"
                placeholder="Recherche par poste, niveau, club..."
              />
            </label>
          </form>

          <button
            type="button"
            class="btn feed-cta feed-cta-secondary mercato-filter-trigger"
            phx-click="open_filters_modal"
          >
            {@filters_button_label}
          </button>
        </div>

        <div class="mercato-active-filters mercato-active-filters-board">
          <span :for={label <- @filter_chip_labels} class="mercato-active-filter mercato-search-chip">
            {label}
          </span>
        </div>
      </div>

      <div class="mercato-section-head mercato-board-head">
        <p class="kicker">
          Offres a la une ({min(@announcement_total, max(length(@announcements), 3))})
        </p>
      </div>

      <div class="mercato-announcement-list">
        <.announcement_card
          :for={{announcement, index} <- Enum.with_index(@announcements, 1)}
          announcement={announcement}
          index={index}
        />

        <article :if={@announcements == []} class="mercato-empty-state">
          <p class="kicker">Aucune annonce</p>
          <p class="section-subtitle">Ajuste les filtres ou publie la tienne.</p>
        </article>
      </div>

      <div class="mercato-card-footer">
        <div class="mercato-card-footer-actions">
          <button
            :if={!@show_all_announcements}
            type="button"
            class="ghost-link mercato-footer-link"
            phx-click="show_more_announcements"
          >
            Voir tout / Explorer les opportunites
          </button>

          <button
            :if={@show_all_announcements}
            type="button"
            class="ghost-link mercato-footer-link"
            phx-click="show_less_announcements"
          >
            Voir moins
          </button>
        </div>
      </div>
    </section>
    """
  end

  attr :announcement, :map, required: true
  attr :index, :integer, required: true

  def announcement_card(assigns) do
    ~H"""
    <article class="mercato-announcement-item">
      <div class="mercato-announcement-main">
        <span class="mercato-announcement-badge">{@announcement.badge}</span>

        <div class="mercato-announcement-copy">
          <div class="mercato-announcement-title-row">
            <h3 class="mercato-announcement-title">{@announcement.title}</h3>
          </div>

          <p class="mercato-announcement-detail">{@announcement.detail_line}</p>

          <div class="mercato-announcement-tags">
            <span :for={tag <- @announcement.tags} class="status-pill status-pill-muted">
              {tag}
            </span>
          </div>
        </div>

        <div class="mercato-announcement-side">
          <p class="mercato-announcement-age">{@announcement.age_label}</p>
          <p class="mercato-announcement-meta">{@announcement.byline}</p>

          <a href={@announcement.view_to} class="btn feed-cta feed-cta-secondary mercato-row-cta">
            {@announcement.cta_label}
          </a>
        </div>
      </div>
    </article>
    """
  end

  attr :filter_form, :any, required: true
  attr :region_options, :list, required: true
  attr :role_options, :list, required: true
  attr :level_options, :list, required: true
  attr :availability_options, :list, required: true
  attr :filters_active, :boolean, required: true

  def filters_form(assigns) do
    ~H"""
    <form phx-submit="apply_filters" class="mercato-filter-form">
      <input type="hidden" name={@filter_form[:q].name} value={@filter_form[:q].value} />

      <div class="mercato-filter-grid">
        <label class="field-wrap mercato-filter-field">
          <span class="field-label">Zone</span>
          <select name={@filter_form[:region].name} class="field-input">
            <option value="" selected={@filter_form[:region].value in [nil, ""]}>Toutes</option>
            <option
              :for={region <- @region_options}
              value={region}
              selected={@filter_form[:region].value == region}
            >
              {region}
            </option>
          </select>
        </label>

        <label class="field-wrap mercato-filter-field">
          <span class="field-label">Role</span>
          <select name={@filter_form[:role].name} class="field-input">
            <option value="" selected={@filter_form[:role].value in [nil, ""]}>Tous</option>
            <option
              :for={role <- @role_options}
              value={Atom.to_string(role)}
              selected={@filter_form[:role].value == Atom.to_string(role)}
            >
              {Labels.role_label(role)}
            </option>
          </select>
        </label>

        <label class="field-wrap mercato-filter-field">
          <span class="field-label">Niveau</span>
          <select name={@filter_form[:level].name} class="field-input">
            <option value="" selected={@filter_form[:level].value in [nil, ""]}>Tous</option>
            <option
              :for={level <- @level_options}
              value={Atom.to_string(level)}
              selected={@filter_form[:level].value == Atom.to_string(level)}
            >
              {Labels.level_label(level)}
            </option>
          </select>
        </label>

        <label class="field-wrap mercato-filter-field">
          <span class="field-label">Disponibilite</span>
          <select name={@filter_form[:availability].name} class="field-input">
            <option value="" selected={@filter_form[:availability].value in [nil, ""]}>
              Toutes
            </option>
            <option
              :for={availability <- @availability_options}
              value={Atom.to_string(availability)}
              selected={@filter_form[:availability].value == Atom.to_string(availability)}
            >
              {Labels.availability_label(availability)}
            </option>
          </select>
        </label>
      </div>

      <div class="mercato-modal-actions">
        <button
          :if={@filters_active}
          type="button"
          class="ghost-link"
          phx-click="clear_filters"
        >
          Reinitialiser
        </button>

        <button type="submit" class="btn feed-cta feed-cta-primary mercato-modal-submit">
          Appliquer
        </button>
      </div>
    </form>
    """
  end

  attr :publish_form, :any, required: true
  attr :publish_errors, :map, required: true
  attr :role_options, :list, required: true
  attr :publish_level_options, :list, required: true
  attr :publish_availability_options, :list, required: true

  def publish_form(assigns) do
    ~H"""
    <form phx-change="change_publish" phx-submit="publish_announcement" class="mercato-publish-form">
      <div class="mercato-publish-grid">
        <label class="field-wrap">
          <span class="field-label">Zone</span>
          <input
            type="text"
            name={@publish_form[:region].name}
            value={@publish_form[:region].value}
            class="field-input"
            placeholder="Ex: Casablanca"
          />
          <p :for={message <- error_messages(@publish_errors, :region)} class="field-error">
            {message}
          </p>
        </label>

        <label class="field-wrap">
          <span class="field-label">Role</span>
          <select name={@publish_form[:role].name} class="field-input">
            <option
              :for={role <- @role_options}
              value={Atom.to_string(role)}
              selected={@publish_form[:role].value == Atom.to_string(role)}
            >
              {Labels.role_label(role)}
            </option>
          </select>
          <p :for={message <- error_messages(@publish_errors, :role)} class="field-error">
            {message}
          </p>
        </label>

        <label class="field-wrap">
          <span class="field-label">Niveau</span>
          <select name={@publish_form[:level].name} class="field-input">
            <option
              :for={level <- @publish_level_options}
              value={Atom.to_string(level)}
              selected={@publish_form[:level].value == Atom.to_string(level)}
            >
              {Labels.level_label(level)}
            </option>
          </select>
          <p :for={message <- error_messages(@publish_errors, :level)} class="field-error">
            {message}
          </p>
        </label>

        <label class="field-wrap">
          <span class="field-label">Disponibilite</span>
          <select name={@publish_form[:availability].name} class="field-input">
            <option
              :for={availability <- @publish_availability_options}
              value={Atom.to_string(availability)}
              selected={@publish_form[:availability].value == Atom.to_string(availability)}
            >
              {Labels.availability_label(availability)}
            </option>
          </select>
          <p :for={message <- error_messages(@publish_errors, :availability)} class="field-error">
            {message}
          </p>
        </label>
      </div>

      <label class="field-wrap">
        <span class="field-label">Annonce</span>
        <textarea
          name={@publish_form[:content].name}
          class="field-input mercato-publish-textarea"
          rows="5"
          placeholder="Ex: Je cherche un club en N2, disponible rapidement a Casablanca."
        ><%= @publish_form[:content].value %></textarea>
        <p :for={message <- error_messages(@publish_errors, :content)} class="field-error">
          {message}
        </p>
      </label>

      <button type="submit" class="btn feed-cta feed-cta-primary mercato-publish-submit">
        Publier mon annonce
      </button>
    </form>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :close_event, :string, required: true
  slot :inner_block, required: true

  def modal_shell(assigns) do
    ~H"""
    <section
      id={@id}
      class="mercato-modal-shell"
      phx-window-keydown={@close_event}
      phx-key="escape"
    >
      <button
        type="button"
        class="mercato-modal-backdrop"
        phx-click={@close_event}
        aria-label="Fermer"
      />

      <div
        class="mercato-modal-card"
        role="dialog"
        aria-modal="true"
        aria-labelledby={"#{@id}-title"}
        phx-click-away={@close_event}
      >
        <div class="mercato-modal-head">
          <div>
            <p class="kicker">Mercato</p>
            <h2 id={"#{@id}-title"} class="section-title mercato-card-title">{@title}</h2>
            <p :if={@subtitle} class="section-subtitle mercato-page-subtitle">{@subtitle}</p>
          </div>

          <button
            type="button"
            class="ghost-link mercato-modal-close"
            phx-click={@close_event}
            aria-label="Fermer"
          >
            Fermer
          </button>
        </div>

        <div class="mercato-modal-body">{render_slot(@inner_block)}</div>
      </div>
    </section>
    """
  end

  defp error_messages(errors, field), do: Map.get(errors, field, [])
end
