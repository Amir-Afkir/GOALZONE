defmodule SocialApp.Recruitment.ShortlistEntry do
  use Ecto.Schema
  import Ecto.Changeset

  alias SocialApp.Accounts.User
  alias SocialApp.Posts.Post

  @stage_values [:sourced, :qualified, :contacted, :trial, :offer, :signed, :rejected]
  @source_values [:highlight_video, :full_match_video, :live_observation, :stat_report, :unknown]
  @verification_values [:self_declared, :scout_validated, :club_verified]

  schema "shortlist_entries" do
    field :stage, Ecto.Enum, values: @stage_values, default: :sourced
    field :next_action, :string, default: ""
    field :next_action_due_at, :utc_datetime_usec
    field :confidence_score, :integer
    field :source_type, Ecto.Enum, values: @source_values
    field :verification_status, Ecto.Enum, values: @verification_values

    belongs_to :user, User
    belongs_to :post, Post

    timestamps(type: :utc_datetime_usec)
  end

  def stage_values, do: @stage_values

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [
      :user_id,
      :post_id,
      :stage,
      :next_action,
      :next_action_due_at,
      :confidence_score,
      :source_type,
      :verification_status
    ])
    |> validate_required([:user_id, :post_id, :stage])
    |> validate_length(:next_action, max: 255)
    |> validate_number(:confidence_score, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> unique_constraint([:user_id, :post_id], name: :shortlist_entries_user_id_post_id_index)
    |> assoc_constraint(:user)
    |> assoc_constraint(:post)
  end
end
