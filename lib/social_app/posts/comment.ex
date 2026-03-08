defmodule SocialApp.Posts.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  alias SocialApp.Accounts.User
  alias SocialApp.Posts.Post

  schema "comments" do
    field :content, :string

    belongs_to :user, User
    belongs_to :post, Post

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content, :user_id, :post_id])
    |> validate_required([:content, :user_id, :post_id])
    |> validate_length(:content, min: 1, max: 1_000)
    |> assoc_constraint(:user)
    |> assoc_constraint(:post)
  end
end
