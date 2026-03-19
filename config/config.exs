import Config

config :social_app,
  ecto_repos: [SocialApp.Repo],
  generators: [timestamp_type: :utc_datetime_usec]

config :social_app, :dev_routes, false

config :social_app, SocialAppWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: SocialAppWeb.ErrorHTML, json: SocialAppWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: SocialApp.PubSub,
  live_view: [signing_salt: "REPLACE_ME"]

config :esbuild,
  version: "0.25.4",
  js: [
    args:
      ~w(app.js --bundle --target=es2022 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ],
  css: [
    args: ~w(app.css --bundle --loader:.png=file --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__)
  ]

config :social_app, Oban,
  repo: SocialApp.Repo,
  queues: [default: 10, fan_out: 20, notifications: 10],
  plugins: [Oban.Plugins.Pruner]

config :social_app, SocialApp.Mailer, adapter: Swoosh.Adapters.Local
config :swoosh, :api_client, false

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
