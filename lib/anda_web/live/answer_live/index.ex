defmodule AndaWeb.AnswerLive.Index do
  alias Anda.Contest.QuizUtils
  use AndaWeb, :live_view
  use Phoenix.Component
  alias AndaWeb.Endpoint
  alias Phoenix.PubSub
  alias Anda.Contest
  alias Anda.Submission
  import AndaWeb.AnswerLive.AnswerComponents

  defp assign_defaults(socket) do
    current_tab =
      case socket.assigns.live_action do
        :preview -> :preview
        :view_submissions -> :submissions
        :view_leaderboard -> :leaderboard
        _ -> nil
      end

    socket
    |> assign(:show_copy_url, nil)
    |> assign(:current_tab, current_tab)
    |> assign_new(:current_scope, fn -> nil end)
  end

  defp secret_url(secret) do
    with {:ok, bytes} <- Ecto.UUID.dump(secret) do
      Mac.encode(<<1>> <> bytes)
    else
      :error ->
        {:ok, bytes} = Base.decode64(secret)
        Mac.encode(<<2>> <> bytes)
    end
  end

  defp verify_secret_url(string) do
    case Mac.decode(string) do
      {:ok, <<1, uuid_bytes::binary>>} -> Ecto.UUID.cast(uuid_bytes)
      {:ok, <<2, hash_bytes::binary>>} -> {:ok, Base.encode64(hash_bytes)}
    end
  end

  defp subscribe_to_updates(socket, quiz, submission \\ nil) do
    if connected?(socket) do
      Endpoint.subscribe("quiz:#{quiz.id}")

      if(submission) do
        Endpoint.subscribe("submission:#{submission.id}")
      end
    end
  end

  defp get_secret(session, quiz_id) do
    legacy_secret = session |> Map.get("submissions", %{}) |> Map.get(quiz_id)

    if(legacy_secret) do
      legacy_secret
    else
      salt = Map.fetch!(session, "secret_salt")
      :crypto.hash(:sha256, Base.decode64!(salt) <> <<quiz_id::32>>) |> Base.encode64()
    end
  end

  # edit -> forhåndsvisning
  def mount(%{"quiz_id" => quiz_id}, _session, socket)
      when socket.assigns.live_action == :preview do
    quiz = Contest.get_quiz_w_questions_and_empty_answers(quiz_id, socket.assigns.current_scope)

    subscribe_to_updates(socket, quiz)
    submission = %Submission.Submission{answers: []}

    {:ok,
     socket
     |> assign_defaults()
     |> assign(:quiz, quiz)
     |> assign(:submission, submission)
     |> assign(:name_form, to_form(Submission.Submission.changeset(submission)))
     |> assign(:enabled, true)}
  end

  # edit -> vis besvarelse
  def mount(%{"quiz_id" => quiz_id, "submission_id" => submission_id}, _session, socket)
      when socket.assigns.live_action in [:view_submissions, :view_leaderboard] do
    submission = Submission.get_submission(quiz_id, submission_id)
    quiz = Contest.get_quiz_w_questions_and_answers(quiz_id, submission_id)
    subscribe_to_updates(socket, quiz)

    {:ok,
     socket
     |> assign_defaults()
     |> assign(:quiz, quiz)
     |> assign(:submission, submission)
     |> assign(:name_form, to_form(Submission.Submission.changeset(submission)))
     |> assign(:enabled, false)}
  end

  # innsending via secret
  @impl true
  def mount(%{"slug" => slug, "secret" => encoded_secret}, _session, socket)
      when socket.assigns.live_action == :edit do
    quiz_id = Contest.get_quiz_id_from_slug(slug)

    with {:ok, decoded_secret} <- verify_secret_url(encoded_secret),
         %Submission.Submission{} = submission <-
           Submission.get_submission_by_secret(quiz_id, decoded_secret) do
      quiz = Contest.get_quiz_w_questions_and_answers(quiz_id, submission.id)

      subscribe_to_updates(socket, quiz, submission)

      {:ok,
       socket
       |> assign_defaults()
       |> assign(:quiz, quiz)
       |> assign(:page_title, quiz.title)
       |> assign(:submission, submission)
       |> assign(:name_form, to_form(Submission.Submission.changeset(submission)))
       |> assign(:enabled, quiz.mode == "open")}
    end
  end

  # se annens innsending
  @impl true
  def mount(%{"slug" => slug, "name" => name}, _session, socket)
      when socket.assigns.live_action == :view_public do
    quiz_id = Contest.get_quiz_id_from_slug(slug)
    submission = Submission.get_submission_by_name(quiz_id, name)
    quiz = Contest.get_quiz_w_questions_and_answers(quiz_id, submission.id)

    subscribe_to_updates(socket, quiz, submission)

    {:ok,
     socket
     |> assign_defaults()
     |> assign(:quiz, quiz)
     |> assign(:page_title, quiz.title)
     |> assign(:submission, submission)
     |> assign(:name_form, to_form(Submission.Submission.changeset(submission)))
     |> assign(:enabled, false)}
  end

  # innsending via cookie
  @impl true
  def mount(%{"slug" => slug}, session, socket) when socket.assigns.live_action == :edit do
    quiz_id = Contest.get_quiz_id_from_slug(slug)
    secret = get_secret(session, quiz_id)
    submission = Submission.get_or_create_submission(quiz_id, secret)

    quiz =
      Contest.get_quiz_w_questions_and_answers(quiz_id, submission.id)
      |> QuizUtils.calculate_ranks()

    subscribe_to_updates(socket, quiz, submission)

    {:ok,
     socket
     |> assign_defaults()
     |> assign(:quiz, quiz)
     |> assign(:page_title, quiz.title)
     |> assign(:submission, submission)
     |> assign(:name_form, to_form(Submission.Submission.changeset(submission)))
     |> assign(:enabled, quiz.mode == "open")}
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
        {:reply, %{success: true},
         socket
         |> assign(:submission, submission)
         |> assign(:name_form, to_form(Submission.Submission.changeset(submission)))
         |> assign(:saved, Ecto.UUID.generate())}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:reply, %{success: false}, assign(socket, name_form: to_form(changeset))}
    end
  end

  def handle_event("show_url", _, socket) do
    encoded_secret = secret_url(socket.assigns.submission.secret)

    url =
      URI.parse(socket.assigns.current_uri)
      |> Map.put(:path, ~p"/quiz/#{socket.assigns.quiz.slug}")
      |> Map.put(:query, "secret=#{encoded_secret}")
      |> Map.put(:fragment, nil)
      |> URI.to_string()

    {:noreply, socket |> assign(:show_copy_url, url)}
  end

  def handle_event("hide_url", _, socket) do
    {:noreply, socket |> assign(:show_copy_url, nil)}
  end

  @impl true
  def handle_info(%{event: "quiz_updated", payload: quiz}, socket) do
    enabled = socket.assigns.live_action in [:edit, :preview] && quiz.mode in ["open"]
    quiz = QuizUtils.update_quiz(socket.assigns.quiz, quiz)

    {:noreply, socket |> assign(quiz: quiz, enabled: enabled)}
  end

  @impl true
  def handle_info(%{event: "submission_updated", payload: submission}, socket) do
    {:noreply,
     socket
     |> assign(:submission, submission)
     |> assign(:name_form, to_form(Submission.Submission.changeset(submission)))}
  end

  @impl true
  def handle_info(%{event: "answer_updated", payload: answer}, socket) do
    quiz = QuizUtils.update_answer(socket.assigns.quiz, answer)

    {:noreply, assign(socket, quiz: quiz)}
  end
end
