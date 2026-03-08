import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

config :social_app, SocialApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "social_app_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :social_app, SocialAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "7xP3bN9kD2qL6wM1rV8tF4zH5cJ2yS9uA3eR7gT1mK5pQ8dW2nB6vC4xZ9hL1oY8rE4pT1sA6cK3",
  server: false

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime

config :social_app, Oban, testing: :inline
config :social_app, :dns_cluster_query, :ignore
config :social_app, SocialApp.Mailer, adapter: Swoosh.Adapters.Test
