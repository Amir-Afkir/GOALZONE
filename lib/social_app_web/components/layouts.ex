defmodule SocialAppWeb.Layouts do
  use SocialAppWeb, :html

  def show_app_header?(assigns), do: layout_variant(assigns) != :feed

  def show_topbar_nav?(assigns) do
    not is_nil(assigns[:current_user]) and nav_variant(assigns) == :topbar
  end

  def app_layout_classes(assigns) do
    _ = assigns
    ["app-layout"]
  end

  def app_header_classes(_assigns) do
    ["app-topbar"]
  end

  def app_main_classes(assigns) do
    variant = layout_variant(assigns)

    [
      "app-main",
      variant == :feed && "app-main-no-header",
      variant == :feed && "app-main-feed"
    ]
  end

  def app_shell_classes(assigns) do
    case shell_variant(assigns) do
      :wide -> ["app-shell", "app-shell-wide"]
      :full -> ["app-shell-full"]
      _ -> ["app-shell"]
    end
  end

  def app_content_classes(assigns) do
    ["app-layout-content"] ++ app_shell_classes(assigns)
  end

  def layout_variant(assigns) do
    case assigns[:layout_variant] do
      :feed -> :feed
      "feed" -> :feed
      :default -> :default
      "default" -> :default
      nil -> if(assigns[:hide_app_header], do: :feed, else: :default)
      _ -> :default
    end
  end

  def shell_variant(assigns) do
    case assigns[:shell_variant] do
      :wide ->
        :wide

      "wide" ->
        :wide

      :full ->
        :full

      "full" ->
        :full

      :default ->
        :default

      "default" ->
        :default

      nil ->
        cond do
          layout_variant(assigns) == :feed -> :full
          assigns[:use_wide_layout] -> :wide
          true -> :default
        end

      _ ->
        :default
    end
  end

  def nav_variant(assigns) do
    case assigns[:nav_variant] do
      :sidebar -> :sidebar
      "sidebar" -> :sidebar
      :topbar -> :topbar
      "topbar" -> :topbar
      nil -> if(assigns[:use_sidebar_nav], do: :sidebar, else: :topbar)
      _ -> :topbar
    end
  end

  embed_templates "layouts/*"
end
