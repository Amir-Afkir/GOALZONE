defmodule SocialApp.Repo.Migrations.AddTtcFeatures do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :role, :string, null: false, default: "player"
      add :onboarding_completed, :boolean, null: false, default: false
      add :headline, :string, null: false, default: ""
      add :position, :string, null: false, default: ""
      add :age, :integer
      add :region, :string, null: false, default: ""
      add :level, :string, null: false, default: "espoir"
      add :availability, :string, null: false, default: "open"
      add :bio, :text, null: false, default: ""
      add :source_type, :string, null: false, default: "unknown"
      add :verification_status, :string, null: false, default: "self_declared"
      add :confidence_score, :integer
    end

    create index(:users, [:role])
    create index(:users, [:region])
    create index(:users, [:level])
    create index(:users, [:availability])

    alter table(:posts) do
      add :community_type, :string, null: false, default: "anyone"
      add :media_url, :string
      add :competition, :string
      add :opponent, :string
      add :match_minute, :integer
      add :source_type, :string, null: false, default: "unknown"
      add :verification_status, :string, null: false, default: "self_declared"
      add :confidence_score, :integer
    end

    create index(:posts, [:community_type])
    create index(:posts, [:source_type])

    create table(:shortlist_entries) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :post_id, references(:posts, on_delete: :delete_all), null: false
      add :stage, :string, null: false, default: "sourced"
      add :next_action, :string, null: false, default: ""
      add :next_action_due_at, :utc_datetime_usec
      add :confidence_score, :integer
      add :verification_status, :string
      add :source_type, :string

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:shortlist_entries, [:user_id, :post_id])
    create index(:shortlist_entries, [:user_id, :stage])
    create index(:shortlist_entries, [:updated_at])

    create table(:message_threads) do
      add :creator_id, references(:users, on_delete: :nilify_all)
      add :user_a_id, references(:users, on_delete: :delete_all), null: false
      add :user_b_id, references(:users, on_delete: :delete_all), null: false
      add :last_message_text, :string, null: false, default: ""
      add :last_message_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:message_threads, [:user_a_id, :user_b_id])
    create index(:message_threads, [:last_message_at])
    create index(:message_threads, [:user_a_id])
    create index(:message_threads, [:user_b_id])

    create constraint(:message_threads, :user_a_before_user_b,
             check: "user_a_id < user_b_id"
           )

    create table(:messages) do
      add :thread_id, references(:message_threads, on_delete: :delete_all), null: false
      add :sender_id, references(:users, on_delete: :delete_all), null: false
      add :body, :text, null: false

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:messages, [:thread_id, :inserted_at])
    create index(:messages, [:sender_id])

    alter table(:notifications) do
      add :thread_id, references(:message_threads, on_delete: :delete_all)
    end

    create index(:notifications, [:thread_id])
    create index(:notifications, [:type, :inserted_at])

    create table(:blocks, primary_key: false) do
      add :blocker_id, references(:users, on_delete: :delete_all), null: false, primary_key: true
      add :blocked_id, references(:users, on_delete: :delete_all), null: false, primary_key: true

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:blocks, [:blocked_id])

    create constraint(:blocks, :blocker_not_equal_blocked,
             check: "blocker_id <> blocked_id"
           )

    create table(:reports) do
      add :reporter_id, references(:users, on_delete: :delete_all), null: false
      add :target_user_id, references(:users, on_delete: :nilify_all)
      add :reason, :string, null: false
      add :context, :text, null: false, default: ""
      add :status, :string, null: false, default: "open"

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:reports, [:reporter_id, :status])
    create index(:reports, [:target_user_id])
  end
end
