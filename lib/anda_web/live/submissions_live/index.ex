defmodule AndaWeb.SubmissionsLive.Index do
  use AndaWeb, :live_view

  alias Anda.Submission
  alias Anda.Contest

  @impl true
  @spec mount(any(), any(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"quiz_id" => quiz_id} = params, _uri, socket) do
    quiz = Contest.get_quiz_w_question_count(quiz_id)
    submissions = Submission.get_submissions(quiz_id)
    dbg(submissions)
    submission_id = Map.get(params, "submission_id")
    tags = if socket.assigns.live_action == :add_tag, do: Submission.get_all_tags(), else: nil

    {:noreply,
     socket
     |> assign(:quiz, quiz)
     |> assign(:submission_id, submission_id)
     |> assign(:tags, tags)
     |> assign(:submissions, submissions)}
  end

  @impl true
  def handle_event("add_tag", %{"submission-id" => submission_id, "tag" => tag}, socket) do
    submission_id = String.to_integer(submission_id)
    {:ok, submission} = Submission.add_tag(submission_id, tag, socket.assigns.current_scope)
    new_submissions = socket.assigns.submissions
    |> Enum.map(fn s -> if s.id == submission.id, do: Map.put(s, :tags, submission.tags), else: s end)

    {:noreply, socket
     |> assign(:submissions, new_submissions)
     |> push_patch(to: ~p"/admin/quiz/#{socket.assigns.quiz.id}/submissions")
    }
  end

  @impl true
  def handle_event("remove_tag", %{"submission-id" => submission_id, "tag" => tag}, socket) do
    submission_id = String.to_integer(submission_id)
    {:ok, submission} = Submission.remove_tag(submission_id, tag, socket.assigns.current_scope)
    new_submissions = Enum.map(socket.assigns.submissions, fn s -> if s.id == submission.id, do: Map.put(s, :tags, submission.tags), else: s end)

    {:noreply, socket
     |> assign(:submissions, new_submissions)
     |> push_patch(to: ~p"/admin/quiz/#{socket.assigns.quiz.id}/submissions")
    }
  end
end
