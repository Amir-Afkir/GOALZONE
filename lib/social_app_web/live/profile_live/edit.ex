defmodule SocialAppWeb.ProfileLive.Edit do
  use SocialAppWeb, :live_view

  alias SocialApp.{Accounts, Labels}

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    form_params = form_params_from_user(user)

    {:ok,
     socket
     |> SocialAppWeb.PageShellComponents.assign_shell(:profil, "Edition profil")
     |> assign(
       mini_coach: %{
         page: "profil-edit",
         where: "Edition profil",
         goal: "Rendre ton profil lisible et credible",
         next: "Renseigne headline, role, region, niveau puis enregistre.",
         cta_to: ~p"/profile/#{user.username}",
         cta_label: "Voir mon profil"
       },
       form_data: form_params,
       form: to_form(form_params, as: :profile)
     )}
  end

  @impl true
  def handle_event("validate", %{"profile" => params}, socket) do
    params = Map.merge(socket.assigns.form_data, params)

    {:noreply,
     socket
     |> assign(:form_data, params)
     |> assign(:form, to_form(params, as: :profile))}
  end

  @impl true
  def handle_event("save", %{"profile" => params}, socket) do
    attrs = build_profile_attrs(params)

    case Accounts.update_user(socket.assigns.current_user, attrs) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profil mis a jour.")
         |> push_navigate(to: ~p"/profile/#{socket.assigns.current_user.username}")}

      {:error, changeset} ->
        params = Map.merge(socket.assigns.form_data, params)

        {:noreply,
         socket
         |> assign(:form_data, params)
         |> assign(:form, to_form(params, as: :profile))
         |> put_flash(:error, translate_changeset_errors(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.goalzone_shell current_user={@current_user} active_nav={@active_nav}>
      <section class="stack-lg">
        <header class="panel feed-panel matchday-hero">
          <p class="kicker">Profile Setup</p>
          <h1 class="section-title">Editer mon profil</h1>
          <p class="section-subtitle">
            Mets a jour ton role, ton contexte sportif et tes preuves recrutement.
          </p>
        </header>

        <form phx-submit="save" phx-change="validate" class="panel feed-panel stack-md">
          <div class="filters-grid">
            <label class="field-wrap">
              <span class="field-label">Role</span>
              <select name={@form[:role].name} class="field-input">
                <option
                  :for={role <- Labels.role_values()}
                  value={Atom.to_string(role)}
                  selected={@form[:role].value == Atom.to_string(role)}
                >
                  {Labels.role_label(role)}
                </option>
              </select>
            </label>

            <label class="field-wrap">
              <span class="field-label">Niveau</span>
              <select name={@form[:level].name} class="field-input">
                <option
                  :for={level <- Labels.level_values()}
                  value={Atom.to_string(level)}
                  selected={@form[:level].value == Atom.to_string(level)}
                >
                  {Labels.level_label(level)}
                </option>
              </select>
            </label>

            <label class="field-wrap">
              <span class="field-label">Disponibilite</span>
              <select name={@form[:availability].name} class="field-input">
                <option
                  :for={availability <- Labels.availability_values()}
                  value={Atom.to_string(availability)}
                  selected={@form[:availability].value == Atom.to_string(availability)}
                >
                  {Labels.availability_label(availability)}
                </option>
              </select>
            </label>
          </div>

          <label class="field-wrap">
            <span class="field-label">Headline</span>
            <input name={@form[:headline].name} value={@form[:headline].value} class="field-input" />
          </label>

          <div class="filters-grid">
            <label class="field-wrap">
              <span class="field-label">Poste / specialite</span>
              <input name={@form[:position].name} value={@form[:position].value} class="field-input" />
            </label>

            <label class="field-wrap">
              <span class="field-label">Age</span>
              <input
                type="number"
                name={@form[:age].name}
                value={@form[:age].value}
                min="12"
                max="60"
                class="field-input"
              />
            </label>

            <label class="field-wrap">
              <span class="field-label">Region</span>
              <input name={@form[:region].name} value={@form[:region].value} class="field-input" />
            </label>
          </div>

          <label class="field-wrap">
            <span class="field-label">Bio</span>
            <textarea name={@form[:bio].name} class="composer-textarea">{@form[:bio].value}</textarea>
          </label>

          <div class="filters-grid">
            <label class="field-wrap">
              <span class="field-label">Source</span>
              <select name={@form[:source_type].name} class="field-input">
                <option
                  value="highlight_video"
                  selected={@form[:source_type].value == "highlight_video"}
                >
                  Video highlight
                </option>
                <option
                  value="full_match_video"
                  selected={@form[:source_type].value == "full_match_video"}
                >
                  Video match complet
                </option>
                <option
                  value="live_observation"
                  selected={@form[:source_type].value == "live_observation"}
                >
                  Observation live
                </option>
                <option value="stat_report" selected={@form[:source_type].value == "stat_report"}>
                  Rapport stats
                </option>
                <option value="unknown" selected={@form[:source_type].value == "unknown"}>
                  Non precise
                </option>
              </select>
            </label>

            <label class="field-wrap">
              <span class="field-label">Confiance (0-100)</span>
              <input
                type="number"
                min="0"
                max="100"
                name={@form[:confidence_score].name}
                value={@form[:confidence_score].value}
                class="field-input"
              />
            </label>
          </div>

          <div class="post-actions">
            <.button type="submit">Enregistrer</.button>
            <a href={~p"/profile/#{@current_user.username}"} class="ghost-link">Annuler</a>
          </div>
        </form>
      </section>
    </.goalzone_shell>
    """
  end

  defp build_profile_attrs(params) do
    %{
      role: Labels.parse_role(params["role"]) || :player,
      onboarding_completed: true,
      headline: String.trim(params["headline"] || ""),
      position: String.trim(params["position"] || ""),
      age: parse_int(params["age"]),
      region: String.trim(params["region"] || ""),
      level: Labels.parse_level(params["level"]) || :espoir,
      availability: Labels.parse_availability(params["availability"]) || :open,
      bio: String.trim(params["bio"] || ""),
      source_type: parse_source_type(params["source_type"]),
      verification_status: :self_declared,
      confidence_score: parse_int(params["confidence_score"])
    }
  end

  defp form_params_from_user(user) do
    %{
      "role" => Atom.to_string(user.role || :player),
      "headline" => user.headline || "",
      "position" => user.position || "",
      "age" => if(user.age, do: Integer.to_string(user.age), else: ""),
      "region" => user.region || "",
      "level" => Atom.to_string(user.level || :espoir),
      "availability" => Atom.to_string(user.availability || :open),
      "bio" => user.bio || "",
      "source_type" => Atom.to_string(user.source_type || :unknown),
      "confidence_score" =>
        if(user.confidence_score, do: Integer.to_string(user.confidence_score), else: "")
    }
  end

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

  defp parse_source_type(value) do
    case value do
      "highlight_video" -> :highlight_video
      "full_match_video" -> :full_match_video
      "live_observation" -> :live_observation
      "stat_report" -> :stat_report
      _ -> :unknown
    end
  end

  defp translate_changeset_errors(changeset) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)

    "Validation invalide: #{inspect(errors)}"
  end
end
