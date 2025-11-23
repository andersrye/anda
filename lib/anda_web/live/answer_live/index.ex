defmodule AndaWeb.AnswerLive.Index do
  use AndaWeb, :live_view
  alias AndaWeb.Endpoint
  alias Phoenix.PubSub
  alias Anda.Contest
  alias Anda.Submission

  defp assign_defaults(assigns) do
    assigns
    |> assign(:show_copy_url, nil)
    |> assign_new(:current_scope, fn -> nil end)
  end

  defp secret_url(secret) do
    {:ok, uuid_bytes} = Ecto.UUID.dump(secret)
    Mac.encode(<<1>> <> uuid_bytes)
  end

  defp verify_secret_url(string) do
    with {:ok, <<1, uuid_bytes::binary>>} <- Mac.decode(string),
         {:ok, secret} <- Ecto.UUID.cast(uuid_bytes) do
      {:ok, secret}
    end
  end

  defp answers_by_question_id(answers) do
    Enum.reduce(answers, %{}, fn a, acc ->
      Map.update(acc, a.question_id, %{a.index => a}, &Map.put(&1, a.index, a))
    end)
  end

  defp questions_with_answers(questions, answers_by_question_id) do
    Enum.map(questions, fn q -> {q, Map.get(answers_by_question_id, q.id, %{})} end)
  end

  defp sections_with_questions_with_answers(sections, answers \\ []) do
    answers_by_question_id = answers_by_question_id(answers)

    Enum.map(sections, fn s ->
      {s, questions_with_answers(s.questions, answers_by_question_id)}
    end)
  end

  defp subscribe_to_updates(socket, quiz, submission \\ nil) do
    if connected?(socket) do
      Endpoint.subscribe("quiz:#{quiz.id}")

      if(submission) do
        PubSub.subscribe(Anda.PubSub, "answer:#{submission.id}")
        PubSub.subscribe(Anda.PubSub, "submission:#{submission.id}")
      end
    end
  end

  def mount(%{"quiz_id" => quiz_id}, _session, socket)
      when socket.assigns.live_action == :preview do
    quiz = Contest.get_quiz_w_questions(quiz_id)
    sections = sections_with_questions_with_answers(quiz.sections)
    subscribe_to_updates(socket, quiz)
    submission = %Submission.Submission{answers: []}

    {:ok,
     socket
     |> assign_defaults()
     |> assign(:quiz, quiz)
     |> assign(:submission, submission)
     |> assign(:name_form, to_form(Submission.Submission.changeset(submission)))
     |> assign(:enabled, true)
     |> assign(:sections, sections)}
  end

  def mount(%{"quiz_id" => quiz_id, "submission_id" => submission_id}, _session, socket)
      when socket.assigns.live_action == :view do
    quiz = Contest.get_quiz_w_questions(quiz_id)
    submission = Submission.get_submission(submission_id)
    answers = Submission.get_answers(submission.id)
    sections = sections_with_questions_with_answers(quiz.sections, answers)
    subscribe_to_updates(socket, quiz)

    {:ok,
     socket
     |> assign_defaults()
     |> assign(:quiz, quiz)
     |> assign(:submission, submission)
     |> assign(:name_form, to_form(Submission.Submission.changeset(submission)))
     |> assign(:enabled, false)
     |> assign(:sections, sections)}
  end

  @impl true
  def mount(%{"slug" => slug, "secret" => encoded_secret}, _session, socket)
      when socket.assigns.live_action == :edit do
    IO.puts("MOUNT secret")
    quiz = Contest.get_quiz_w_questions_by_slug(slug)

    with {:ok, decoded_secret} <- verify_secret_url(encoded_secret),
         %Submission.Submission{} = submission <-
           Submission.get_submission_by_secret(quiz.id, decoded_secret) do
      answers = Submission.get_answers(submission.id)
      sections = sections_with_questions_with_answers(quiz.sections, answers)
      subscribe_to_updates(socket, quiz, submission)

      {:ok,
       socket
       |> assign_defaults()
       |> assign(:quiz, quiz)
       |> assign(:submission, submission)
       |> assign(:name_form, to_form(Submission.Submission.changeset(submission)))
       |> assign(:enabled, quiz.mode == "open")
       |> assign(:sections, sections)}
    else
      # TODO: den feilhåndteringa her er rotete as...
      _ ->
        sections = sections_with_questions_with_answers(quiz.sections)
        submission = %Submission.Submission{}

        {:ok,
         socket
         |> assign_defaults()
         |> assign(:quiz, quiz)
         |> assign(:submission, submission)
         |> assign(:name_form, to_form(Submission.Submission.changeset(submission)))
         |> assign(:enabled, false)
         |> assign(:sections, sections)
         |> put_flash(:error, "Oops, fant ikke besvarelsen!")}
    end
  end

  @impl true
  def mount(%{"slug" => slug}, session, socket) when socket.assigns.live_action == :edit do
    quiz = Contest.get_quiz_w_questions_by_slug(slug)
    secret = session |> Map.fetch!("submissions") |> Map.fetch!(quiz.id)
    submission = Submission.get_submission_by_secret(quiz.id, secret)

    submission =
      if submission == nil do
        {:ok, new_submission} = Submission.create_submission(quiz.id, secret)
        new_submission
      else
        submission
      end

    answers = Submission.get_answers(submission.id)

    sections = sections_with_questions_with_answers(quiz.sections, answers)

    subscribe_to_updates(socket, quiz, submission)

    {:ok,
     socket
     |> assign_defaults()
     |> assign(:quiz, quiz)
     |> assign(:submission, submission)
     |> assign(:name_form, to_form(Submission.Submission.changeset(submission)))
     |> assign(:enabled, quiz.mode in ["open"])
     |> assign(:sections, sections)}
  end

  @impl true
  def handle_params(_, uri, socket) do
    {:noreply, socket |> assign(current_uri: uri)}
  end

  @impl true
  def handle_event("change_name", _, socket)
      when socket.assigns.live_action == :preview do
    {:noreply, socket}
  end

  @impl true
  def handle_event("change_name", %{"name" => name}, socket)
      when socket.assigns.live_action == :edit and socket.assigns.quiz.mode in ["open"] do
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

  def handle_event("show_url", _, socket) do
    encoded_secret = secret_url(socket.assigns.submission.secret)
    url = URI.parse(socket.assigns.current_uri) |> Map.put(:query, "secret=#{encoded_secret}") |> URI.to_string()
    {:noreply, socket |> assign(:show_copy_url, url)}

  end

  def handle_event("hide_url", _, socket) do
    {:noreply, socket |> assign(:show_copy_url, nil)}
  end

  @impl true
  def handle_info(%{event: "quiz_updated", payload: quiz}, socket) do
    enabled = socket.assigns.live_action in [:edit, :preview] && quiz.mode in ["open"]

    {:noreply, socket |> assign(quiz: quiz, enabled: enabled)}
  end

  @impl true
  def handle_info({:submission_updated, submission}, socket) do
    IO.puts("handle_info submission_updated #{submission.name}")

    {:noreply,
     socket
     |> assign(:submission, submission)
     |> assign(:name_form, to_form(Submission.Submission.changeset(submission)))}
  end

  @impl true
  def handle_info({:answer_updated, answer}, socket) do
    send_update(AndaWeb.AnswerLive.QuestionComponent,
      id: "question-#{answer.question_id}-#{answer.index}",
      answer_updated: answer
    )

    {:noreply, socket}
  end
end
