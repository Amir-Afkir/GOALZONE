alias SocialApp.Accounts
alias SocialApp.Posts

{:ok, alice} =
  Accounts.register_user(%{
    username: "alice",
    email: "alice@example.com",
    password: "password1234"
  })

{:ok, bob} =
  Accounts.register_user(%{
    username: "bob",
    email: "bob@example.com",
    password: "password1234"
  })

_ = Accounts.follow_user(bob.id, alice.id)
{:ok, _post} = Posts.create_post(alice.id, %{content: "Premier post de demo"})
