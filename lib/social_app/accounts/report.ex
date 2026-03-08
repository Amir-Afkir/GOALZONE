defmodule SocialApp.Accounts.Report do
  use Ecto.Schema
  import Ecto.Changeset

  alias SocialApp.Accounts.User

  @status_values [:open, :reviewing, :closed]

  schema "reports" do
    field :reason, :string
    field :context, :string, default: ""
    field :status, Ecto.Enum, values: @status_values, default: :open

    belongs_to :reporter, User
    belongs_to :target_user, User

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(report, attrs) do
    report
    |> cast(attrs, [:reporter_id, :target_user_id, :reason, :context, :status])
    |> validate_required([:reporter_id, :reason])
    |> validate_length(:reason, min: 3, max: 100)
    |> validate_length(:context, max: 2_000)
    |> assoc_constraint(:reporter)
    |> assoc_constraint(:target_user)
  end
end
