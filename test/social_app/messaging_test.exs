defmodule SocialApp.MessagingTest do
  use SocialApp.DataCase, async: true

  import SocialApp.AccountsFixtures

  alias SocialApp.{Messaging, Notifications}

  test "send_message broadcasts to thread subscribers and creates a notification" do
    sender = user_fixture()
    recipient = user_fixture()

    {:ok, thread} = Messaging.ensure_direct_thread(sender.id, recipient.id)
    Phoenix.PubSub.subscribe(SocialApp.PubSub, "thread:#{thread.id}")

    assert {:ok, _message} = Messaging.send_message(sender.id, thread.id, "Bonjour")
    assert_receive {:message_sent, thread_id}
    assert thread_id == thread.id

    notifications = Notifications.list_recent(recipient.id, 10)

    assert Enum.any?(notifications, fn notification ->
             notification.type == :message_received and notification.thread_id == thread.id and
               notification.origin_user_id == sender.id
           end)
  end
end
