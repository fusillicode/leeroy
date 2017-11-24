defmodule Leeroy.Bot do
  @moduledoc false

  use Slack
  alias Slack.Bot

  def start_link do
    Bot.start_link(
      __MODULE__,
      [],
      Application.get_env(:leeroy, :slack_api_token)
    )
  end

  def handle_connect(slack, state) do
    IO.puts "Connected as #{slack.me.name}"
    {:ok, state}
  end

  def handle_event(message = %{type: "message"}, slack, state) do
    message |> IO.puts
    {:ok, state}
  end

  def handle_event(_, _, state), do: {:ok, state}

  def handle_info({:message, text, channel}, slack, state) do
    IO.puts "Sending your message, captain!"

    send_message(text, channel, slack)

    {:ok, state}
  end

  def handle_info(_, _, state), do: {:ok, state}
end
