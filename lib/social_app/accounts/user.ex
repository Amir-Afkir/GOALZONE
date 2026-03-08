defmodule SocialApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias SocialApp.Posts.Post
  alias SocialApp.Accounts.{Block, Report}
  alias SocialApp.Messaging.{Message, Thread}
  alias SocialApp.Notifications.Notification
  alias SocialApp.Recruitment.ShortlistEntry

  @role_values [:player, :coach, :agent, :scout, :club]
  @level_values [:espoir, :confirme, :elite]
  @availability_values [:open, :monitoring, :closed]
  @source_values [:highlight_video, :full_match_video, :live_observation, :stat_report, :unknown]
  @verification_values [:self_declared, :scout_validated, :club_verified]

  schema "users" do
    field :username, :string
    field :email, :string
    field :role, Ecto.Enum, values: @role_values, default: :player
    field :onboarding_completed, :boolean, default: false
    field :headline, :string, default: ""
    field :position, :string, default: ""
    field :age, :integer
    field :region, :string, default: ""
    field :level, Ecto.Enum, values: @level_values, default: :espoir
    field :availability, Ecto.Enum, values: @availability_values, default: :open
    field :bio, :string, default: ""
    field :source_type, Ecto.Enum, values: @source_values, default: :unknown
    field :verification_status, Ecto.Enum, values: @verification_values, default: :self_declared
    field :confidence_score, :integer
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :utc_datetime_usec

    has_many :posts, Post
    has_many :notifications, Notification
    has_many :shortlist_entries, ShortlistEntry
    has_many :sent_messages, Message, foreign_key: :sender_id
    has_many :created_threads, Thread, foreign_key: :creator_id
    has_many :threads_as_a, Thread, foreign_key: :user_a_id
    has_many :threads_as_b, Thread, foreign_key: :user_b_id
    has_many :blocks, Block, foreign_key: :blocker_id
    has_many :reports, Report, foreign_key: :reporter_id

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Registration changeset with auth + social fields.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:username, :email, :password])
    |> validate_username(opts)
    |> validate_email(opts)
    |> validate_password(opts)
  end

  def profile_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [
      :username,
      :email,
      :role,
      :onboarding_completed,
      :headline,
      :position,
      :age,
      :region,
      :level,
      :availability,
      :bio,
      :source_type,
      :verification_status,
      :confidence_score
    ])
    |> validate_username(opts)
    |> validate_email(opts)
    |> validate_length(:headline, max: 140)
    |> validate_length(:position, max: 60)
    |> validate_number(:age, greater_than_or_equal_to: 12, less_than_or_equal_to: 60)
    |> validate_length(:region, max: 120)
    |> validate_length(:bio, max: 2_000)
    |> validate_number(:confidence_score, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
  end

  defp validate_username(changeset, opts) do
    changeset
    |> maybe_put_generated_username()
    |> validate_length(:username, min: 3, max: 30)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/,
      message: "must contain only letters, numbers or underscore"
    )
    |> maybe_validate_unique_username(opts)
  end

  defp maybe_put_generated_username(changeset) do
    username = get_field(changeset, :username)
    email = get_field(changeset, :email)

    cond do
      is_binary(username) and String.trim(username) != "" ->
        changeset

      is_binary(email) and String.contains?(email, "@") ->
        local_part =
          email |> String.split("@") |> List.first() |> String.replace(~r/[^a-zA-Z0-9_]/, "_")

        generated = "#{local_part}_#{System.unique_integer([:positive])}"
        put_change(changeset, :username, generated)

      true ->
        changeset
    end
  end

  defp maybe_validate_unique_username(changeset, opts) do
    if Keyword.get(opts, :validate_username, true) do
      changeset
      |> unsafe_validate_unique(:username, SocialApp.Repo)
      |> unique_constraint(:username)
    else
      changeset
    end
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, SocialApp.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.
  """
  def valid_password?(%SocialApp.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
