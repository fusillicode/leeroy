defmodule Leeroy.Mind do
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

  def handle_event(
    %{type: "message", text: text, channel: channel} = _, slack, state
  ) do
    case Regex.scan(gif_pattern(), text) do
      []      -> {:ok, state}
      matches -> Enum.each(matches, fn(match) ->
        match |> build_gif_message |> send_message(channel, slack)
      end)
    end
    {:ok, state}
  end

  def handle_event(_, _, state), do: {:ok, state}
  def handle_info(_, _, state), do: {:ok, state}

  defp gif_pattern, do: ~r/\s+(\/gif).*?(\/|$)/

  defp build_gif_message([gif_match | [prefix | [suffix]]]) do
    gif_match_without_prefix = remove_and_trim prefix, gif_match
    suffix |> case do
      "" -> gif_match_without_prefix
      _  -> remove_and_trim suffix, gif_match_without_prefix
    end |> gif_message
  end

  defp gif_message gif_tag do
    "[#{gif_tag}] #{fetch_gif(gif_tag)}"
  end

  defp remove_and_trim(pattern, input) do
    input
    |> String.replace(pattern, "")
    |> String.trim
  end

  defp fetch_gif("") do
    "api.giphy.com/v1/gifs/random"
    |> ask_giphy
    |> extract_gif_url
  end

  defp fetch_gif(search) do
    "api.giphy.com/v1/gifs/random"
    |> ask_giphy([{"tag", search}])
    |> extract_gif_url
  end

  defp ask_giphy(api_endpoint, params \\ []) do
    {:ok, %HTTPoison.Response{body: response_body}} = HTTPoison.get(
      api_endpoint,
      [],
      params: [
        {"api_key", Application.get_env(:leeroy, :giphy_api_key)} | params
      ]
    )
    response_body
  end

  defp extract_gif_url(response_body) do
    case Poison.decode(response_body) do
      {:ok, %{"data" => %{
        "fixed_height_downsampled_url" => image_url
      }}} -> image_url
      {:ok, %{"data" => _}} -> ""
    end
  end
end
