defmodule SocialApp.RecruitmentTest do
  use SocialApp.DataCase, async: true

  import SocialApp.AccountsFixtures

  alias SocialApp.{Accounts, Posts, Recruitment}

  test "toggle shortlist and advance stage for a post" do
    recruiter = user_fixture()
    player = user_fixture()
    {:ok, post} = Posts.create_post(player.id, %{content: "Profil cible"})

    assert {:ok, entry} = Recruitment.toggle_shortlist(recruiter.id, post.id)
    assert entry.stage == :sourced

    assert %{} = Recruitment.stage_counts(recruiter.id)
    assert Recruitment.shortlisted?(recruiter.id, post.id)

    assert {:ok, advanced_entry} = Recruitment.advance_stage(recruiter.id, post.id)
    assert advanced_entry.stage == :qualified

    assert {:ok, _deleted} = Recruitment.toggle_shortlist(recruiter.id, post.id)
    refute Recruitment.shortlisted?(recruiter.id, post.id)
    assert is_nil(Recruitment.get_entry(recruiter.id, post.id))
  end

  test "publish_announcement updates the user profile and creates a recruitment post" do
    user = user_fixture()

    assert {:ok, %{user: updated_user, post: post}} =
             Recruitment.publish_announcement(user, %{
               region: "Casablanca",
               role: :player,
               level: :elite,
               availability: :open,
               content: "Je cherche un projet ambitieux pour la prochaine saison."
             })

    persisted_user = Accounts.get_user!(user.id)

    assert updated_user.region == "Casablanca"
    assert persisted_user.level == :elite
    assert persisted_user.availability == :open
    assert post.user_id == user.id
    assert post.intention == :recruitment
    assert post.post_format == :article
  end
end
