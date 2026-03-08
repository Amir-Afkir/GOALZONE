defmodule SocialAppWeb.CoreComponents do
  use Phoenix.Component

  attr :class, :string, default: nil
  slot :inner_block, required: true
  slot :subtitle

  def header(assigns) do
    ~H"""
    <header class={["section-header", @class]}>
      <h1 class="section-title">{render_slot(@inner_block)}</h1>
      <p :if={@subtitle != []} class="section-subtitle">{render_slot(@subtitle)}</p>
    </header>
    """
  end

  attr :for, :any, required: true
  attr :as, :any, default: nil
  attr :action, :string, default: nil
  attr :method, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  slot :actions

  def simple_form(assigns) do
    ~H"""
    <.form
      :let={f}
      for={@for}
      as={@as}
      action={@action}
      method={@method}
      class={["form-stack", @class]}
      {@rest}
    >
      <div class="form-fields">{render_slot(@inner_block, f)}</div>
      <div :if={@actions != []} class="form-actions">
        {render_slot(@actions, f)}
      </div>
    </.form>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :type, :string, default: "text"
  attr :label, :string, default: nil
  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :errors, :list, default: []
  attr :rest, :global, include: ~w(
      accept
      autocomplete
      checked
      disabled
      max
      maxlength
      min
      minlength
      multiple
      name
      pattern
      placeholder
      readonly
      required
      step
      value
    )

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns =
      assigns
      |> assign(:id, assigns.id || assigns.field.id)
      |> assign(:name, assigns.name || assigns.field.name)
      |> assign(:value, if(is_nil(assigns.value), do: field.value, else: assigns.value))
      |> assign(:errors, if(assigns.errors == [], do: field.errors, else: assigns.errors))

    ~H"""
    <div class="field-wrap">
      <label :if={@label && @type != "checkbox"} for={@id} class="field-label">
        {@label}
      </label>

      <%= if @type == "checkbox" do %>
        <div class="field-check">
          <input type="hidden" name={@name} value="false" />
          <input
            id={@id}
            name={@name}
            type="checkbox"
            value="true"
            checked={Phoenix.HTML.Form.normalize_value("checkbox", @value)}
            class="field-check-input"
            {@rest}
          />
          <span :if={@label} class="field-check-label">{@label}</span>
        </div>
      <% else %>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class="field-input"
          {@rest}
        />
      <% end %>

      <p :for={msg <- Enum.map(@errors, &translate_error/1)} class="field-error">
        {msg}
      </p>
    </div>
    """
  end

  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="error-box">
      {render_slot(@inner_block)}
    </p>
    """
  end

  attr :rest, :global, include: ~w(href navigate patch method name value disabled type)
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button class={["btn", @class]} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :flash, :map, default: %{}

  def flash_group(assigns) do
    ~H"""
    <div id="flash" class="flash-stack">
      <%= for {kind, message} <- @flash do %>
        <div class="flash-item">
          <strong class="flash-kind"><%= kind %>:</strong>{message}
        </div>
      <% end %>
    </div>
    """
  end

  attr :page, :string, required: true
  attr :where, :string, required: true
  attr :goal, :string, required: true
  attr :next, :string, required: true
  attr :cta_to, :string, default: nil
  attr :cta_label, :string, default: nil

  def mini_coach(assigns) do
    ~H"""
    <section class="mini-coach mini-coach-open" data-mini-coach data-page={@page}>
      <button
        type="button"
        class="mini-coach-fab"
        data-mini-coach-toggle
        aria-expanded="true"
        aria-controls={"mini-coach-panel-#{@page}"}
      >
        Coach
      </button>

      <article class="mini-coach-panel" id={"mini-coach-panel-#{@page}"} data-mini-coach-panel>
        <header class="mini-coach-head">
          <p class="mini-coach-title">Ton mini coach</p>
          <button type="button" class="mini-coach-close" data-mini-coach-close aria-label="Fermer">
            x
          </button>
        </header>

        <div class="mini-coach-body">
          <p class="mini-coach-intro">Je te guide en 10 secondes:</p>
          <p class="mini-coach-line">Tu es sur <strong>{@where}</strong>.</p>
          <p class="mini-coach-line">Ici, l'objectif est <strong>{@goal}</strong>.</p>
          <p class="mini-coach-line">Commence par <strong>{@next}</strong>.</p>
        </div>

        <footer class="mini-coach-actions">
          <a :if={@cta_to && @cta_label} href={@cta_to} class="ghost-link">{@cta_label}</a>
          <button type="button" class="ghost-link" data-mini-coach-dismiss>Ne plus afficher</button>
        </footer>
      </article>
    </section>
    """
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", format_error_value(value))
    end)
  end

  defp translate_error(msg) when is_binary(msg), do: msg

  defp format_error_value(value)

  defp format_error_value(value) when is_binary(value), do: value
  defp format_error_value(value) when is_number(value), do: to_string(value)
  defp format_error_value(value) when is_atom(value), do: Atom.to_string(value)

  defp format_error_value(value) when is_list(value) do
    if Enum.all?(value, &(is_binary(&1) or is_integer(&1))) do
      to_string(value)
    else
      inspect(value)
    end
  end

  defp format_error_value(value), do: inspect(value)
end
