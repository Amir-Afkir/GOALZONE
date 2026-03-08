defmodule SocialAppWeb.PostLive.Show do
  use SocialAppWeb, :live_view

  alias SocialApp.{Labels, Posts, Recruitment}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user_id = socket.assigns.current_user.id
    post_id = String.to_integer(id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SocialApp.PubSub, "post:#{post_id}")
      Phoenix.PubSub.subscribe(SocialApp.PubSub, "user:#{user_id}")

      SocialAppWeb.Presence.track(self(), "user:#{user_id}", user_id, %{
        online_at: DateTime.utc_now()
      })
    end

    {:ok,
     assign(socket,
       page_context: "Debrief post",
       mini_coach: %{
         page: "post-#{post_id}",
         where: "Debrief d'une action",
         goal: "Analyser l'action puis contribuer utilement",
         next: "Commente ou avance l'etape pipeline.",
         cta_to: ~p"/",
         cta_label: "Retour terrain"
       },
       current_user_id: user_id,
       post: Posts.get_post!(post_id),
       comments: Posts.list_comments(post_id, 100),
       comment_form: to_form(%{"content" => ""}, as: :comment),
       shortlist_entry: Recruitment.get_entry(user_id, post_id)
     )}
  end

  @impl true
  def handle_event("like", _params, socket) do
    _ = Posts.like_post(socket.assigns.current_user_id, socket.assigns.post.id)
    {:noreply, assign(socket, post: Posts.get_post!(socket.assigns.post.id))}
  end

  @impl true
  def handle_event("toggle_shortlist", _params, socket) do
    _ = Recruitment.toggle_shortlist(socket.assigns.current_user_id, socket.assigns.post.id)

    {:noreply,
     assign(
       socket,
       :shortlist_entry,
       Recruitment.get_entry(socket.assigns.current_user_id, socket.assigns.post.id)
     )}
  end

  @impl true
  def handle_event("advance_stage", _params, socket) do
    _ = Recruitment.advance_stage(socket.assigns.current_user_id, socket.assigns.post.id)

    {:noreply,
     assign(
       socket,
       :shortlist_entry,
       Recruitment.get_entry(socket.assigns.current_user_id, socket.assigns.post.id)
     )}
  end

  @impl true
  def handle_event("add_comment", %{"comment" => %{"content" => content}}, socket) do
    case Posts.add_comment(socket.assigns.current_user_id, socket.assigns.post.id, %{
           content: content
         }) do
      {:ok, _comment} ->
        {:noreply, assign(socket, comment_form: to_form(%{"content" => ""}, as: :comment))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Commentaire invalide")}
    end
  end

  @impl true
  def handle_info({:post_liked, post_id, _likes_count}, socket) do
    if socket.assigns.post.id == post_id do
      {:noreply, assign(socket, post: Posts.get_post!(post_id))}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:comment_created, post_id, _comment_id}, socket) do
    if socket.assigns.post.id == post_id do
      {:noreply, assign(socket, comments: Posts.list_comments(post_id, 100))}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="stack-lg">
      <header class="panel matchday-hero">
        <p class="kicker">Zone tactique</p>
        <h1 class="section-title">Debrief du post</h1>
      </header>

      <article class="panel">
        <div class="meta-line">@{(@post.user && @post.user.username) || "inconnu"}</div>
        <div class="status-row">
          <span class="status-pill status-pill-muted">{post_format_label(@post.post_format)}</span>
          <span class="status-pill status-pill-muted">{intention_label(@post.intention)}</span>
          <span
            :if={@post.source_type && @post.source_type != :unknown}
            class="status-pill status-pill-muted"
          >
            Source: {source_type_label(@post.source_type)}
          </span>
          <a
            :if={@post.media_url}
            href={@post.media_url}
            class="text-link"
            target="_blank"
            rel="noopener noreferrer"
          >
            Ouvrir media
          </a>
        </div>
        <p class="post-content">{@post.content}</p>
        <p :if={structured_post?(@post)} class="meta-line">
          {@post.competition || "Match"} {if @post.opponent, do: "· vs #{@post.opponent}", else: ""}
          {if @post.match_minute, do: "· #{@post.match_minute}'", else: ""}
        </p>
        <.button class="btn-like" phx-click="like">Supporters: {@post.likes_count}</.button>
        <div class="post-actions">
          <button class="ghost-link" phx-click="toggle_shortlist">
            {if @shortlist_entry, do: "Retirer pipeline", else: "Ajouter pipeline"}
          </button>
          <button :if={@shortlist_entry} class="ghost-link" phx-click="advance_stage">
            Etape: {Labels.stage_label(@shortlist_entry.stage)}
          </button>
        </div>
      </article>

      <form phx-submit="add_comment" class="panel stack-md">
        <label for="comment_content" class="field-label">Ton analyse</label>
        <textarea
          id="comment_content"
          name={@comment_form[:content].name}
          rows="3"
          class="comment-textarea"
          placeholder="Ecris ton debrief de cette action..."
        ><%= @comment_form[:content].value %></textarea>
        <.button type="submit">Publier l'analyse</.button>
      </form>

      <section class="stack-md">
        <h2 class="section-title">Commentaires du vestiaire</h2>
        <article :for={comment <- @comments} class="panel">
          <div class="meta-line">@{(comment.user && comment.user.username) || "inconnu"}</div>
          <p class="post-content">{comment.content}</p>
        </article>
      </section>
    </section>
    """
  end

  defp structured_post?(post), do: post.intention in [:showcase, :recruitment]

  defp post_format_label(:post), do: "Post"
  defp post_format_label(:photo), do: "Photo"
  defp post_format_label(:video), do: "Video"
  defp post_format_label(:article), do: "Article"
  defp post_format_label(_), do: "Post"

  defp intention_label(:entertainment), do: "Divertissement"
  defp intention_label(:showcase), do: "Performance"
  defp intention_label(:recruitment), do: "Recrutement"
  defp intention_label(_), do: "Divertissement"

  defp source_type_label(:highlight_video), do: "Highlight video"
  defp source_type_label(:full_match_video), do: "Match complet"
  defp source_type_label(:live_observation), do: "Observation live"
  defp source_type_label(:stat_report), do: "Rapport stats"
  defp source_type_label(_), do: "Non precise"
end
