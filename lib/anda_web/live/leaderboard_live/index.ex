defmodule AndaWeb.LeaderboardLive.Index do
  alias Phoenix.PubSub
  use AndaWeb, :live_view

  alias Anda.Contest
  alias Anda.Submission


  @impl true
  @spec mount(any(), any(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(%{"id" => id}, session, socket) do
    leaderboard = Submission.get_leaderboard(id)
    |> Enum.with_index()
    |> Enum.map(fn {{_id, name, score}, index} -> {index+1, name, score}end)
    dbg(leaderboard)

    {:ok,socket |> assign(:leaderboard, leaderboard)}
  end
end
