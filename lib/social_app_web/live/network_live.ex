defmodule SocialAppWeb.NetworkLive do
  use SocialAppWeb, :live_view

  alias SocialApp.{Accounts, Labels}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_context, "Reseau")
     |> assign(:mini_coach, %{
       page: "reseau",
       where: "Reseau (connexions)",
       goal: "Construire un vivier actif de contacts utiles",
       next: "Ajoute 1 connexion puis envoie un premier message.",
       cta_to: ~p"/messages",
       cta_label: "Ouvrir messages"
     })
     |> assign(:current_user_id, socket.assigns.current_user.id)
     |> load_network()}
  end

  @impl true
  def handle_event("toggle_follow", %{"user_id" => user_id}, socket) do
    user_id = String.to_integer(user_id)
    current_user_id = socket.assigns.current_user_id

    if user_id in socket.assigns.followed_ids do
      _ = Accounts.unfollow_user(current_user_id, user_id)
    else
      _ = Accounts.follow_user(current_user_id, user_id)
    end

    {:noreply, load_network(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="stack-lg">
      <header class="panel matchday-hero">
        <p class="kicker">Network</p>
        <h1 class="section-title">Reseau professionnel</h1>
        <p class="section-subtitle">
          Connecte-toi avec scouts, clubs, agents et joueurs cibles.
        </p>
      </header>

      <section class="panel stack-md">
        <div class="post-actions">
          <h2 class="section-title">Connexions actives</h2>
          <span class="meta-line">{length(@following)} connexions</span>
        </div>

        <article :for={user <- @following} class="directory-card">
          <div>
            <a href={~p"/profile/#{user.username}"} class="text-link">@{user.username}</a>
            <p class="meta-line">
              {Labels.role_label(user.role)} · {Labels.level_label(user.level)} · {user.region}
            </p>
            <p class="post-content">{fallback_headline(user.headline)}</p>
          </div>
          <button class="ghost-link" phx-click="toggle_follow" phx-value-user_id={user.id}>
            Retirer
          </button>
        </article>

        <p :if={@following == []} class="meta-line">Aucune connexion pour le moment.</p>
      </section>

      <section class="panel stack-md">
        <div class="post-actions">
          <h2 class="section-title">Suggestions</h2>
          <span class="meta-line">{length(@suggestions)} profils</span>
        </div>

        <article :for={user <- @suggestions} class="directory-card">
          <div>
            <a href={~p"/profile/#{user.username}"} class="text-link">@{user.username}</a>
            <p class="meta-line">
              {Labels.role_label(user.role)} · {Labels.level_label(user.level)} · {user.region}
            </p>
            <p class="post-content">{fallback_headline(user.headline)}</p>
          </div>
          <button class="ghost-link" phx-click="toggle_follow" phx-value-user_id={user.id}>
            Connecter
          </button>
        </article>
      </section>
    </section>
    """
  end

  defp load_network(socket) do
    current_user_id = socket.assigns.current_user_id
    following = Accounts.list_following(current_user_id)
    followed_ids = Enum.map(following, & &1.id)

    suggestions =
      Accounts.list_directory(%{}, exclude_user_id: current_user_id, limit: 200)
      |> Enum.reject(&(&1.id in followed_ids))
      |> Enum.take(8)

    assign(socket,
      following: following,
      followed_ids: followed_ids,
      suggestions: suggestions
    )
  end

  defp fallback_headline(nil), do: "Profil en cours de qualification"
  defp fallback_headline(""), do: "Profil en cours de qualification"
  defp fallback_headline(value), do: value
end
