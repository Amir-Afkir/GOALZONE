defmodule SocialAppWeb.UserConfirmationLive do
  use SocialAppWeb, :live_view

  alias SocialApp.Accounts

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <.goalzone_shell current_user={@current_user} active_nav={@active_nav}>
      <section class="stack-lg">
        <section class="panel feed-panel matchday-hero">
          <p class="kicker">Confirm</p>
          <h1 class="section-title">Confirm Account</h1>
          <p class="section-subtitle">Valide l'email puis reconnecte-toi pour entrer sur GoalZone.</p>
        </section>

        <div class="panel feed-panel auth-card">
          <.header>Confirm Account</.header>

          <.simple_form for={@form} id="confirmation_form" phx-submit="confirm_account">
            <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
            <:actions>
              <.button phx-disable-with="Confirming...">Confirm my account</.button>
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

  def mount(%{"token" => token}, _session, socket) do
    form = to_form(%{"token" => token}, as: "user")

    {:ok,
     socket
     |> SocialAppWeb.PageShellComponents.assign_shell(:confirm, "Confirmation compte")
     |> assign(form: form), temporary_assigns: [form: nil]}
  end

  # Do not log in the user after confirmation to avoid a
  # leaked token giving the user access to the account.
  def handle_event("confirm_account", %{"user" => %{"token" => token}}, socket) do
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "User confirmed successfully.")
         |> redirect(to: ~p"/users/log_in")}

      :error ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case socket.assigns do
          %{current_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            {:noreply, redirect(socket, to: ~p"/")}

          %{} ->
            {:noreply,
             socket
             |> put_flash(:error, "User confirmation link is invalid or it has expired.")
             |> redirect(to: ~p"/users/log_in")}
        end
    end
  end
end
