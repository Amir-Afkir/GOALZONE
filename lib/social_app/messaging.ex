defmodule SocialApp.Messaging do
  @moduledoc """
  Messagerie directe entre membres.
  """

  import Ecto.Query, warn: false

  alias SocialApp.Repo
  alias SocialApp.Notifications
  alias SocialApp.Messaging.{Message, Thread}

  def list_threads(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 80)

    from(t in Thread,
      where: t.user_a_id == ^user_id or t.user_b_id == ^user_id,
      order_by: [desc: fragment("COALESCE(?, ?)", t.last_message_at, t.inserted_at)],
      preload: [:user_a, :user_b],
      limit: ^limit
    )
    |> Repo.all()
  end

  def count_threads(user_id) do
    from(t in Thread,
      where: t.user_a_id == ^user_id or t.user_b_id == ^user_id,
      select: count()
    )
    |> Repo.one()
  end

  def ensure_direct_thread(from_user_id, to_user_id) when from_user_id == to_user_id do
    {:error, :self_thread}
  end

  def ensure_direct_thread(from_user_id, to_user_id) do
    {user_a_id, user_b_id} = sort_pair(from_user_id, to_user_id)

    case Repo.get_by(Thread, user_a_id: user_a_id, user_b_id: user_b_id) do
      nil ->
        %Thread{}
        |> Thread.changeset(%{
          creator_id: from_user_id,
          user_a_id: user_a_id,
          user_b_id: user_b_id
        })
        |> Repo.insert()

      %Thread{} = thread ->
        {:ok, thread}
    end
  end

  def get_thread_for_user(thread_id, user_id) do
    from(t in Thread,
      where: t.id == ^thread_id and (t.user_a_id == ^user_id or t.user_b_id == ^user_id),
      preload: [:user_a, :user_b]
    )
    |> Repo.one()
  end

  def list_messages(thread_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 200)

    from(m in Message,
      where: m.thread_id == ^thread_id,
      order_by: [asc: m.inserted_at],
      preload: [:sender],
      limit: ^limit
    )
    |> Repo.all()
  end

  def send_message(user_id, thread_id, body) when is_binary(body) do
    trimmed = String.trim(body)

    if trimmed == "" do
      {:error, :empty_message}
    else
      do_send_message(user_id, thread_id, trimmed)
    end
  end

  def send_message(_, _, _), do: {:error, :invalid_message}

  defp do_send_message(user_id, thread_id, body) do
    Repo.transaction(fn ->
      case get_thread_for_user(thread_id, user_id) do
        nil ->
          Repo.rollback(:unauthorized)

        %Thread{} = thread ->
          case %Message{}
               |> Message.changeset(%{thread_id: thread.id, sender_id: user_id, body: body})
               |> Repo.insert() do
            {:ok, message} ->
              _ =
                thread
                |> Thread.changeset(%{
                  last_message_text: String.slice(body, 0, 180),
                  last_message_at: DateTime.utc_now() |> DateTime.truncate(:second)
                })
                |> Repo.update()

              maybe_notify_recipient(thread, user_id)

              Phoenix.PubSub.broadcast(
                SocialApp.PubSub,
                "thread:#{thread.id}",
                {:message_sent, thread.id}
              )

              message

            {:error, changeset} ->
              Repo.rollback(changeset)
          end
      end
    end)
  end

  defp maybe_notify_recipient(%Thread{} = thread, sender_id) do
    recipient_id =
      if thread.user_a_id == sender_id do
        thread.user_b_id
      else
        thread.user_a_id
      end

    Notifications.create_notification(%{
      user_id: recipient_id,
      origin_user_id: sender_id,
      thread_id: thread.id,
      type: :message_received
    })
  end

  defp sort_pair(a, b) when a < b, do: {a, b}
  defp sort_pair(a, b), do: {b, a}
end
