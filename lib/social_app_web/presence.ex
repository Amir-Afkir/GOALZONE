defmodule SocialAppWeb.Presence do
  use Phoenix.Presence,
    otp_app: :social_app,
    pubsub_server: SocialApp.PubSub
end
