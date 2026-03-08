defmodule SocialApp.Accounts.Follow do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "follows" do
    belongs_to :follower, SocialApp.Accounts.User, primary_key: true
    belongs_to :followed, SocialApp.Accounts.User, primary_key: true

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(follow, attrs) do
    follow
    |> cast(attrs, [:follower_id, :followed_id])
    |> validate_required([:follower_id, :followed_id])
    |> unique_constraint([:follower_id, :followed_id], name: :follows_pkey)
    |> check_constraint(:followed_id, name: :follower_not_equal_followed)
  end
end
