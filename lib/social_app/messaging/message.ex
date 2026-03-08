defmodule SocialApp.Messaging.Message do
  use Ecto.Schema
  import Ecto.Changeset

  alias SocialApp.Accounts.User
  alias SocialApp.Messaging.Thread

  schema "messages" do
    field :body, :string

    belongs_to :thread, Thread
    belongs_to :sender, User

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:thread_id, :sender_id, :body])
    |> validate_required([:thread_id, :sender_id, :body])
    |> validate_length(:body, min: 1, max: 2_000)
    |> assoc_constraint(:thread)
    |> assoc_constraint(:sender)
  end
end
