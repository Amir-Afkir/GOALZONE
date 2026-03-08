defmodule SocialApp.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        SocialAppWeb.Telemetry,
        SocialApp.Repo,
        {DNSCluster, query: Application.get_env(:social_app, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: SocialApp.PubSub},
        SocialAppWeb.Presence,
        redix_child_spec(),
        {Oban, Application.fetch_env!(:social_app, Oban)},
        SocialAppWeb.Endpoint
      ]
      |> Enum.reject(&is_nil/1)

    opts = [strategy: :one_for_one, name: SocialApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    SocialAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp redix_child_spec do
    case System.get_env("REDIS_URL") do
      nil -> {Redix, {"redis://localhost:6379/0", [name: :redix]}}
      url -> {Redix, {url, [name: :redix]}}
    end
  end
end
