defmodule SocialAppWeb.TalentsLive do
  use SocialAppWeb, :live_view

  alias SocialApp.{Accounts, Labels}

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id
    base_filter = %{"q" => "", "role" => "", "region" => "", "level" => "", "availability" => ""}

    {:ok,
     socket
     |> assign(:page_context, "Talents")
     |> assign(:mini_coach, %{
       page: "talents",
       where: "Talents (annuaire profils)",
       goal: "Trouver rapidement des profils cibles",
       next: "Applique 1 ou 2 filtres puis ouvre un profil.",
       cta_to: ~p"/reseau",
       cta_label: "Voir le reseau"
     })
     |> assign(:current_user_id, user_id)
     |> assign(:filter, base_filter)
     |> assign(:filter_form, to_form(base_filter, as: :filters))
     |> load_directory()}
  end

  @impl true
  def handle_event("filter", %{"filters" => params}, socket) do
    filter =
      socket.assigns.filter
      |> Map.merge(params)
      |> Map.update!("q", &String.trim/1)

    {:noreply,
     socket
     |> assign(:filter, filter)
     |> assign(:filter_form, to_form(filter, as: :filters))
     |> load_directory()}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    filter = %{"q" => "", "role" => "", "region" => "", "level" => "", "availability" => ""}

    {:noreply,
     socket
     |> assign(:filter, filter)
     |> assign(:filter_form, to_form(filter, as: :filters))
     |> load_directory()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="stack-lg">
      <header class="panel matchday-hero">
        <p class="kicker">Scout Search</p>
        <h1 class="section-title">Explorer les talents</h1>
        <p class="section-subtitle">
          Recherche par role, region, niveau et disponibilite, comme dans TTC.
        </p>
      </header>

      <form phx-change="filter" class="panel stack-md">
        <div class="filters-grid">
          <label class="field-wrap">
            <span class="field-label">Recherche</span>
            <input
              class="field-input"
              type="text"
              name={@filter_form[:q].name}
              value={@filter_form[:q].value}
              placeholder="Nom, headline, poste, region"
            />
          </label>

          <label class="field-wrap">
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

          <label class="field-wrap">
            <span class="field-label">Region</span>
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

          <label class="field-wrap">
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

          <label class="field-wrap">
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

        <div class="post-actions">
          <span class="meta-line">{length(@directory)} resultats</span>
          <button type="button" class="ghost-link" phx-click="clear_filters">Reinitialiser</button>
        </div>
      </form>

      <section class="stack-md">
        <article :for={user <- @directory} class="panel directory-card">
          <div>
            <a href={~p"/profile/#{user.username}"} class="text-link">@{user.username}</a>
            <p class="meta-line">
              {Labels.role_label(user.role)} · {Labels.level_label(user.level)} · {user.region}
            </p>
            <p class="post-content">
              {if String.trim(user.headline || "") == "",
                do: "Profil en cours de qualification",
                else: user.headline}
            </p>
          </div>
          <a href={~p"/profile/#{user.username}"} class="ghost-link">Voir profil</a>
        </article>

        <article :if={@directory == []} class="panel">
          <p class="meta-line">Aucun profil ne correspond a ces filtres.</p>
        </article>
      </section>
    </section>
    """
  end

  defp load_directory(socket) do
    user_id = socket.assigns.current_user_id
    filter = socket.assigns.filter
    all_users = Accounts.list_directory(%{}, exclude_user_id: user_id, limit: 300)
    filters = parse_filter(filter)

    filtered =
      Accounts.list_directory(
        filters,
        exclude_user_id: user_id,
        limit: 200
      )

    socket
    |> assign(:directory, filtered)
    |> assign(:role_options, Labels.role_values())
    |> assign(
      :region_options,
      all_users
      |> Enum.map(& &1.region)
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.uniq()
      |> Enum.sort()
    )
    |> assign(:level_options, all_users |> Enum.map(& &1.level) |> Enum.uniq())
    |> assign(:availability_options, all_users |> Enum.map(& &1.availability) |> Enum.uniq())
  end

  defp parse_filter(filter) do
    []
    |> maybe_put_filter(:q, filter["q"])
    |> maybe_put_filter(:role, Labels.parse_role(filter["role"]))
    |> maybe_put_filter(:region, blank_to_nil(filter["region"]))
    |> maybe_put_filter(:level, Labels.parse_level(filter["level"]))
    |> maybe_put_filter(:availability, Labels.parse_availability(filter["availability"]))
    |> Map.new()
  end

  defp maybe_put_filter(list, _key, nil), do: list
  defp maybe_put_filter(list, _key, ""), do: list
  defp maybe_put_filter(list, key, value), do: [{key, value} | list]

  defp blank_to_nil(nil), do: nil

  defp blank_to_nil(value) do
    value = String.trim(value)
    if value == "", do: nil, else: value
  end
end
