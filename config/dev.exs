import Config

config :social_app, SocialApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "social_app_dev",
  show_sensitive_data_on_connection_error: true,
  stacktrace: true,
  pool_size: 10

config :social_app, SocialAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "I5Z5w5F4Vv3kW2fP8W4u8eX3Y6J2nQ5oN4dE8aG2wP7kH3vR1xC9mT6yB4qS2zL9uE3mA7nB5dT2",
  watchers: []

config :social_app, SocialAppWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/social_app_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

config :logger, :default_formatter, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime

config :social_app, :dns_cluster_query, :ignore
config :social_app, :dev_routes, true
config :social_app, SocialApp.Mailer, adapter: Swoosh.Adapters.Local
