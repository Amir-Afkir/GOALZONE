defmodule SocialApp.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :post_id, references(:posts, on_delete: :delete_all), null: false
      add :content, :text, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:comments, [:user_id])
    create index(:comments, [:post_id])
    create index(:comments, [:inserted_at])
  end
end
