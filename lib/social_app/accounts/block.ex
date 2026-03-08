defmodule SocialApp.Accounts.Block do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "blocks" do
    belongs_to :blocker, SocialApp.Accounts.User, primary_key: true
    belongs_to :blocked, SocialApp.Accounts.User, primary_key: true

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(block, attrs) do
    block
    |> cast(attrs, [:blocker_id, :blocked_id])
    |> validate_required([:blocker_id, :blocked_id])
    |> unique_constraint([:blocker_id, :blocked_id], name: :blocks_pkey)
    |> check_constraint(:blocked_id, name: :blocker_not_equal_blocked)
  end
end
