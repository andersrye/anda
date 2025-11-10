defmodule AndaWeb.LeaderboardLive.Index do
  alias Anda.Contest
  use AndaWeb, :live_view

  alias Anda.Submission

  @impl true
  @spec mount(any(), any(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"quiz_id" => quiz_id} = params, _uri, socket) do
    quiz = Contest.get_quiz!(quiz_id)
    tags = Submission.get_all_tags()
    selected_tag = Map.get(params, "tag")

    leaderboard =
      Submission.get_leaderboard(quiz_id, selected_tag)
      |> Enum.with_index()
      |> Enum.map(fn {{_id, name, score}, index} -> {index + 1, name, score || 0} end)

    dbg(leaderboard)

    {:noreply,
     socket
     |> assign(:quiz, quiz)
     |> assign(:tags, tags)
     |> assign(:selected_tag, selected_tag)
     |> assign(:leaderboard, leaderboard)}
  end

  def handle_event("change_tag", %{"tag" => tag}, socket) do
    url = if tag == "" do
      ~p"/admin/quiz/#{socket.assigns.quiz.id}/leaderboard"
    else
      ~p"/admin/quiz/#{socket.assigns.quiz.id}/leaderboard?tag=#{tag}"
    end
    {:noreply, socket |> push_patch(to: url)}
  end
end
