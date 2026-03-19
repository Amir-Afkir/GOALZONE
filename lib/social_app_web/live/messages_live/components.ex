defmodule SocialAppWeb.MessagesLive.Components do
  @moduledoc false
  use SocialAppWeb, :html

  def render(assigns) do
    ~H"""
    <.goalzone_shell
      current_user={@current_user}
      active_nav={@active_nav}
      right_rail={%{hide: true}}
    >
      <section class="messages-page">
        <section class="messages-page-head panel panel-compact feed-toolbar feed-panel">
          <div class="messages-page-head-copy">
            <p class="messages-page-kicker">Messages</p>
            <h1 class="messages-page-title">Faire avancer le bon thread</h1>
          </div>
        </section>

        <section
          id="messages-workspace"
          class={[
            "messages-workspace panel feed-panel",
            @selected_thread && "messages-workspace-thread-open"
          ]}
          phx-hook="MessagesWorkspace"
        >
          <aside class="messages-rail" aria-label="Threads">
            <div class="messages-rail-head">
              <h2 class="messages-rail-title">Threads directs</h2>

              <form phx-change="update_thread_search" class="messages-search-form" role="search">
                <label class="messages-search-shell" for="messages-search">
                  <span class="right-search-icon">
                    <.search_icon />
                  </span>
                  <input
                    id="messages-search"
                    name={@thread_search_form[:q].name}
                    type="search"
                    value={@thread_search_form[:q].value}
                    class="messages-search-input"
                    placeholder="Chercher un contact ou un thread"
                    autocomplete="off"
                    spellcheck="false"
                    data-messages-search-input
                  />
                </label>
              </form>
            </div>

            <div :if={@contact_matches != []} class="messages-contact-results">
              <p class="messages-section-label">Contacts</p>
              <button
                :for={contact <- @contact_matches}
                type="button"
                class="messages-contact-row"
                phx-click="open_thread_for_contact"
                phx-value-user_id={contact.id}
              >
                <span class="messages-avatar" aria-hidden="true">{contact.avatar}</span>
                <span class="messages-contact-copy">
                  <span class="messages-contact-name">{contact.title}</span>
                  <span class="messages-contact-meta">{contact.meta}</span>
                </span>
              </button>
            </div>

            <div class="messages-thread-section">
              <div :if={@visible_thread_items != []} class="messages-thread-list">
                <button
                  :for={thread <- @visible_thread_items}
                  type="button"
                  phx-click="select_thread"
                  phx-value-thread_id={thread.id}
                  class={[
                    "messages-thread-row",
                    @selected_thread_id == thread.id && "messages-thread-row-active"
                  ]}
                  aria-pressed={@selected_thread_id == thread.id}
                >
                  <span class="messages-avatar" aria-hidden="true">{thread.avatar}</span>
                  <span class="messages-thread-copy">
                    <span class="messages-thread-name">{thread.title}</span>
                    <span class="messages-thread-preview">{thread.preview}</span>
                  </span>
                  <span :if={thread.timestamp} class="messages-thread-time">{thread.timestamp}</span>
                </button>
              </div>

              <article
                :if={@visible_thread_items == [] && @thread_search_form[:q].value not in [nil, ""]}
                class="messages-empty-state"
              >
                <p class="messages-empty-title">Aucun thread ne correspond.</p>
                <p class="messages-empty-copy">Essaie un nom de contact ou un role.</p>
              </article>

              <article
                :if={@threads == [] && @thread_search_form[:q].value in [nil, ""]}
                class="messages-empty-state"
              >
                <p class="messages-empty-title">Aucun thread pour le moment.</p>
                <p class="messages-empty-copy">Utilise la recherche pour ouvrir une conversation.</p>
              </article>
            </div>
          </aside>

          <section class="messages-pane" aria-label="Conversation">
            <div :if={@selected_thread && @selected_peer} class="messages-conversation-shell">
              <header class="messages-thread-head">
                <button
                  type="button"
                  class="ghost-link messages-mobile-back"
                  phx-click="clear_selected_thread"
                >
                  Retour
                </button>

                <div class="messages-thread-identity">
                  <span class="messages-avatar messages-avatar-thread" aria-hidden="true">
                    {@selected_peer.avatar}
                  </span>
                  <div class="messages-thread-identity-copy">
                    <h2 class="messages-thread-title">{@selected_peer.title}</h2>
                    <p class="messages-thread-subtitle">{@selected_peer.meta}</p>
                  </div>
                </div>

                <.link
                  :if={@selected_peer.profile_href}
                  href={@selected_peer.profile_href}
                  class="ghost-link messages-thread-profile-link"
                >
                  Profil
                </.link>
              </header>

              <div class="messages-timeline">
                <article
                  :for={message <- @messages}
                  class={[
                    "messages-row",
                    message.sender_id == @current_user_id && "messages-row-own"
                  ]}
                >
                  <div class="messages-bubble">
                    <p class="messages-bubble-body">{message.body}</p>
                    <time class="messages-bubble-meta">{format_message_timestamp(message.inserted_at)}</time>
                  </div>
                </article>
              </div>

              <form phx-submit="send_message" class="messages-composer">
                <label class="messages-composer-shell" for="messages-body">
                  <textarea
                    id="messages-body"
                    name={@message_form[:body].name}
                    class="messages-composer-input"
                    rows="1"
                    placeholder="Ecrire un message utile..."
                    data-messages-composer
                  ><%= @message_form[:body].value %></textarea>
                </label>

                <button type="submit" class="messages-send-button">
                  Envoyer
                </button>
              </form>
            </div>

            <article :if={!@selected_thread || !@selected_peer} class="messages-placeholder">
              <h2 class="messages-placeholder-title">Choisis un thread</h2>
              <p class="messages-placeholder-copy">
                Ouvre une conversation depuis la liste ou cherche directement un contact.
              </p>
            </article>
          </section>
        </section>
      </section>
    </.goalzone_shell>
    """
  end

  defp format_message_timestamp(nil), do: ""

  defp format_message_timestamp(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%d %b · %H:%M")
  end

  defp format_message_timestamp(%NaiveDateTime{} = datetime) do
    datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> format_message_timestamp()
  end

  defp format_message_timestamp(_), do: ""

  defp search_icon(assigns) do
    ~H"""
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <circle cx="11" cy="11" r="6"></circle>
      <path d="m20 20-4.2-4.2"></path>
    </svg>
    """
  end
end
