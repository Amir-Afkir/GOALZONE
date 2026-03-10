defmodule Mix.Tasks.Assets.Verify do
  use Mix.Task

  @shortdoc "Fails if assets and priv/static/assets are out of sync"

  @source_dir "assets"
  @target_dir "priv/static/assets"
  @files ~w(app.css app.js terrain.png)

  @impl true
  def run(_args) do
    Enum.each(@files, fn file ->
      source = Path.join(@source_dir, file)
      target = Path.join(@target_dir, file)

      unless File.exists?(source) do
        Mix.raise("Missing source asset #{source}")
      end

      unless File.exists?(target) do
        Mix.raise("Missing compiled asset #{target}. Run: mix assets.sync")
      end

      source_content = File.read!(source)
      target_content = File.read!(target)

      if source_content != target_content do
        Mix.raise("Asset drift detected for #{file}. Run: mix assets.sync")
      end
    end)

    Mix.shell().info("Assets are synchronized")
  end
end
