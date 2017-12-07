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
        match
        |> extract_gif_tag
        |> fetch_gif_url
        |> build_message
        |> send_message(channel, slack)
      end)
    end
    {:ok, state}
  end

  def handle_event(_, _, state), do: {:ok, state}
  def handle_info(_, _, state), do: {:ok, state}

  defp gif_pattern, do: ~r/\s+(\/gif).*?(\/|$)/

  defp extract_gif_tag([gif_match | [prefix | [""]]]) do
    prefix |> remove_and_trim(gif_match)
  end
  defp extract_gif_tag([gif_match | [prefix | [suffix]]]) do
    [gif_match | [prefix | [""]]]
    |> extract_gif_tag
    |> (&(remove_and_trim(suffix, &1))).()
  end

  defp remove_and_trim(pattern, input) do
    input |> String.replace(pattern, "") |> String.trim
  end

  defp fetch_gif_url(tag \\ "") do
    tag
    |> build_search_params
    |> search_gif
    |> extract_gif_url
    |> gif_url_and_tag(tag)
  end

  defp build_search_params("") , do: []
  defp build_search_params(tag) , do: [{"tag", tag}]

  defp search_gif(params \\ [], api_endpoint \\ "api.giphy.com/v1/gifs/random") do
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

  defp gif_url_and_tag(url, tag) do
    {url, tag}
  end

  defp build_message({gif_url, gif_tag}) do
    "[#{gif_tag}] #{gif_url}"
  end
end
