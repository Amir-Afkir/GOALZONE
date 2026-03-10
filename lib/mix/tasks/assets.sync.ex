defmodule Mix.Tasks.Assets.Sync do
  use Mix.Task

  @shortdoc "Syncs source assets into priv/static/assets"

  @source_dir "assets"
  @target_dir "priv/static/assets"
  @files ~w(app.css app.js terrain.png)

  @impl true
  def run(_args) do
    File.mkdir_p!(@target_dir)

    Enum.each(@files, fn file ->
      source = Path.join(@source_dir, file)
      target = Path.join(@target_dir, file)

      unless File.exists?(source) do
        Mix.raise("Missing source asset #{source}")
      end

      case File.cp(source, target) do
        :ok -> :ok
        {:error, reason} -> Mix.raise("Failed to copy #{source} -> #{target}: #{inspect(reason)}")
      end
    end)

    Mix.shell().info("Synced #{@source_dir} to #{@target_dir}")
  end
end
