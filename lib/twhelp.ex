defmodule Twhelp do
  @twilio_api_accounts_endpoint "https://api.twilio.com/2010-04-01/Accounts/"
  @twilio_errors_endpoint "https://www.twilio.com/docs/api/errors/"

  @doc """
  Primary entry point
  """
  def main(args \\ []) do
    creds = handle_creds()
    {cmd, val} = handle_args(args)

    case cmd do
      "acct" ->
        convert_account_sid(creds, val)

      "code" ->
        get_error_code(creds, val)

      _ ->
        IO.puts(red("ERROR: ") <> "Unknown cmd '#{cmd}'")
        System.halt(1)
    end
  end

  @doc """
  Attempt to fetch required env vars; exit 1 if env vars not set
  """
  def handle_creds do
    twilio_account_sid = System.get_env("TWILIO_ACCOUNT_SID")
    twilio_auth_token = System.get_env("TWILIO_AUTH_TOKEN")

    # TODO: What's an idiomatic way to dry this up?
    if twilio_account_sid == nil do
      IO.puts(red("ERROR: ") <> "'TWILIO_ACCOUNT_SID' is undefined")
      System.halt(1)
    end

    if twilio_auth_token == nil do
      IO.puts(red("ERROR: ") <> "'TWILIO_AUTH_TOKEN' is undefined")
      System.halt(1)
    end

    {twilio_account_sid, twilio_auth_token}
  end

  defp red(text) do
    IO.ANSI.red() <> text <> IO.ANSI.reset()
  end

  defp yellow(text) do
    IO.ANSI.yellow() <> text <> IO.ANSI.reset()
  end

  @doc """
  Fetch required args; exit 1 if args not provided
  """
  def handle_args(args) do
    if length(args) !== 2 do
      IO.puts(yellow("Usage: ") <> "./twhelp.exs acct|code value")
      System.halt(1)
    end

    {Enum.fetch!(args, 0), Enum.fetch!(args, 1)}
  end

  @doc """
  Use the Twilio API to fetch and display subaccount metadata.
  """
  def convert_account_sid({sid, token}, account_sid) do
    url = @twilio_api_accounts_endpoint <> account_sid <> ".json"
    options = [hackney: [basic_auth: {sid, token}]]

    case HTTPoison.get(url, [], options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Enum.each(Poison.decode!(body), fn {k, v} ->
          if k == "subresource_uris" do
            :ok
          else
            IO.puts(yellow("#{inspect(k)}: ") <> "#{inspect(v)}")
          end
        end)

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        IO.puts(
          red("ERROR: ") <>
            "Non-200 (#{status_code}) response from twilio\n\nBODY:\n#{inspect(body)}"
        )

        System.halt(1)

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts(red("ERROR: ") <> "Unable to complete lookup: #{reason}")
        System.halt(1)
    end
  end

  @doc """
  This function fetches the given Twilio error page and attempts to parse it for
  short and full description info.

  NOTE: Twilio documents 100s of error codes but sadly they are not behind an
  API and instead we have to fetch and parse HTML :(
  """
  def get_error_code({sid, token}, error_code) do
    url = @twilio_errors_endpoint <> error_code
    options = [hackney: [basic_auth: {sid, token}]]

    case HTTPoison.get(url, [], options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        IO.puts(yellow("URL: ") <> "#{url}")
        parse_error_code(body)

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        IO.puts(
          red("ERROR: ") <>
            "Non-200 (#{status_code}) response from twilio\n\nBODY:\n#{inspect(body)}"
        )

        System.halt(1)

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts(red("ERROR: ") <> "Unable to complete lookup: #{reason}")
        System.halt(1)
    end
  end

  defp parse_error_code(body) do
    data = Floki.find(body, "div.markdown")

    # Example: [{"div", ["class", "markdown"], [{"children"}]}]
    data
    |> Enum.fetch!(0)
    |> elem(2)
    |> Enum.each(fn x ->
      case elem(x, 0) do
        "h3" ->
          short_description =
            elem(x, 2)
            |> Enum.fetch!(0)
            |> elem(2)
            |> Enum.fetch!(0)

          IO.puts(yellow("Short description: ") <> short_description)

        "p" ->
          # We know this is the title/short description
          full_description =
            elem(x, 2)
            |> Enum.fetch!(0)

          IO.puts(yellow("Full description: ") <> full_description)

        _ ->
          nil
      end
    end)
  end
end
