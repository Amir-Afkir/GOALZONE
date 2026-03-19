defmodule SocialAppWeb.NetworkLive do
  use SocialAppWeb, :live_view

  alias SocialApp.{Accounts, Labels}
  alias SocialAppWeb.NetworkLive.Components

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> SocialAppWeb.PageShellComponents.assign_shell(:reseau, "Reseau")
     |> assign(:mini_coach, %{
       page: "reseau",
       where: "Reseau (connexions)",
       goal: "Construire un vivier actif de contacts utiles",
       next: "Ajoute 1 connexion puis envoie un premier message.",
       cta_to: ~p"/messages",
       cta_label: "Ouvrir messages"
     })
     |> assign(:current_user_id, socket.assigns.current_user.id)
     |> assign(:show_all_suggestions, false)
     |> load_network()}
  end

  @impl true
  def handle_event("toggle_follow", %{"user_id" => user_id}, socket) do
    with {:ok, parsed_user_id} <- parse_user_id(user_id) do
      current_user_id = socket.assigns.current_user_id

      if parsed_user_id in socket.assigns.followed_ids do
        _ = Accounts.unfollow_user(current_user_id, parsed_user_id)
      else
        _ = Accounts.follow_user(current_user_id, parsed_user_id)
      end

      {:noreply, load_network(socket)}
    else
      {:error, :invalid_id} ->
        {:noreply, put_flash(socket, :error, "Action invalide")}
    end
  end

  @impl true
  def handle_event("show_all_suggestions", _params, socket) do
    {:noreply, assign(socket, :show_all_suggestions, true)}
  end

  @impl true
  def handle_event("show_less_suggestions", _params, socket) do
    {:noreply, assign(socket, :show_all_suggestions, false)}
  end

  @impl true
  def render(assigns) do
    Components.render(assigns)
  end

  defp load_network(socket) do
    current_user_id = socket.assigns.current_user_id
    following = Accounts.list_following(current_user_id)
    followed_ids = Enum.map(following, & &1.id)
    suggestions = Accounts.list_suggested_users(current_user_id, limit: 8)
    current_user = socket.assigns.current_user

    assign(socket,
      following: following,
      followed_ids: followed_ids,
      suggestions: suggestions,
      visible_suggestion_cards: visible_suggestion_cards(suggestions, current_user, socket.assigns.show_all_suggestions),
      connection_cards: Enum.map(following, &build_connection_card(&1, current_user)),
      suggestion_cards: Enum.map(suggestions, &build_suggestion_card(&1, current_user))
    )
  end

  defp visible_suggestion_cards(suggestions, current_user, true) do
    Enum.map(suggestions, &build_suggestion_card(&1, current_user))
  end

  defp visible_suggestion_cards(suggestions, current_user, false) do
    suggestions
    |> Enum.take(3)
    |> Enum.map(&build_suggestion_card(&1, current_user))
  end

  defp build_suggestion_card(user, current_user) do
    %{
      id: user.id,
      username: user.username,
      profile_href: ~p"/profile/#{user.username}",
      role: Labels.role_label(user.role),
      level: Labels.level_label(user.level),
      region: present_region(user.region),
      headline: compact_headline(user.headline),
      meta: compact_meta(user, current_user)
    }
  end

  defp build_connection_card(user, current_user) do
    %{
      id: user.id,
      username: user.username,
      profile_href: ~p"/profile/#{user.username}",
      role: Labels.role_label(user.role),
      level: Labels.level_label(user.level),
      region: present_region(user.region),
      headline: fallback_headline(user.headline),
      badge: "Connexion active",
      meta: connection_meta(user, current_user),
      signals: connection_signals(user, current_user)
    }
  end

  defp connection_signals(user, current_user) do
    [
      same_region_signal(user, current_user),
      level_signal(user),
      "Pret pour un message"
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.take(3)
  end

  defp same_region_signal(user, current_user) do
    current_region = blank_to_nil(current_user.region)
    user_region = blank_to_nil(user.region)

    if current_region && user_region && current_region == user_region do
      "Meme zone: #{user_region}"
    end
  end

  defp level_signal(user), do: "Niveau: #{Labels.level_label(user.level)}"

  defp compact_meta(user, current_user) do
    case same_region_signal(user, current_user) do
      nil -> nil
      signal -> signal
    end
  end

  defp connection_meta(user, current_user) do
    if blank_to_nil(user.region) == blank_to_nil(current_user.region) do
      "Connexion locale a activer"
    else
      "Connexion a recontacter"
    end
  end

  defp fallback_headline(nil), do: "Profil en cours de qualification"
  defp fallback_headline(""), do: "Profil en cours de qualification"
  defp fallback_headline(value), do: value

  defp compact_headline(nil), do: nil
  defp compact_headline(""), do: nil

  defp compact_headline(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp present_region(nil), do: "Region a confirmer"
  defp present_region(""), do: "Region a confirmer"
  defp present_region(value), do: value

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp parse_user_id(nil), do: {:error, :invalid_id}
  defp parse_user_id(""), do: {:error, :invalid_id}

  defp parse_user_id(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} when parsed > 0 -> {:ok, parsed}
      _ -> {:error, :invalid_id}
    end
  end

  defp parse_user_id(_), do: {:error, :invalid_id}
end
