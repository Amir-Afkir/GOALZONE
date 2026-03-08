defmodule SocialApp.Posts.Like do
  use Ecto.Schema
  import Ecto.Changeset

  alias SocialApp.Accounts.User
  alias SocialApp.Posts.Post

  schema "likes" do
    belongs_to :user, User
    belongs_to :post, Post

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(like, attrs) do
    like
    |> cast(attrs, [:user_id, :post_id])
    |> validate_required([:user_id, :post_id])
    |> unique_constraint([:user_id, :post_id], name: :likes_user_id_post_id_index)
    |> assoc_constraint(:user)
    |> assoc_constraint(:post)
  end
end
