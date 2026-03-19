defmodule SocialAppWeb.UserConfirmationInstructionsLive do
  use SocialAppWeb, :live_view

  alias SocialApp.Accounts

  def render(assigns) do
    ~H"""
    <.goalzone_shell current_user={@current_user} active_nav={@active_nav}>
      <section class="stack-lg">
        <section class="panel feed-panel matchday-hero">
          <p class="kicker">Confirm</p>
          <h1 class="section-title">No confirmation instructions received?</h1>
          <p class="section-subtitle">Renvoie le lien de confirmation pour activer le compte.</p>
        </section>

        <div class="panel feed-panel auth-card">
          <.header>
            No confirmation instructions received?
            <:subtitle>We'll send a new confirmation link to your inbox</:subtitle>
          </.header>

          <.simple_form for={@form} id="resend_confirmation_form" phx-submit="send_instructions">
            <.input field={@form[:email]} type="email" placeholder="Email" required />
            <:actions>
              <.button phx-disable-with="Sending...">
                Resend confirmation instructions
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
     |> SocialAppWeb.PageShellComponents.assign_shell(:confirm, "Instructions confirmation")
     |> assign(form: to_form(%{}, as: "user"))}
  end

  def handle_event("send_instructions", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/users/confirm/#{&1}")
      )
    end

    info =
      "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/users/log_in")}
  end
end
