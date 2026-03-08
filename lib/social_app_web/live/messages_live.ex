defmodule SocialAppWeb.MessagesLive do
  use SocialAppWeb, :live_view

  alias SocialApp.{Accounts, Messaging}

  @impl true
  def mount(_params, _session, socket) do
    current_user_id = socket.assigns.current_user.id

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SocialApp.PubSub, "user:#{current_user_id}")
    end

    {:ok,
     socket
     |> assign(:page_context, "Messages")
     |> assign(:mini_coach, %{
       page: "messages",
       where: "Messages (threads directs)",
       goal: "Avancer les discussions vers une decision claire",
       next: "Choisis un thread et envoie un message actionnable.",
       cta_to: ~p"/talents",
       cta_label: "Trouver un contact"
     })
     |> assign(:current_user_id, current_user_id)
     |> assign(:thread_form, to_form(%{"recipient_id" => ""}, as: :thread))
     |> assign(:message_form, to_form(%{"body" => ""}, as: :message))
     |> load_threads_and_directory()
     |> select_default_thread()}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      cond do
        params["thread"] ->
          socket
          |> assign(:selected_thread_id, parse_int(params["thread"]))
          |> load_messages()

        params["to"] ->
          maybe_bootstrap_thread_from_recipient(socket, parse_int(params["to"]))

        true ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("create_thread", %{"thread" => %{"recipient_id" => recipient_id}}, socket) do
    recipient_id = parse_int(recipient_id)

    cond do
      is_nil(recipient_id) ->
        {:noreply, put_flash(socket, :error, "Selectionne un contact.")}

      recipient_id == socket.assigns.current_user_id ->
        {:noreply, put_flash(socket, :error, "Conversation avec soi-meme non supportee.")}

      true ->
        case Messaging.ensure_direct_thread(socket.assigns.current_user_id, recipient_id) do
          {:ok, thread} ->
            {:noreply,
             socket
             |> clear_flash()
             |> load_threads_and_directory()
             |> assign(:selected_thread_id, thread.id)
             |> assign(:thread_form, to_form(%{"recipient_id" => ""}, as: :thread))
             |> load_messages()}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "Impossible de creer le thread.")}
        end
    end
  end

  @impl true
  def handle_event("select_thread", %{"thread_id" => thread_id}, socket) do
    {:noreply,
     socket
     |> assign(:selected_thread_id, parse_int(thread_id))
     |> load_messages()}
  end

  @impl true
  def handle_event("send_message", %{"message" => %{"body" => body}}, socket) do
    case socket.assigns.selected_thread_id do
      nil ->
        {:noreply, put_flash(socket, :error, "Selectionne un thread avant d'envoyer.")}

      thread_id ->
        case Messaging.send_message(socket.assigns.current_user_id, thread_id, body) do
          {:ok, _message} ->
            {:noreply,
             socket
             |> assign(:message_form, to_form(%{"body" => ""}, as: :message))
             |> load_threads_and_directory()
             |> load_messages()}

          {:error, :empty_message} ->
            {:noreply, socket}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "Message non envoye. Reessaie.")}
        end
    end
  end

  @impl true
  def handle_info({:message_sent, thread_id}, socket) do
    socket = load_threads_and_directory(socket)

    if socket.assigns.selected_thread_id == thread_id do
      {:noreply, load_messages(socket)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:new_post, _post}, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <section class="stack-lg">
      <header class="panel matchday-hero">
        <p class="kicker">Direct Messages</p>
        <h1 class="section-title">Messagerie recrutement</h1>
        <p class="section-subtitle">
          Cree un thread direct avec un club, un scout, un agent ou un joueur.
        </p>
      </header>

      <section class="panel stack-md">
        <form phx-submit="create_thread" class="post-actions">
          <select name={@thread_form[:recipient_id].name} class="field-input">
            <option value="">Choisir un contact</option>
            <option :for={user <- @directory} value={user.id}>{user.username}</option>
          </select>
          <.button type="submit">Creer thread</.button>
        </form>

        <div class="thread-list">
          <button
            :for={thread <- @threads}
            type="button"
            phx-click="select_thread"
            phx-value-thread_id={thread.id}
            class={["thread-item", @selected_thread_id == thread.id && "thread-item-active"]}
          >
            <span class="thread-title">{thread_title(thread, @current_user_id)}</span>
            <span class="thread-last">{thread.last_message_text}</span>
          </button>
        </div>

        <p :if={@threads == []} class="meta-line">
          Aucun thread. Cree ta premiere conversation depuis le select ci-dessus.
        </p>
      </section>

      <section class="panel stack-md">
        <h2 class="section-title">Conversation</h2>

        <div class="messages-list">
          <article
            :for={message <- @messages}
            class={["message-bubble", message.sender_id == @current_user_id && "message-own"]}
          >
            <p class="meta-line">@{message.sender && message.sender.username}</p>
            <p class="post-content">{message.body}</p>
          </article>
        </div>

        <form phx-submit="send_message" class="post-actions">
          <input
            type="text"
            name={@message_form[:body].name}
            value={@message_form[:body].value}
            class="field-input"
            placeholder="Ecrire un message..."
          />
          <.button type="submit">Envoyer</.button>
        </form>
      </section>
    </section>
    """
  end

  defp load_threads_and_directory(socket) do
    current_user_id = socket.assigns.current_user_id

    assign(socket,
      threads: Messaging.list_threads(current_user_id, limit: 80),
      directory: Accounts.list_directory(%{}, exclude_user_id: current_user_id, limit: 200)
    )
  end

  defp select_default_thread(socket) do
    selected = socket.assigns.threads |> List.first() |> then(&(&1 && &1.id))
    socket |> assign(:selected_thread_id, selected) |> load_messages()
  end

  defp load_messages(socket) do
    case socket.assigns.selected_thread_id do
      nil ->
        assign(socket, :messages, [])

      thread_id ->
        if connected?(socket) do
          Phoenix.PubSub.subscribe(SocialApp.PubSub, "thread:#{thread_id}")
        end

        assign(socket, :messages, Messaging.list_messages(thread_id, limit: 200))
    end
  end

  defp thread_title(thread, current_user_id) do
    cond do
      thread.user_a_id == current_user_id and thread.user_b -> "@#{thread.user_b.username}"
      thread.user_b_id == current_user_id and thread.user_a -> "@#{thread.user_a.username}"
      true -> "Thread ##{thread.id}"
    end
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

  defp maybe_bootstrap_thread_from_recipient(socket, nil), do: socket

  defp maybe_bootstrap_thread_from_recipient(socket, recipient_id) do
    if recipient_id == socket.assigns.current_user_id do
      socket
    else
      case Messaging.ensure_direct_thread(socket.assigns.current_user_id, recipient_id) do
        {:ok, thread} ->
          socket
          |> load_threads_and_directory()
          |> assign(:selected_thread_id, thread.id)
          |> load_messages()

        _ ->
          socket
      end
    end
  end
end
