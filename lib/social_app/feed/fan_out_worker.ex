defmodule SocialApp.Feed.FanOutWorker do
  @moduledoc false
  use Oban.Worker, queue: :fan_out, max_attempts: 10

  alias SocialApp.Feed

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"post_id" => post_id}}) when is_integer(post_id) do
    case Feed.fan_out_post(post_id) do
      :ok -> :ok
      {:error, :post_not_found} -> :discard
      {:error, reason} -> {:error, inspect(reason)}
    end
  end

  def perform(_job), do: :discard
end
