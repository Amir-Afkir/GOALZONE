defmodule SocialAppWeb.UserLoginLive do
  use SocialAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <.goalzone_shell current_user={@current_user} active_nav={@active_nav}>
      <section class="stack-lg">
        <section class="panel feed-panel matchday-hero">
          <p class="kicker">Access</p>
          <h1 class="section-title">Log in</h1>
          <p class="section-subtitle">Reconnecte-toi pour revenir sur le terrain GoalZone.</p>
        </section>

        <div class="panel feed-panel auth-card">
          <.header>
            Log in to account
            <:subtitle>
              Don't have an account?
              <.link navigate={~p"/users/register"} class="text-link">
                Sign up
              </.link>
              for an account now.
            </:subtitle>
          </.header>

          <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
            <.input field={@form[:email]} type="email" label="Email" required />
            <.input field={@form[:password]} type="password" label="Password" required />

            <:actions>
              <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
              <.link href={~p"/users/reset_password"} class="text-link">
                Forgot your password?
              </.link>
            </:actions>
            <:actions>
              <.button phx-disable-with="Logging in...">Log in</.button>
            </:actions>
          </.simple_form>
        </div>
      </section>
    </.goalzone_shell>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")

    {:ok,
     socket
     |> SocialAppWeb.PageShellComponents.assign_shell(:login, "Connexion")
     |> assign(form: form), temporary_assigns: [form: form]}
  end
end
