defmodule SocialAppWeb.ProfileLive.Show do
  use SocialAppWeb, :live_view

  alias SocialApp.{Accounts, Labels, Messaging, Notifications, Posts, Recruitment}

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    {:ok,
     socket
     |> SocialAppWeb.PageShellComponents.assign_shell(:profil, "Profil")
     |> assign(:mini_coach, %{
       page: "profil",
       where: "Profil public",
       goal: "Comprendre vite la valeur du profil",
       next: "Choisis une action: contacter, suivre ou revenir au reseau.",
       cta_to: ~p"/reseau",
       cta_label: "Retour reseau"
     })
     |> assign(:current_user_id, socket.assigns.current_user.id)
     |> assign(:username, username)
     |> load_profile()}
  end

  @impl true
  def handle_event("toggle_follow", _params, socket) do
    with %{profile: profile} when not is_nil(profile) <- socket.assigns do
      current_user_id = socket.assigns.current_user_id

      if socket.assigns.can_moderate do
        if socket.assigns.is_following do
          _ = Accounts.unfollow_user(current_user_id, profile.id)
        else
          _ = Accounts.follow_user(current_user_id, profile.id)
        end
      end
    end

    {:noreply, load_profile(socket)}
  end

  @impl true
  def handle_event("toggle_block", _params, socket) do
    with %{profile: profile} when not is_nil(profile) <- socket.assigns,
         true <- socket.assigns.can_moderate do
      if socket.assigns.is_blocked do
        _ = Accounts.unblock_user(socket.assigns.current_user_id, profile.id)
      else
        _ = Accounts.block_user(socket.assigns.current_user_id, profile.id)
      end
    end

    {:noreply, load_profile(socket)}
  end

  @impl true
  def handle_event("report", _params, socket) do
    with %{profile: profile} when not is_nil(profile) <- socket.assigns do
      _ =
        Accounts.create_report(socket.assigns.current_user_id, %{
          target_user_id: profile.id,
          reason: "profile_report",
          context: "profile:#{profile.username}"
        })
    end

    {:noreply, put_flash(socket, :info, "Signalement envoye.")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.goalzone_shell current_user={@current_user} active_nav={@active_nav}>
      <section :if={@not_found} class="panel feed-panel">
        <h1 class="section-title">Profil introuvable</h1>
        <p class="section-subtitle">Aucun profil ne correspond a ce handle.</p>
      </section>

      <section :if={!@not_found} class="stack-lg">
        <section class="panel feed-panel matchday-hero">
          <p class="kicker">Player Card</p>
          <h1 class="section-title">@{@profile.username}</h1>
          <p class="section-subtitle">
            {fallback(@profile.headline, "Profil en cours de qualification")}
          </p>

          <div class="status-row">
            <span class="status-pill">{Labels.role_label(@profile.role)}</span>
            <span class="status-pill">{Labels.level_label(@profile.level)}</span>
            <span class="status-pill">{Labels.availability_label(@profile.availability)}</span>
            <span :if={@profile.region not in [nil, ""]} class="status-pill status-pill-muted">
              {@profile.region}
            </span>
          </div>

          <p :if={@profile.bio not in [nil, ""]} class="post-content">{@profile.bio}</p>

          <div class="post-actions">
            <a href={~p"/messages?to=#{@profile.id}"} class="ghost-link">Contacter</a>
            <button :if={@can_moderate} class="ghost-link" phx-click="toggle_follow">
              {if @is_following, do: "Retirer du reseau", else: "Ajouter au reseau"}
            </button>
            <button :if={@can_moderate} class="ghost-link" phx-click="toggle_block">
              {if @is_blocked, do: "Debloquer", else: "Bloquer"}
            </button>
            <button :if={@can_moderate} class="ghost-link" phx-click="report">Signaler</button>
          </div>
        </section>

        <section :if={@show_dashboard} class="panel feed-panel stack-md">
          <p class="kicker">Pilotage</p>
          <h2 class="section-title">Mon dashboard</h2>
          <p class="section-subtitle">Vue rapide de ton activite et de ton pipeline recrutement.</p>

          <div class="dashboard-grid">
            <article class="metric-card">
              <p class="label-caps">Connexions</p>
              <p class="metric-value">{@signal_follows}</p>
            </article>
            <article class="metric-card">
              <p class="label-caps">Conversations</p>
              <p class="metric-value">{@signal_threads}</p>
            </article>
            <article class="metric-card">
              <p class="label-caps">Alertes</p>
              <p class="metric-value">{@signal_alerts}</p>
            </article>
            <article class="metric-card">
              <p class="label-caps">Pipeline</p>
              <p class="metric-value">{@signal_shortlists}</p>
            </article>
          </div>

          <div class="pipeline-row">
            <span :for={stage <- Labels.stage_values()} class="status-pill status-pill-muted">
              {Labels.stage_label(stage)}: {Map.get(@stage_counts, stage, 0)}
            </span>
          </div>
        </section>

        <section class="panel feed-panel stack-md">
          <div class="post-actions">
            <h2 class="section-title">Contenus publies</h2>
            <span class="meta-line">{length(@posts)} posts</span>
          </div>

          <article :for={post <- @posts} class="panel feed-panel panel-inner">
            <p class="post-content">{post.content}</p>
            <p class="meta-line">
              {fallback(post.competition, "Match")} {if post.match_minute,
                do: "· #{post.match_minute}'",
                else: ""}
            </p>
          </article>

          <p :if={@posts == []} class="meta-line">Aucun post pour ce profil.</p>
        </section>
      </section>
    </.goalzone_shell>
    """
  end

  defp load_profile(socket) do
    viewer_id = socket.assigns.current_user_id
    username = socket.assigns.username
    profile = Accounts.get_user_by_username(username)

    if profile do
      followed_ids = Accounts.list_followed_ids(viewer_id)
      blocked_ids = Accounts.list_blocked_ids(viewer_id)

      assign(socket,
        profile: profile,
        posts: Posts.list_posts_by_user(profile.id, 8),
        show_dashboard: profile.id == viewer_id,
        signal_follows: length(Accounts.list_following(viewer_id)),
        signal_threads: Messaging.count_threads(viewer_id),
        signal_alerts: Notifications.unread_count(viewer_id),
        signal_shortlists: Recruitment.count_entries(viewer_id),
        stage_counts: Recruitment.stage_counts(viewer_id),
        is_following: profile.id in followed_ids,
        is_blocked: profile.id in blocked_ids,
        can_moderate: profile.id != viewer_id,
        not_found: false,
        page_context: "Profil de @#{profile.username}",
        mini_coach: %{
          page: "profil-#{profile.username}",
          where: "Profil de @#{profile.username}",
          goal: "Qualifier ce profil en moins de 20 secondes",
          next: "Lis le resume puis choisis une action claire.",
          cta_to: ~p"/messages?to=#{profile.id}",
          cta_label: "Contacter"
        }
      )
    else
      assign(socket,
        profile: nil,
        posts: [],
        show_dashboard: false,
        signal_follows: 0,
        signal_threads: 0,
        signal_alerts: 0,
        signal_shortlists: 0,
        stage_counts: %{},
        is_following: false,
        is_blocked: false,
        can_moderate: false,
        not_found: true
      )
    end
  end

  defp fallback(nil, backup), do: backup
  defp fallback("", backup), do: backup
  defp fallback(value, _backup), do: value
end
