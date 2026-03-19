defmodule SocialAppWeb.MessagesLive do
  use SocialAppWeb, :live_view

  alias SocialApp.{Accounts, Labels, Messaging}
  alias SocialAppWeb.MessagesLive.Components

  @thread_limit 80
  @directory_limit 120
  @contact_match_limit 6

  @impl true
  def mount(_params, _session, socket) do
    current_user_id = socket.assigns.current_user.id

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SocialApp.PubSub, "user:#{current_user_id}")
    end

    {:ok,
     socket
     |> SocialAppWeb.PageShellComponents.assign_shell(:messages, "Messages")
     |> assign(:mini_coach, nil)
     |> assign(:current_user_id, current_user_id)
     |> assign(:thread_query, "")
     |> assign(:thread_search_form, to_form(%{"q" => ""}, as: :directory))
     |> assign(:message_form, to_form(%{"body" => ""}, as: :message))
     |> assign(:subscribed_thread_id, nil)
     |> assign(:selected_thread_id, nil)
     |> assign(:threads, [])
     |> assign(:directory, [])
     |> assign(:visible_thread_items, [])
     |> assign(:contact_matches, [])
     |> assign(:selected_thread, nil)
     |> assign(:selected_peer, nil)
     |> assign(:messages, [])
     |> load_directory()
     |> load_threads()}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      cond do
        params["thread"] ->
          activate_thread(socket, parse_int(params["thread"]))

        params["to"] ->
          maybe_bootstrap_thread_from_recipient(socket, parse_int(params["to"]))

        true ->
          activate_thread(socket, nil)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_thread_search", %{"directory" => %{"q" => query}}, socket) do
    {:noreply, socket |> assign(:thread_query, normalize_query(query)) |> refresh_messages_view()}
  end

  @impl true
  def handle_event("open_thread_for_contact", %{"user_id" => user_id}, socket) do
    recipient_id = parse_int(user_id)

    cond do
      is_nil(recipient_id) ->
        {:noreply, invalid_action(socket)}

      recipient_id == socket.assigns.current_user_id ->
        {:noreply, put_flash(socket, :error, "Conversation avec soi-meme non supportee.")}

      true ->
        case Messaging.ensure_direct_thread(socket.assigns.current_user_id, recipient_id) do
          {:ok, thread} ->
            {:noreply,
             socket
             |> load_threads()
             |> assign(:thread_query, "")
             |> refresh_messages_view()
             |> push_patch(to: ~p"/messages?thread=#{thread.id}")}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "Impossible d'ouvrir ce thread.")}
        end
    end
  end

  @impl true
  def handle_event("select_thread", %{"thread_id" => thread_id}, socket) do
    case parse_int(thread_id) do
      nil ->
        {:noreply, invalid_action(socket)}

      selected_thread_id ->
        {:noreply, push_patch(socket, to: ~p"/messages?thread=#{selected_thread_id}")}
    end
  end

  @impl true
  def handle_event("clear_selected_thread", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/messages")}
  end

  @impl true
  def handle_event("messages_shortcut", %{"action" => action}, socket) do
    {:noreply, run_messages_shortcut(socket, action)}
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
             |> load_threads()
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
    socket = load_threads(socket)

    if socket.assigns.selected_thread_id == thread_id do
      {:noreply, load_messages(socket)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:new_post, _post}, socket), do: {:noreply, socket}

  @impl true
  def render(assigns), do: Components.render(assigns)

  defp load_threads(socket) do
    socket
    |> assign(
      :threads,
      Messaging.list_threads(socket.assigns.current_user_id, limit: @thread_limit)
    )
    |> refresh_messages_view()
  end

  defp load_directory(socket) do
    socket
    |> assign(
      :directory,
      Accounts.list_directory(%{},
        exclude_user_id: socket.assigns.current_user_id,
        limit: @directory_limit
      )
    )
    |> refresh_messages_view()
  end

  defp activate_thread(socket, thread_id) do
    socket
    |> assign(:selected_thread_id, thread_id)
    |> refresh_messages_view()
    |> load_messages()
  end

  defp load_messages(socket) do
    case socket.assigns.selected_thread_id do
      nil ->
        socket
        |> clear_thread_subscription()
        |> assign(:messages, [])

      thread_id ->
        socket
        |> ensure_thread_subscription(thread_id)
        |> assign(:messages, Messaging.list_messages(thread_id, limit: 100))
    end
  end

  defp refresh_messages_view(socket) do
    current_user_id = socket.assigns.current_user_id
    query = socket.assigns.thread_query
    threads = socket.assigns.threads

    selected_thread =
      Enum.find(threads, &(&1.id == socket.assigns.selected_thread_id))

    selected_peer =
      case selected_thread do
        nil -> nil
        thread -> peer_user(thread, current_user_id)
      end

    thread_items =
      threads
      |> Enum.map(&thread_item(&1, current_user_id))
      |> filter_thread_items(query)

    assign(socket,
      selected_thread_id: selected_thread && selected_thread.id,
      selected_thread: selected_thread,
      selected_peer: selected_peer && user_card(selected_peer),
      visible_thread_items: thread_items,
      contact_matches: filter_contact_matches(socket.assigns.directory, query),
      thread_search_form: to_form(%{"q" => query}, as: :directory)
    )
  end

  defp maybe_bootstrap_thread_from_recipient(socket, nil), do: activate_thread(socket, nil)

  defp maybe_bootstrap_thread_from_recipient(socket, recipient_id) do
    if recipient_id == socket.assigns.current_user_id do
      activate_thread(socket, nil)
    else
      case Messaging.ensure_direct_thread(socket.assigns.current_user_id, recipient_id) do
        {:ok, thread} ->
          socket
          |> load_threads()
          |> push_patch(to: ~p"/messages?thread=#{thread.id}")

        _ ->
          socket
      end
    end
  end

  defp ensure_thread_subscription(socket, thread_id) do
    current_subscription = socket.assigns.subscribed_thread_id

    cond do
      not connected?(socket) ->
        assign(socket, :subscribed_thread_id, thread_id)

      current_subscription == thread_id ->
        socket

      true ->
        if current_subscription do
          Phoenix.PubSub.unsubscribe(SocialApp.PubSub, "thread:#{current_subscription}")
        end

        Phoenix.PubSub.subscribe(SocialApp.PubSub, "thread:#{thread_id}")
        assign(socket, :subscribed_thread_id, thread_id)
    end
  end

  defp clear_thread_subscription(socket) do
    if connected?(socket) and socket.assigns.subscribed_thread_id do
      Phoenix.PubSub.unsubscribe(
        SocialApp.PubSub,
        "thread:#{socket.assigns.subscribed_thread_id}"
      )
    end

    assign(socket, :subscribed_thread_id, nil)
  end

  defp run_messages_shortcut(socket, "next_thread"), do: push_adjacent_thread(socket, 1)
  defp run_messages_shortcut(socket, "previous_thread"), do: push_adjacent_thread(socket, -1)
  defp run_messages_shortcut(socket, _unknown_action), do: socket

  defp push_adjacent_thread(socket, direction) do
    thread_ids = Enum.map(socket.assigns.visible_thread_items, & &1.id)

    next_id =
      case {thread_ids, socket.assigns.selected_thread_id} do
        {[], _current} ->
          nil

        {ids, nil} when direction > 0 ->
          List.first(ids)

        {ids, nil} ->
          List.last(ids)

        {ids, current} ->
          current_index = Enum.find_index(ids, &(&1 == current))

          case current_index do
            nil -> List.first(ids)
            index -> Enum.at(ids, index + direction)
          end
      end

    if next_id do
      push_patch(socket, to: ~p"/messages?thread=#{next_id}")
    else
      socket
    end
  end

  defp thread_item(thread, current_user_id) do
    peer =
      thread
      |> peer_user(current_user_id)
      |> user_card()

    %{
      id: thread.id,
      title: peer.title,
      meta: peer.meta,
      avatar: peer.avatar,
      preview: thread_preview(thread.last_message_text),
      timestamp: format_timestamp(thread.last_message_at || thread.inserted_at)
    }
  end

  defp peer_user(thread, current_user_id) do
    cond do
      thread.user_a_id == current_user_id -> thread.user_b
      thread.user_b_id == current_user_id -> thread.user_a
      true -> nil
    end
  end

  defp user_card(nil) do
    %{
      id: nil,
      title: "Thread inconnu",
      meta: "Profil indisponible",
      avatar: "?",
      profile_href: nil
    }
  end

  defp user_card(user) do
    %{
      id: user.id,
      title: "@#{user.username}",
      meta: user_meta(user),
      avatar: avatar_initial(user.username),
      profile_href: ~p"/profile/#{user.username}"
    }
  end

  defp filter_thread_items(items, ""), do: items

  defp filter_thread_items(items, query) do
    Enum.filter(items, fn item ->
      contains_query?([item.title, item.meta, item.preview], query)
    end)
  end

  defp filter_contact_matches(_directory, ""), do: []

  defp filter_contact_matches(directory, query) do
    directory
    |> Enum.map(&user_card/1)
    |> Enum.filter(fn item -> contains_query?([item.title, item.meta], query) end)
    |> Enum.take(@contact_match_limit)
  end

  defp contains_query?(values, query) do
    query = String.downcase(query)

    Enum.any?(values, fn value ->
      value
      |> to_string()
      |> String.downcase()
      |> String.contains?(query)
    end)
  end

  defp thread_preview(nil), do: "Aucun message"
  defp thread_preview(""), do: "Aucun message"

  defp thread_preview(value) do
    value
    |> String.trim()
    |> case do
      "" -> "Aucun message"
      trimmed -> trimmed
    end
  end

  defp user_meta(user) do
    [
      Labels.role_label(user.role),
      Labels.level_label(user.level),
      present_region(user.region)
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" · ")
  end

  defp format_timestamp(nil), do: nil

  defp format_timestamp(%DateTime{} = datetime) do
    now = DateTime.utc_now()

    if Date.compare(DateTime.to_date(datetime), DateTime.to_date(now)) == :eq do
      Calendar.strftime(datetime, "%H:%M")
    else
      Calendar.strftime(datetime, "%d %b")
    end
  end

  defp format_timestamp(%NaiveDateTime{} = datetime) do
    format_timestamp(DateTime.from_naive!(datetime, "Etc/UTC"))
  end

  defp format_timestamp(_), do: nil

  defp present_region(nil), do: nil
  defp present_region(""), do: nil
  defp present_region(value), do: value

  defp avatar_initial(nil), do: "?"

  defp avatar_initial(username) when is_binary(username) do
    username
    |> String.trim()
    |> String.first()
    |> case do
      nil -> "?"
      first -> String.upcase(first)
    end
  end

  defp avatar_initial(_), do: "?"

  defp invalid_action(socket), do: put_flash(socket, :error, "Action invalide.")

  defp normalize_query(nil), do: ""
  defp normalize_query(query), do: String.trim(query)

  defp parse_int(nil), do: nil
  defp parse_int(""), do: nil

  defp parse_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} when parsed > 0 -> parsed
      _ -> nil
    end
  end

  defp parse_int(value) when is_integer(value), do: value
  defp parse_int(_), do: nil
end
