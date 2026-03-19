defmodule SocialAppWeb.MercatoLive do
  use SocialAppWeb, :live_view

  alias SocialApp.{Accounts, Labels, Posts, Recruitment}
  alias SocialAppWeb.MercatoLive.Components, as: MercatoComponents

  @preview_limit 3
  @expanded_limit 50
  @filter_defaults %{
    "q" => "",
    "region" => "",
    "role" => "",
    "level" => "",
    "availability" => ""
  }

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    {:ok,
     socket
     |> SocialAppWeb.PageShellComponents.assign_shell(:mercato, "Mercato")
     |> assign(:current_user_id, current_user.id)
     |> assign(:current_user_region, blank_to_nil(current_user.region))
     |> assign(:show_all_announcements, false)
     |> assign(:announcement_total, 0)
     |> assign(:announcements, [])
     |> assign(:filters_modal_open, false)
     |> assign(:publish_modal_open, false)
     |> assign(:publish_errors, %{})
     |> assign(:publish_notice, nil)
     |> assign(:role_options, Labels.role_values())
     |> assign(:publish_level_options, Labels.level_values())
     |> assign(:publish_availability_options, Labels.availability_values())
     |> assign(:filter, @filter_defaults)
     |> assign(:filter_form, to_form(@filter_defaults, as: :filters))
     |> load_directory_facets()
     |> assign_publish_form(current_user)
     |> load_announcements()}
  end

  @impl true
  def handle_event("filter", %{"filters" => params}, socket) do
    {:noreply, socket |> apply_filters(params)}
  end

  @impl true
  def handle_event("apply_filters", %{"filters" => params}, socket) do
    {:noreply,
     socket
     |> apply_filters(params)
     |> assign(:filters_modal_open, false)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_all_announcements, false)
     |> assign(:filter, @filter_defaults)
     |> assign(:filter_form, to_form(@filter_defaults, as: :filters))
     |> load_announcements()}
  end

  @impl true
  def handle_event("show_more_announcements", _params, socket) do
    {:noreply, socket |> assign(:show_all_announcements, true) |> load_announcements()}
  end

  @impl true
  def handle_event("show_less_announcements", _params, socket) do
    {:noreply, socket |> assign(:show_all_announcements, false) |> load_announcements()}
  end

  @impl true
  def handle_event("open_filters_modal", _params, socket) do
    {:noreply, assign(socket, :filters_modal_open, true)}
  end

  @impl true
  def handle_event("close_filters_modal", _params, socket) do
    {:noreply, assign(socket, :filters_modal_open, false)}
  end

  @impl true
  def handle_event("open_publish_modal", params, socket) do
    socket =
      case params["role"] do
        role when role in ["club", "player"] ->
          publish_params =
            socket.assigns.current_user
            |> publish_defaults()
            |> Map.put("role", role)

          socket
          |> assign(:publish_params, publish_params)
          |> assign(:publish_form, to_form(publish_params, as: :announcement))

        _ ->
          socket
      end

    {:noreply, assign(socket, :publish_modal_open, true)}
  end

  @impl true
  def handle_event("close_publish_modal", _params, socket) do
    {:noreply, assign(socket, :publish_modal_open, false)}
  end

  @impl true
  def handle_event("change_publish", %{"announcement" => params}, socket) do
    publish_params = normalize_publish_params(socket.assigns.current_user, params)

    {:noreply,
     socket
     |> assign(:publish_notice, nil)
     |> assign(:publish_errors, %{})
     |> assign(:publish_modal_open, true)
     |> assign(:publish_params, publish_params)
     |> assign(:publish_form, to_form(publish_params, as: :announcement))}
  end

  @impl true
  def handle_event("publish_announcement", %{"announcement" => params}, socket) do
    publish_params = normalize_publish_params(socket.assigns.current_user, params)

    case Recruitment.publish_announcement(
           socket.assigns.current_user,
           parse_publish_attrs(publish_params)
         ) do
      {:ok, %{user: updated_user, post: post}} ->
        {:noreply,
         socket
         |> assign(:current_user, updated_user)
         |> assign(:current_user_region, blank_to_nil(updated_user.region))
         |> assign(:publish_errors, %{})
         |> assign(:publish_modal_open, false)
         |> assign(:publish_notice, %{post_id: post.id})
         |> load_directory_facets()
         |> assign_publish_form(updated_user)
         |> load_announcements()
         |> put_flash(:info, "Annonce publiee")}

      {:error, _step, changeset} ->
        {:noreply,
         socket
         |> assign(:publish_notice, nil)
         |> assign(:publish_errors, changeset_errors(changeset))
         |> assign(:publish_modal_open, true)
         |> assign(:publish_params, publish_params)
         |> assign(:publish_form, to_form(publish_params, as: :announcement))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.goalzone_shell
      current_user={@current_user}
      active_nav={@active_nav}
      left_rail_cta={%{type: :event, label: "Publier une annonce", event: "open_publish_modal"}}
      right_rail={mercato_right_rail()}
    >
      <section class="stack-lg mercato-minimal-page">
        <MercatoComponents.page_header publish_notice={@publish_notice} />

        <MercatoComponents.results_panel
          filter_form={@filter_form}
          filters_button_label={filters_button_label(@filter)}
          active_filter_labels={active_filter_labels(@filter)}
          announcements={@announcements}
          announcement_total={@announcement_total}
          show_all_announcements={@show_all_announcements}
        />

        <MercatoComponents.modal_shell
          :if={@filters_modal_open}
          id="mercato-filters-modal"
          title="Filtres annonces"
          subtitle="Affiner sans charger la colonne centrale."
          close_event="close_filters_modal"
        >
          <MercatoComponents.filters_form
            filter_form={@filter_form}
            region_options={@region_options}
            role_options={@role_options}
            level_options={@level_options}
            availability_options={@availability_options}
            filters_active={filters_active?(@filter)}
          />
        </MercatoComponents.modal_shell>

        <MercatoComponents.modal_shell
          :if={@publish_modal_open}
          id="mercato-publish-modal"
          title="Publier une annonce"
          subtitle="Un cadre propre. Un message clair. Rien de plus."
          close_event="close_publish_modal"
        >
          <MercatoComponents.publish_form
            publish_form={@publish_form}
            publish_errors={@publish_errors}
            role_options={@role_options}
            publish_level_options={@publish_level_options}
            publish_availability_options={@publish_availability_options}
          />
        </MercatoComponents.modal_shell>
      </section>
    </.goalzone_shell>
    """
  end

  defp load_announcements(socket) do
    filters = parse_filter(socket.assigns.filter)

    total =
      Posts.count_recruitment_posts(filters, exclude_user_id: socket.assigns.current_user_id)

    limit = if(socket.assigns.show_all_announcements, do: @expanded_limit, else: @preview_limit)

    announcements =
      Posts.list_recruitment_posts(filters,
        exclude_user_id: socket.assigns.current_user_id,
        limit: min(limit, max(total, @preview_limit)),
        viewer_region: socket.assigns.current_user_region
      )
      |> Enum.map(&announcement_card/1)

    socket
    |> assign(:announcement_total, total)
    |> assign(:announcements, announcements)
  end

  defp apply_filters(socket, params) do
    filter = normalize_filter_params(params)

    socket
    |> assign(:show_all_announcements, false)
    |> assign(:filter, filter)
    |> assign(:filter_form, to_form(filter, as: :filters))
    |> load_announcements()
  end

  defp load_directory_facets(socket) do
    facets = Accounts.directory_facets(exclude_user_id: socket.assigns.current_user_id)
    current_user = socket.assigns.current_user

    socket
    |> assign(:region_options, merge_string_option(facets.regions, current_user.region))
    |> assign(:level_options, merge_atom_option(facets.levels, current_user.level))
    |> assign(
      :availability_options,
      merge_atom_option(facets.availabilities, current_user.availability)
    )
  end

  defp assign_publish_form(socket, user) do
    params = publish_defaults(user)

    socket
    |> assign(:publish_params, params)
    |> assign(:publish_form, to_form(params, as: :announcement))
  end

  defp announcement_card(post) do
    %{
      title: announcement_title(post.content),
      excerpt: announcement_excerpt(post.content),
      byline:
        "@#{post.user.username} · #{Labels.role_label(post.user.role)} · #{display_date(post.inserted_at)}",
      context:
        [
          blank_to_nil(post.user.region) || "zone ouverte",
          Labels.level_label(post.user.level),
          Labels.availability_label(post.user.availability)
        ]
        |> Enum.reject(&is_nil/1)
        |> Enum.join(" · "),
      tags:
        [
          blank_to_nil(post.user.region),
          Labels.level_label(post.user.level),
          Labels.availability_label(post.user.availability)
        ]
        |> Enum.reject(&is_nil/1),
      badge: announcement_badge(post.user),
      detail_line:
        [
          blank_to_nil(post.user.region) || "zone ouverte",
          Labels.level_label(post.user.level)
        ]
        |> Enum.reject(&is_nil/1)
        |> Enum.join(" · "),
      age_label: relative_age_label(post.inserted_at),
      cta_label: announcement_cta_label(post.user.role),
      view_to: ~p"/posts/#{post.id}",
      contact_to: ~p"/messages?#{[to: post.user_id]}"
    }
  end

  defp announcement_title(nil), do: "Annonce recrutement"

  defp announcement_title(content) do
    content = String.trim(content)

    cond do
      content == "" -> "Annonce recrutement"
      String.length(content) <= 58 -> content
      true -> "#{String.slice(content, 0, 58)}..."
    end
  end

  defp announcement_excerpt(nil), do: nil

  defp announcement_excerpt(content) do
    content = String.trim(content)

    cond do
      content == "" -> nil
      String.length(content) <= 58 -> nil
      String.length(content) <= 150 -> content
      true -> "#{String.slice(content, 0, 150)}..."
    end
  end

  defp filters_button_label(filter) do
    case length(active_filter_labels(filter)) do
      0 -> "Filtres"
      count -> "Filtres (#{count})"
    end
  end

  defp normalize_filter_params(params) do
    @filter_defaults
    |> Map.merge(Map.new(params))
    |> Map.take(Map.keys(@filter_defaults))
  end

  defp normalize_publish_params(user, params) do
    user
    |> publish_defaults()
    |> Map.merge(Map.new(params))
    |> Map.update!("content", &String.trim/1)
  end

  defp publish_defaults(user) do
    %{
      "region" => user.region || "",
      "role" => user.role |> fallback_atom(:player) |> Atom.to_string(),
      "level" => user.level |> fallback_atom(:espoir) |> Atom.to_string(),
      "availability" => user.availability |> fallback_atom(:open) |> Atom.to_string(),
      "content" => ""
    }
  end

  defp parse_filter(filter) do
    []
    |> maybe_put_filter(:q, blank_to_nil(filter["q"]))
    |> maybe_put_filter(:region, blank_to_nil(filter["region"]))
    |> maybe_put_filter(:role, Labels.parse_role(filter["role"]))
    |> maybe_put_filter(:level, Labels.parse_level(filter["level"]))
    |> maybe_put_filter(:availability, Labels.parse_availability(filter["availability"]))
    |> Map.new()
  end

  defp parse_publish_attrs(params) do
    %{
      region: blank_to_nil(params["region"]),
      role: Labels.parse_role(params["role"]),
      level: Labels.parse_level(params["level"]),
      availability: Labels.parse_availability(params["availability"]),
      content: blank_to_nil(params["content"])
    }
  end

  defp filters_active?(filter), do: filter != @filter_defaults

  defp active_filter_labels(filter) do
    []
    |> maybe_add_filter_label(search_filter_label(filter["q"]))
    |> maybe_add_filter_label(blank_to_nil(filter["region"]))
    |> maybe_add_filter_label(label_for_role(filter["role"]))
    |> maybe_add_filter_label(label_for_level(filter["level"]))
    |> maybe_add_filter_label(label_for_availability(filter["availability"]))
  end

  defp mercato_right_rail do
    %{
      hide_search_panel: true,
      hide_premium_panel: true,
      hide_coach_panel: true,
      radar_title: "Repere",
      radar_items: [
        %{
          kicker: "Lire",
          title: "Zone, niveau, disponibilite.",
          meta: "Le cadre avant le texte."
        },
        %{
          kicker: "Choisir",
          title: "Trois cartes d'abord.",
          meta: "Tu decides avant d'elargir."
        },
        %{
          kicker: "Agir",
          title: "Contacte ou passe.",
          meta: "Aucune friction inutile."
        }
      ]
    }
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  defp merge_string_option(options, value) do
    options
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Kernel.++(if present?(value), do: [String.trim(value)], else: [])
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp merge_atom_option(options, nil), do: Enum.sort(options)

  defp merge_atom_option(options, value) do
    options
    |> Kernel.++([value])
    |> Enum.uniq()
    |> Enum.sort_by(&Atom.to_string/1)
  end

  defp display_date(nil), do: "date inconnue"
  defp display_date(%DateTime{} = value), do: Calendar.strftime(value, "%d/%m/%Y")
  defp display_date(%NaiveDateTime{} = value), do: Calendar.strftime(value, "%d/%m/%Y")
  defp display_date(_), do: "date inconnue"

  defp relative_age_label(nil), do: "a l'instant"

  defp relative_age_label(%NaiveDateTime{} = value) do
    value
    |> DateTime.from_naive!("Etc/UTC")
    |> relative_age_label()
  end

  defp relative_age_label(%DateTime{} = value) do
    diff = DateTime.diff(DateTime.utc_now(), value, :second)

    cond do
      diff < 3600 -> "il y a #{max(div(diff, 60), 1)} min"
      diff < 86_400 -> "il y a #{div(diff, 3600)}h"
      true -> "il y a #{div(diff, 86_400)}j"
    end
  end

  defp relative_age_label(_), do: "recent"

  defp announcement_badge(user) do
    user.username
    |> blank_to_nil()
    |> case do
      nil -> role_badge(user.role)
      username -> username |> String.first() |> String.upcase()
    end
  end

  defp announcement_cta_label(:club), do: "Voir & postuler"
  defp announcement_cta_label(:player), do: "Voir le profil"
  defp announcement_cta_label(:coach), do: "Voir l'annonce"
  defp announcement_cta_label(:agent), do: "Voir l'annonce"
  defp announcement_cta_label(_role), do: "Voir l'annonce"

  defp role_badge(role) do
    role
    |> Labels.role_label()
    |> String.first()
    |> case do
      nil -> "G"
      initial -> String.upcase(initial)
    end
  end

  defp maybe_put_filter(list, _key, nil), do: list
  defp maybe_put_filter(list, _key, ""), do: list
  defp maybe_put_filter(list, key, value), do: [{key, value} | list]

  defp maybe_add_filter_label(list, nil), do: list
  defp maybe_add_filter_label(list, value), do: list ++ [value]

  defp label_for_role(value) do
    case Labels.parse_role(value) do
      nil -> nil
      role -> Labels.role_label(role)
    end
  end

  defp label_for_level(value) do
    case Labels.parse_level(value) do
      nil -> nil
      level -> Labels.level_label(level)
    end
  end

  defp label_for_availability(value) do
    case Labels.parse_availability(value) do
      nil -> nil
      availability -> Labels.availability_label(availability)
    end
  end

  defp search_filter_label(value) do
    case blank_to_nil(value) do
      nil -> nil
      query -> "Recherche: #{query}"
    end
  end

  defp blank_to_nil(nil), do: nil

  defp blank_to_nil(value) when is_binary(value) do
    value = String.trim(value)
    if value == "", do: nil, else: value
  end

  defp blank_to_nil(value), do: value

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(value), do: not is_nil(value)

  defp fallback_atom(nil, default), do: default
  defp fallback_atom(value, _default), do: value
end
