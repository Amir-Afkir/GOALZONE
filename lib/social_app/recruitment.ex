defmodule SocialApp.Recruitment do
  @moduledoc """
  Pipeline recrutement (shortlist, progression et indicateurs).
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi

  alias SocialApp.Repo
  alias SocialApp.Accounts.User
  alias SocialApp.Feed
  alias SocialApp.Notifications
  alias SocialApp.Posts.Post
  alias SocialApp.Recruitment.ShortlistEntry

  @stage_order ShortlistEntry.stage_values()

  def stage_order, do: @stage_order

  def list_entries(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 80)

    from(s in ShortlistEntry,
      where: s.user_id == ^user_id,
      order_by: [desc: s.updated_at],
      limit: ^limit,
      preload: [post: :user]
    )
    |> Repo.all()
  end

  def list_entries_for_posts(_user_id, []), do: []

  def list_entries_for_posts(user_id, post_ids) do
    from(s in ShortlistEntry,
      where: s.user_id == ^user_id and s.post_id in ^post_ids
    )
    |> Repo.all()
  end

  def count_entries(user_id) do
    from(s in ShortlistEntry, where: s.user_id == ^user_id, select: count())
    |> Repo.one()
  end

  def stage_counts(user_id) do
    counts =
      from(s in ShortlistEntry,
        where: s.user_id == ^user_id,
        group_by: s.stage,
        select: {s.stage, count()}
      )
      |> Repo.all()
      |> Map.new()

    Enum.reduce(@stage_order, %{}, fn stage, acc ->
      Map.put(acc, stage, Map.get(counts, stage, 0))
    end)
  end

  def shortlisted?(user_id, post_id) do
    Repo.get_by(ShortlistEntry, user_id: user_id, post_id: post_id) != nil
  end

  def get_entry(user_id, post_id) do
    Repo.get_by(ShortlistEntry, user_id: user_id, post_id: post_id)
  end

  def toggle_shortlist(user_id, post_id) do
    case Repo.get_by(ShortlistEntry, user_id: user_id, post_id: post_id) do
      nil ->
        create_shortlist_entry(user_id, post_id)

      %ShortlistEntry{} = entry ->
        Repo.delete(entry)
    end
  end

  def advance_stage(user_id, post_id) do
    with %ShortlistEntry{} = entry <- get_entry(user_id, post_id),
         next when next != entry.stage <- next_stage(entry.stage) do
      entry
      |> ShortlistEntry.changeset(%{stage: next})
      |> Repo.update()
    else
      nil -> {:error, :not_found}
      _ -> {:error, :final_stage}
    end
  end

  def publish_announcement(%User{} = user, attrs) do
    attrs = Map.new(attrs)

    user_changeset =
      user
      |> User.profile_changeset(
        %{
          region: Map.get(attrs, :region),
          role: Map.get(attrs, :role),
          level: Map.get(attrs, :level),
          availability: Map.get(attrs, :availability)
        },
        validate_email: false,
        validate_username: false
      )
      |> Ecto.Changeset.validate_required([:region, :role, :level, :availability])

    post_attrs = %{
      content: Map.get(attrs, :content),
      user_id: user.id,
      post_format: :article,
      intention: :recruitment,
      source_type: :unknown
    }

    post_changeset = Post.changeset(%Post{}, post_attrs)

    Multi.new()
    |> Multi.update(:user, user_changeset)
    |> Multi.insert(:post, post_changeset)
    |> Repo.transaction()
    |> case do
      {:ok, %{user: updated_user, post: post}} ->
        Feed.fan_out_post_async(post)
        {:ok, %{user: updated_user, post: post}}

      {:error, step, changeset, _changes_so_far} ->
        {:error, step, changeset}
    end
  end

  def next_stage(stage) do
    index = Enum.find_index(@stage_order, &(&1 == stage))

    cond do
      is_nil(index) -> :sourced
      index >= length(@stage_order) - 2 -> stage
      true -> Enum.at(@stage_order, index + 1)
    end
  end

  defp create_shortlist_entry(user_id, post_id) do
    Repo.transaction(fn ->
      post = Repo.get!(Post, post_id)

      attrs = %{
        user_id: user_id,
        post_id: post_id,
        stage: :sourced,
        source_type: post.source_type,
        verification_status: post.verification_status,
        confidence_score: post.confidence_score
      }

      case %ShortlistEntry{} |> ShortlistEntry.changeset(attrs) |> Repo.insert() do
        {:ok, entry} ->
          maybe_notify_post_owner(post, user_id)
          entry

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  defp maybe_notify_post_owner(%Post{user_id: owner_id, id: post_id}, actor_id)
       when owner_id != actor_id do
    Notifications.create_notification(%{
      user_id: owner_id,
      origin_user_id: actor_id,
      post_id: post_id,
      type: :shortlist_added
    })
  end

  defp maybe_notify_post_owner(_, _), do: :ok
end
