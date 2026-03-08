defmodule SocialApp.Repo.Migrations.CreateFollows do
  use Ecto.Migration

  def change do
    create table(:follows, primary_key: false) do
      add :follower_id, references(:users, on_delete: :delete_all), null: false, primary_key: true
      add :followed_id, references(:users, on_delete: :delete_all), null: false, primary_key: true

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:follows, [:followed_id])

    create constraint(:follows, :follower_not_equal_followed,
             check: "follower_id <> followed_id"
           )
  end
end
