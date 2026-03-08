defmodule SocialApp.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :content, :text, null: false
      add :likes_count, :integer, default: 0, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:posts, [:user_id])
    create index(:posts, [:inserted_at])
  end
end
