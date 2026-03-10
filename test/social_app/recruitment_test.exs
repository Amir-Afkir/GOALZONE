defmodule SocialApp.RecruitmentTest do
  use SocialApp.DataCase, async: true

  import SocialApp.AccountsFixtures

  alias SocialApp.{Posts, Recruitment}

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
end
