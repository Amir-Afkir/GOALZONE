defmodule SocialApp.Repo.Migrations.AddPostFormatAndIntention do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :post_format, :string, null: false, default: "post"
      add :intention, :string, null: false, default: "entertainment"
    end

    create index(:posts, [:post_format])
    create index(:posts, [:intention])
  end
end
