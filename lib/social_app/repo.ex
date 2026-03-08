defmodule SocialApp.Repo do
  use Ecto.Repo,
    otp_app: :social_app,
    adapter: Ecto.Adapters.Postgres
end
