defmodule SocialApp.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  alias SocialApp.Accounts.User
  alias SocialApp.Messaging.Thread
  alias SocialApp.Posts.Post

  @type_values [:like, :comment, :follow, :shortlist_added, :message_received, :system]

  schema "notifications" do
    field :type, Ecto.Enum, values: @type_values
    field :read, :boolean, default: false

    belongs_to :user, User
    belongs_to :origin_user, User
    belongs_to :post, Post
    belongs_to :thread, Thread

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:user_id, :origin_user_id, :post_id, :thread_id, :type, :read])
    |> validate_required([:user_id, :origin_user_id, :type])
    |> assoc_constraint(:user)
    |> assoc_constraint(:origin_user)
    |> assoc_constraint(:post)
    |> assoc_constraint(:thread)
  end
end
