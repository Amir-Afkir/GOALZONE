defmodule SocialApp.AssetsTasksTest do
  use ExUnit.Case, async: false

  test "project defines build and deploy aliases for assets" do
    aliases = Mix.Project.config()[:aliases] |> Enum.into(%{})

    assert alias_value(aliases, "assets.setup") == ["esbuild.install --if-missing"]
    assert alias_value(aliases, "assets.sync") == ["assets.build"]
    assert alias_value(aliases, "assets.build") == ["compile", "esbuild js", "esbuild css"]

    assert alias_value(aliases, "assets.deploy") == [
             "esbuild js --minify",
             "esbuild css --minify",
             "phx.digest"
           ]
  end

  defp alias_value(aliases, key) do
    Map.get(aliases, key) || Map.get(aliases, String.to_atom(key))
  end
end
