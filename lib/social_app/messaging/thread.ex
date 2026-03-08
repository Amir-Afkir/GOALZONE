defmodule SocialApp.Messaging.Thread do
  use Ecto.Schema
  import Ecto.Changeset

  alias SocialApp.Accounts.User
  alias SocialApp.Messaging.Message

  schema "message_threads" do
    field :last_message_text, :string, default: ""
    field :last_message_at, :utc_datetime_usec

    belongs_to :creator, User
    belongs_to :user_a, User
    belongs_to :user_b, User

    has_many :messages, Message

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(thread, attrs) do
    thread
    |> cast(attrs, [:creator_id, :user_a_id, :user_b_id, :last_message_text, :last_message_at])
    |> validate_required([:user_a_id, :user_b_id])
    |> validate_length(:last_message_text, max: 255)
    |> unique_constraint([:user_a_id, :user_b_id],
      name: :message_threads_user_a_id_user_b_id_index
    )
    |> check_constraint(:user_b_id, name: :user_a_before_user_b)
    |> assoc_constraint(:creator)
    |> assoc_constraint(:user_a)
    |> assoc_constraint(:user_b)
  end
end
