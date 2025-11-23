defmodule SubmissionPlug do
  alias Anda.Contest
  def init([]), do: false

  def call(%{path_params: %{"slug" => slug}} = conn, _opts) do
    quiz_id = Contest.get_quiz_id_from_slug(slug)
    submissions_map =
      Plug.Conn.fetch_cookies(conn, signed: ~w"submissions")
      |> Plug.Conn.get_cookies()
      |> Map.get("submissions", %{})
      |> Map.put_new(quiz_id, Ecto.UUID.generate())

    conn
    |> Plug.Conn.put_session(:submissions, submissions_map)
    |> Plug.Conn.put_resp_cookie("submissions", submissions_map, sign: true, max_age: 34_560_000)
  end
end
