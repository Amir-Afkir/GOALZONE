defmodule SocialAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :social_app

  @session_options [
    store: :cookie,
    key: "_social_app_key",
    signing_salt: "REPLACE_ME",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: false

  plug Plug.Static,
    at: "/",
    from: :social_app,
    gzip: Mix.env() == :prod,
    only: SocialAppWeb.static_paths(),
    raise_on_missing_only: Mix.env() == :dev

  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :social_app
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug SocialAppWeb.Router
end
