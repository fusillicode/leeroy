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

  def handle_event(%{
    type: "message",
    text: message_text,
    channel: channel} = _, slack, state
  ) do
    case Regex.scan(gif_pattern(), message_text) do
      []          -> {:ok, state}
      gif_matches -> message_text
        |> giphily_message(gif_matches)
        |> send_message(channel, slack)
    end
    {:ok, state}
  end

  def handle_event(_, _, state), do: {:ok, state}
  def handle_info(_, _, state), do: {:ok, state}

  def gif_pattern, do: ~r/(\/g).*?(\/|$)/

  def giphily_message message_text, gif_matches do
    gif_matches
    |> Enum.reduce(message_text, fn([gif_match | [start_pattern | [end_pattern]]], acc) ->
      match_without_prefix = gif_match
      |> String.replace(start_pattern, "")
      |> String.trim
      case end_pattern do
        "" -> match_without_prefix
        _  -> match_without_prefix
          |> String.replace(end_pattern, "")
          |> String.trim
      end |> (&(String.replace(acc, gif_match, fetch_gif(&1)))).()
    end)
  end

  defp fetch_gif("") do
    {:ok, response} = HTTPoison.get(
      "api.giphy.com/v1/gifs/random",
      [],
      params: [
        {"api_key", Application.get_env(:leeroy, :giphy_api_key)}
      ]
    )
    case Poison.decode(response.body) do
      {:ok, %{"data" => [%{
        "images" => %{"fixed_height_downsampled" => %{"url" => image_url}}
      }]}} -> image_url
      {:ok, %{"data" => []}} -> ""
    end
  end

  defp fetch_gif(search) do
    {:ok, response} = HTTPoison.get(
      "api.giphy.com/v1/gifs/search",
      [],
      params: [
        {"api_key", Application.get_env(:leeroy, :giphy_api_key)},
        {"q", search},
        {"limit", 1}
      ]
    )
    case Poison.decode(response.body) do
      {:ok, %{"data" => [%{
        "images" => %{"fixed_height_downsampled" => %{"url" => image_url}}
      }]}} -> image_url
      {:ok, %{"data" => []}} -> ""
    end
  end
end
