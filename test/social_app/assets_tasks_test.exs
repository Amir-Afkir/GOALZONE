defmodule SocialApp.AssetsTasksTest do
  use ExUnit.Case, async: false

  setup do
    static_css = Path.join([File.cwd!(), "priv", "static", "assets", "app.css"])
    original_css = File.read!(static_css)

    on_exit(fn ->
      File.write!(static_css, original_css)
    end)

    :ok
  end

  test "assets.verify passes when files are synchronized" do
    Mix.Task.reenable("assets.verify")
    assert :ok = Mix.Task.run("assets.verify")
  end

  test "assets.verify fails when files are out of sync" do
    static_css = Path.join([File.cwd!(), "priv", "static", "assets", "app.css"])
    File.write!(static_css, File.read!(static_css) <> "\n/* drift */\n")

    Mix.Task.reenable("assets.verify")

    assert_raise Mix.Error, ~r/Asset drift detected/, fn ->
      Mix.Task.run("assets.verify")
    end
  end
end
