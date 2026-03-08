defmodule SocialApp.Notifications do
  @moduledoc """
  Contexte notifications.
  """

  import Ecto.Query, warn: false
  alias SocialApp.Repo
  alias SocialApp.Notifications.Notification

  def list_recent(user_id, limit \\ 20) do
    from(n in Notification,
      where: n.user_id == ^user_id,
      order_by: [desc: n.inserted_at],
      limit: ^limit,
      preload: [:origin_user, :post, :thread]
    )
    |> Repo.all()
  end

  def unread_count(user_id) do
    from(n in Notification,
      where: n.user_id == ^user_id and n.read == false,
      select: count()
    )
    |> Repo.one()
  end

  def create_notification(attrs) do
    case %Notification{}
         |> Notification.changeset(attrs)
         |> Repo.insert() do
      {:ok, notification} = result ->
        Phoenix.PubSub.broadcast(
          SocialApp.PubSub,
          "user:#{notification.user_id}:notifications",
          :notification_created
        )

        result

      error ->
        error
    end
  end

  def mark_all_read(user_id) do
    from(n in Notification, where: n.user_id == ^user_id and n.read == false)
    |> Repo.update_all(set: [read: true])
  end
end
