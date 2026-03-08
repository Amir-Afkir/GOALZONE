defmodule SocialApp.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    alter table(:users) do
      add :hashed_password, :string
      add :confirmed_at, :utc_datetime_usec
    end

    execute "UPDATE users SET hashed_password = password_hash WHERE hashed_password IS NULL"

    alter table(:users) do
      modify :hashed_password, :string, null: false
      remove :password_hash
    end

    execute "ALTER TABLE users ALTER COLUMN email TYPE citext USING email::citext"

    drop_if_exists index(:users, [:email])
    create unique_index(:users, [:email])

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])
  end

  def down do
    drop_if_exists unique_index(:users_tokens, [:context, :token])
    drop_if_exists index(:users_tokens, [:user_id])
    drop_if_exists table(:users_tokens)

    alter table(:users) do
      add :password_hash, :string
    end

    execute "UPDATE users SET password_hash = hashed_password WHERE password_hash IS NULL"

    alter table(:users) do
      modify :password_hash, :string, null: false
      remove :hashed_password
      remove :confirmed_at
    end

    execute "ALTER TABLE users ALTER COLUMN email TYPE varchar(255) USING email::varchar(255)"
  end
end
