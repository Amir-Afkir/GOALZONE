defmodule SocialAppWeb.UserForgotPasswordLive do
  use SocialAppWeb, :live_view

  alias SocialApp.Accounts

  def render(assigns) do
    ~H"""
    <.goalzone_shell current_user={@current_user} active_nav={@active_nav}>
      <section class="stack-lg">
        <section class="panel feed-panel matchday-hero">
          <p class="kicker">Recovery</p>
          <h1 class="section-title">Forgot your password?</h1>
          <p class="section-subtitle">Recupere l'acces proprement puis reconnecte-toi.</p>
        </section>

        <div class="panel feed-panel auth-card">
          <.header>
            Forgot your password?
            <:subtitle>We'll send a password reset link to your inbox</:subtitle>
          </.header>

          <.simple_form for={@form} id="reset_password_form" phx-submit="send_email">
            <.input field={@form[:email]} type="email" placeholder="Email" required />
            <:actions>
              <.button phx-disable-with="Sending...">
                Send password reset instructions
              </.button>
            </:actions>
          </.simple_form>
          <p class="info-link-row">
            <.link href={~p"/users/register"} class="text-link">Register</.link>
            | <.link href={~p"/users/log_in"} class="text-link">Log in</.link>
          </p>
        </div>
      </section>
    </.goalzone_shell>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> SocialAppWeb.PageShellComponents.assign_shell(:recovery, "Recuperation acces")
     |> assign(form: to_form(%{}, as: "user"))}
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset_password/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
