defmodule AndaWeb.AnswerLive.Index do
  alias Phoenix.PubSub
  use AndaWeb, :live_view

  alias Anda.Contest
  alias Anda.Submission


  @impl true
  @spec mount(any(), any(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(%{"id" => id}, session, socket) do

    secret = Map.fetch!(session, "submissions") |> Map.fetch!(id)
    submission = Submission.get_submission_by_secret(id, secret)

    submission =
      if submission == nil do
        {:ok, new_submission} = Submission.create_submission(id, secret)
        new_submission |> Anda.Repo.preload(:answers)
      else
        submission
      end
    answers_by_question_id = Enum.reduce(submission.answers, %{}, fn a, acc -> Map.put(acc, a.question_id, a) end)

    if connected?(socket) do
      PubSub.subscribe(Anda.PubSub, "submission:#{submission.id}")
      PubSub.subscribe(Anda.PubSub, "answer:#{submission.id}")
    end

    quiz = Contest.get_quiz_w_questions(id)

    {:ok,
     socket
     |> assign(:quiz, quiz)
     |> assign(:submission, submission)
     |> assign(:answers_by_question_id, answers_by_question_id)
     |> stream(:sections, quiz.sections)}
  end

  @impl true
  def handle_info({:submission_updated, submission}, socket) do
    {:noreply, assign(socket, :submission, submission)}
  end

  @impl true
  def handle_info({:answer_updated, answer}, socket) do
    send_update(AndaWeb.AnswerLive.QuestionComponent, id: "question-#{answer.question_id}", answer: answer)
    {:noreply, socket}
  end

  @impl true
  def handle_event("change_name", %{"name" => name}, socket) do
    case Submission.update_submission_name(socket.assigns.submission, name) do
      {:ok, submission} ->
        {:noreply, socket |> assign(:submission, submission)}
      _ ->
        {:noreply, socket}
    end
  end
end
