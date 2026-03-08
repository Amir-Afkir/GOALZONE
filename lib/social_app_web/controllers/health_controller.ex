defmodule SocialAppWeb.HealthController do
  use SocialAppWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
