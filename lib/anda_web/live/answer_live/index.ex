defmodule AndaWeb.AnswerLive.Index do
  alias Phoenix.PubSub
  use AndaWeb, :live_view

  alias Anda.Contest
  alias Anda.Submission

  @impl true
  @spec mount(any(), any(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(%{"quiz_id" => quiz_id} = params, session, socket) do
    submission =
      case socket.assigns.live_action do
        :edit ->
          secret = session |> Map.fetch!("submissions") |> Map.fetch!(quiz_id)
          submission = Submission.get_submission_by_secret(quiz_id, secret)

          if submission == nil do
            {:ok, new_submission} = Submission.create_submission(quiz_id, secret)
            new_submission |> Anda.Repo.preload(:answers)
          else
            submission
          end

        :view ->
          submission_id = params |> Map.get("submission_id") |> String.to_integer()
          Submission.get_submission(submission_id)
      end

    answers_by_question_id =
      Enum.reduce(submission.answers, %{}, fn a, acc ->
         Map.update(acc, a.question_id, [a], fn l -> [a | l] end)
         end)


    if connected?(socket) do
      PubSub.subscribe(Anda.PubSub, "submission:#{submission.id}")
      PubSub.subscribe(Anda.PubSub, "answer:#{submission.id}")
    end

    quiz = Contest.get_quiz_w_questions(quiz_id)


    {:ok,
     socket
     |> assign(:quiz, quiz)
     |> assign(:submission, submission)
     |> assign(:name_form, to_form(Submission.Submission.changeset(submission)))
     |> assign(:answers_by_question_id, answers_by_question_id)
     |> assign(:saved, nil)
     |> stream(:sections, quiz.sections)}
  end

  @impl true
  def handle_info({:submission_updated, submission}, socket) do
    {:noreply, assign(socket, :submission, submission)}
  end

  @impl true
  def handle_info({:answer_updated, answer}, socket) do
    send_update(AndaWeb.AnswerLive.QuestionComponent,
      id: "question-#{answer.question_id}",
      answer: answer
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("change_name", %{"name" => name}, socket)
      when socket.assigns.live_action == :edit do
    dbg(socket.assigns.live_action)

    case Submission.update_submission_name(socket.assigns.submission, name) do
      {:ok, submission} ->
        {:reply, %{hello: "world"},
         socket
         |> assign(:submission, submission)
         |> assign(:name_form, to_form(Submission.Submission.changeset(submission)))
         |> assign(:saved, Ecto.UUID.generate())}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, name_form: to_form(changeset))}
    end
  end
end
