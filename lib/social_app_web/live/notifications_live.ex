defmodule SocialAppWeb.NotificationsLive do
  use SocialAppWeb, :live_view

  alias SocialApp.Notifications

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SocialApp.PubSub, "user:#{user_id}:notifications")

      SocialAppWeb.Presence.track(self(), "user:#{user_id}", user_id, %{
        online_at: DateTime.utc_now()
      })
    end

    {:ok,
     socket
     |> assign(:page_context, "Alertes")
     |> assign(:mini_coach, %{
       page: "alertes",
       where: "Alertes (inbox actionnable)",
       goal: "Traiter en priorite ce qui demande une action rapide",
       next: "Ouvre la premiere alerte non lue puis agis.",
       cta_to: ~p"/messages",
       cta_label: "Voir messages"
     })
     |> assign_notifications(user_id)}
  end

  @impl true
  def handle_event("mark_all_read", _params, socket) do
    _ = Notifications.mark_all_read(socket.assigns.current_user_id)
    {:noreply, assign_notifications(socket, socket.assigns.current_user_id)}
  end

  @impl true
  def handle_info(:notification_created, socket) do
    {:noreply, assign_notifications(socket, socket.assigns.current_user_id)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="stack-lg">
      <header class="panel">
        <h1 class="section-title">Alertes du vestiaire</h1>
        <div class="post-actions">
          <span class="meta-line">Nouvelles alertes: {@unread_count}</span>
          <.button phx-click="mark_all_read">Tout valider</.button>
        </div>
      </header>

      <article :for={notification <- @notifications} class="panel">
        <div class="meta-line">
          <strong>{notification_label(notification.type)}</strong>
          par @{(notification.origin_user && notification.origin_user.username) || "inconnu"}
        </div>
        <a
          :if={notification_link(notification)}
          href={notification_link(notification)}
          class="text-link"
        >
          Ouvrir
        </a>
        <div class="meta-line">
          Statut: {if notification.read, do: "lu", else: "non lu"}
        </div>
      </article>
    </section>
    """
  end

  defp assign_notifications(socket, user_id) do
    assign(socket,
      current_user_id: user_id,
      notifications: Notifications.list_recent(user_id, 50),
      unread_count: Notifications.unread_count(user_id)
    )
  end

  defp notification_label(:like), do: "Reaction supporter"
  defp notification_label(:comment), do: "Commentaire tactique"
  defp notification_label(:follow), do: "Nouvelle connexion"
  defp notification_label(:shortlist_added), do: "Ajout au pipeline"
  defp notification_label(:message_received), do: "Nouveau message"
  defp notification_label(:system), do: "Systeme"
  defp notification_label("like"), do: "Reaction supporter"
  defp notification_label("comment"), do: "Commentaire tactique"
  defp notification_label("follow"), do: "Nouvelle connexion"
  defp notification_label("shortlist_added"), do: "Ajout au pipeline"
  defp notification_label("message_received"), do: "Nouveau message"
  defp notification_label("system"), do: "Systeme"
  defp notification_label(type) when is_binary(type), do: type
  defp notification_label(_), do: "Notification"

  defp notification_link(notification) do
    cond do
      notification.type in [
        :like,
        :comment,
        :shortlist_added,
        "like",
        "comment",
        "shortlist_added"
      ] &&
          notification.post_id ->
        ~p"/posts/#{notification.post_id}"

      notification.type in [:message_received, "message_received"] && notification.thread_id ->
        ~p"/messages?thread=#{notification.thread_id}"

      notification.type in [:follow, "follow"] ->
        ~p"/reseau"

      true ->
        nil
    end
  end
end
