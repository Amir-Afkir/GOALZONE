defmodule SocialApp.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  alias SocialApp.Accounts.User
  alias SocialApp.Posts.{Like, Comment}
  alias SocialApp.Recruitment.ShortlistEntry

  @post_format_values [:post, :photo, :video, :article]
  @intention_values [:entertainment, :showcase, :recruitment]
  @community_values [:anyone, :twitter, :connection, :group]
  @source_values [:highlight_video, :full_match_video, :live_observation, :stat_report, :unknown]
  @verification_values [:self_declared, :scout_validated, :club_verified]

  schema "posts" do
    field :content, :string
    field :likes_count, :integer, default: 0
    field :post_format, Ecto.Enum, values: @post_format_values, default: :post
    field :intention, Ecto.Enum, values: @intention_values, default: :entertainment
    field :community_type, Ecto.Enum, values: @community_values, default: :anyone
    field :media_url, :string
    field :competition, :string
    field :opponent, :string
    field :match_minute, :integer
    field :source_type, Ecto.Enum, values: @source_values, default: :unknown
    field :verification_status, Ecto.Enum, values: @verification_values, default: :self_declared
    field :confidence_score, :integer

    belongs_to :user, User
    has_many :likes, Like
    has_many :comments, Comment
    has_many :shortlist_entries, ShortlistEntry

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [
      :content,
      :user_id,
      :post_format,
      :intention,
      :community_type,
      :media_url,
      :competition,
      :opponent,
      :match_minute,
      :source_type,
      :verification_status,
      :confidence_score
    ])
    |> validate_required([:content, :user_id])
    |> validate_length(:content, min: 1, max: 500)
    |> validate_length(:competition, max: 120)
    |> validate_length(:opponent, max: 120)
    |> validate_number(:match_minute, greater_than_or_equal_to: 0, less_than_or_equal_to: 130)
    |> validate_number(:confidence_score, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> assoc_constraint(:user)
  end
end
