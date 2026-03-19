defmodule SocialApp.Accounts do
  @moduledoc """
  Contexte utilisateur: authentification + relation follow.
  """

  import Ecto.Query, warn: false

  alias SocialApp.Repo
  alias SocialApp.Notifications
  alias SocialApp.Accounts.{Block, Follow, Report, User, UserNotifier, UserToken}

  ## User reads and profile

  def list_users, do: Repo.all(User)
  def get_user(id), do: Repo.get(User, id)
  def get_user!(id), do: Repo.get!(User, id)

  def list_directory(filters \\ %{}, opts \\ []) do
    exclude_user_id = Keyword.get(opts, :exclude_user_id)
    limit = Keyword.get(opts, :limit, 120)
    order_by = Keyword.get(opts, :order_by, :username)
    viewer_region = Keyword.get(opts, :viewer_region)

    User
    |> maybe_exclude_user(exclude_user_id)
    |> apply_directory_filters(filters)
    |> apply_directory_order(order_by, viewer_region)
    |> limit(^limit)
    |> Repo.all()
  end

  def count_directory(filters \\ %{}, opts \\ []) do
    exclude_user_id = Keyword.get(opts, :exclude_user_id)

    User
    |> maybe_exclude_user(exclude_user_id)
    |> apply_directory_filters(filters)
    |> select([u], count(u.id))
    |> Repo.one()
  end

  def list_suggested_users(user_id, opts \\ [])

  def list_suggested_users(nil, opts) do
    limit = Keyword.get(opts, :limit, 8)
    list_directory(%{}, limit: limit)
  end

  def list_suggested_users(user_id, opts) do
    limit = Keyword.get(opts, :limit, 8)

    from(u in User,
      left_join: f in Follow,
      on: f.followed_id == u.id and f.follower_id == ^user_id,
      where: u.id != ^user_id and is_nil(f.followed_id),
      order_by: [asc: u.username],
      limit: ^limit
    )
    |> Repo.all()
  end

  def directory_facets(opts \\ []) do
    exclude_user_id = Keyword.get(opts, :exclude_user_id)
    base_query = User |> maybe_exclude_user(exclude_user_id)

    %{
      regions: list_distinct_field_values(base_query, :region),
      levels: list_distinct_field_values(base_query, :level),
      availabilities: list_distinct_field_values(base_query, :availability)
    }
  end

  def get_user_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: username)
  end

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  def update_user(%User{} = user, attrs) do
    attrs =
      attrs
      |> Map.new()
      |> Map.put_new(:email, user.email)
      |> Map.put_new(:username, user.username)

    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  ## Social graph

  def follow_user(follower_id, followed_id) when follower_id == followed_id do
    {:error, :cannot_follow_self}
  end

  def follow_user(follower_id, followed_id) do
    case Repo.get_by(Follow, follower_id: follower_id, followed_id: followed_id) do
      %Follow{} = follow ->
        {:ok, follow}

      nil ->
        with {:ok, follow} <-
               %Follow{}
               |> Follow.changeset(%{follower_id: follower_id, followed_id: followed_id})
               |> Repo.insert() do
          _ =
            Notifications.create_notification(%{
              user_id: followed_id,
              origin_user_id: follower_id,
              type: :follow
            })

          {:ok, follow}
        end
    end
  end

  def unfollow_user(follower_id, followed_id) do
    from(f in Follow, where: f.follower_id == ^follower_id and f.followed_id == ^followed_id)
    |> Repo.delete_all()
  end

  def list_followed_ids(user_id) do
    from(f in Follow,
      where: f.follower_id == ^user_id,
      select: f.followed_id
    )
    |> Repo.all()
  end

  def list_followers(user_id) do
    from(u in User,
      join: f in Follow,
      on: f.follower_id == u.id,
      where: f.followed_id == ^user_id
    )
    |> Repo.all()
  end

  def block_user(blocker_id, blocked_id) when blocker_id == blocked_id do
    {:error, :cannot_block_self}
  end

  def block_user(blocker_id, blocked_id) do
    %Block{}
    |> Block.changeset(%{blocker_id: blocker_id, blocked_id: blocked_id})
    |> Repo.insert(on_conflict: :nothing)
  end

  def unblock_user(blocker_id, blocked_id) do
    from(b in Block, where: b.blocker_id == ^blocker_id and b.blocked_id == ^blocked_id)
    |> Repo.delete_all()
  end

  def list_blocked_ids(user_id) do
    from(b in Block,
      where: b.blocker_id == ^user_id,
      select: b.blocked_id
    )
    |> Repo.all()
  end

  def create_report(reporter_id, attrs) do
    attrs = Map.put(Map.new(attrs), :reporter_id, reporter_id)

    %Report{}
    |> Report.changeset(attrs)
    |> Repo.insert()
  end

  def list_following(user_id) do
    from(u in User,
      join: f in Follow,
      on: f.followed_id == u.id,
      where: f.follower_id == ^user_id
    )
    |> Repo.all()
  end

  ## Auth - credentials

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  ## Auth - registration

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs,
      hash_password: false,
      validate_email: false,
      validate_username: false
    )
  end

  ## Auth - settings

  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Auth - session

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Auth - confirmation

  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Auth - reset password

  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  defp maybe_exclude_user(query, nil), do: query

  defp maybe_exclude_user(query, user_id) do
    from(u in query, where: u.id != ^user_id)
  end

  defp apply_directory_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:role, role}, acc when role in [:player, :coach, :agent, :scout, :club] ->
        from(u in acc, where: u.role == ^role)

      {:region, region}, acc when is_binary(region) and region != "" ->
        from(u in acc, where: u.region == ^region)

      {:level, level}, acc when level in [:espoir, :confirme, :elite] ->
        from(u in acc, where: u.level == ^level)

      {:availability, availability}, acc when availability in [:open, :monitoring, :closed] ->
        from(u in acc, where: u.availability == ^availability)

      {:min_confidence_score, score}, acc when is_integer(score) ->
        from(u in acc, where: coalesce(u.confidence_score, 0) >= ^score)

      {:headline_required, true}, acc ->
        from(u in acc, where: fragment("COALESCE(?, '') <> ''", u.headline))

      {:q, q}, acc when is_binary(q) and q != "" ->
        pattern = "%#{q}%"

        from(u in acc,
          where:
            ilike(u.username, ^pattern) or ilike(u.headline, ^pattern) or
              ilike(u.position, ^pattern) or
              ilike(u.region, ^pattern)
        )

      _, acc ->
        acc
    end)
  end

  defp apply_directory_order(query, :mission_priority, viewer_region) do
    from(u in query,
      order_by: [
        desc: fragment("CASE WHEN ? = 'open' THEN 1 ELSE 0 END", u.availability),
        desc:
          fragment(
            "CASE WHEN ? = 'elite' THEN 2 WHEN ? = 'confirme' THEN 1 ELSE 0 END",
            u.level,
            u.level
          ),
        desc: fragment("CASE WHEN COALESCE(?, '') <> '' THEN 1 ELSE 0 END", u.headline),
        desc: fragment("COALESCE(?, 0)", u.confidence_score),
        desc:
          fragment(
            "CASE WHEN COALESCE(?, '') <> '' AND ? = ? THEN 1 ELSE 0 END",
            u.region,
            u.region,
            ^viewer_region
          ),
        asc: u.username
      ]
    )
  end

  defp apply_directory_order(query, _order_by, _viewer_region) do
    from(u in query, order_by: [asc: u.username])
  end

  defp list_distinct_field_values(query, field_name) do
    from(u in query,
      select: field(u, ^field_name),
      distinct: true,
      order_by: field(u, ^field_name)
    )
    |> Repo.all()
    |> Enum.reject(&(&1 in [nil, ""]))
  end
end
