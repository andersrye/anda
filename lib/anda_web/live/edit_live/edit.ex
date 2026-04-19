defmodule AndaWeb.EditLive.Edit do
  alias Anda.Contest.QuizUtils
  alias AndaWeb.Endpoint
  use AndaWeb, :live_view
  alias Anda.Contest
  alias AndaWeb.EditLive.Form

  def section_edit_controls(assigns) do
    ~H"""
    <div class="flex flex-row gap-2">
      <.link
        patch={~p"/admin/quiz/#{@section.quiz_id}/edit/section/#{@section.id}"}
        phx-click={JS.push_focus()}
      >
        <.button class="btn btn-square btn-outline btn-sm"><.icon name="hero-pencil" /></.button>
      </.link>
      <.button
        class="btn btn-square btn-outline btn-sm"
        phx-click="move_section_up"
        phx-value-section_id={@section.id}
      >
        <.icon name="hero-arrow-up" />
      </.button>
      <.button
        class="btn btn-square btn-outline btn-sm"
        phx-click="move_section_down"
        phx-value-section_id={@section.id}
      >
        <.icon name="hero-arrow-down" />
      </.button>

      <.link
        patch={~p"/admin/quiz/#{@section.quiz_id}/edit/section/#{@section.id}/delete"}
        phx-click={JS.push_focus()}
      >
        <.button class="btn btn-square btn-outline btn-error btn-sm">
          <.icon name="hero-trash" />
        </.button>
      </.link>
    </div>
    """
  end

  def question_edit_controls(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-4 gap-2">
      <.link
        patch={~p"/admin/quiz/#{@section.quiz_id}/edit/question/#{@question.id}"}
        phx-click={JS.push_focus()}
      >
        <.button class="btn btn-square btn-outline btn-sm">
          <.icon name="hero-pencil" />
        </.button>
      </.link>
      <.button
        class="btn btn-square btn-outline btn-sm"
        phx-click="move_question_up"
        phx-value-question_id={@question.id}
      >
        <.icon name="hero-arrow-up" />
      </.button>
      <.button
        class="btn btn-square btn-outline btn-sm"
        phx-click="move_question_down"
        phx-value-question_id={@question.id}
      >
        <.icon name="hero-arrow-down" />
      </.button>
      <.link
        patch={~p"/admin/quiz/#{@section.quiz_id}/edit/question/#{@question.id}/delete"}
        phx-click={JS.push_focus()}
      >
        <.button class="btn btn-square btn-outline btn-error btn-sm">
          <.icon name="hero-trash" />
        </.button>
      </.link>
    </div>
    """
  end

  def question_details(assigns) do
    type_text =
      case assigns.question.type do
        "alternatives" ->
          count = Enum.count(assigns.question.alternatives || [], &(!String.starts_with?(&1, "--")))
          "#{count} alternativer"
        "text" -> "Fritekst"
        "number" -> "Tall"
        "football-score" -> "Fotball-resultat"
        _ -> "??"
      end

    assigns = assign(assigns, type_text: type_text)

    ~H"""
    <div class="mt-4">
      <div class="badge badge-sm badge-soft">
        {@type_text}
      </div>
      <div :if={@question.num_answers > 1} class="badge badge-sm badge-soft">
        {"#{@question.num_answers} svar"}
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"quiz_id" => id}, _session, socket) do
    if connected?(socket) do
      Endpoint.subscribe("quiz:#{id}:section")
      Endpoint.subscribe("quiz:#{id}:question")
    end

    quiz =
      Contest.get_quiz_w_questions(id, socket.assigns.current_scope)
      |> QuizUtils.calculate_ranks()

    {
      :ok,
      socket
      |> assign(:page_title, quiz.title)
      |> assign(:quiz, quiz)
    }
  end

  @impl true
  def handle_params(params, _, socket) do
    parsed_params =
      for {k, v} when k in ["quiz_id", "section_id", "question_id"] <- params, into: %{} do
        {String.to_atom(k), String.to_integer(v)}
      end

    {:noreply, assign(socket, parsed_params)}
  end

  @impl true
  def handle_info({Form.QuizForm, {:saved, quiz}}, socket) do
    quiz = QuizUtils.update_quiz(socket.assigns.quiz, quiz)
    {:noreply, assign(socket, quiz: quiz)}
  end

  @impl true
  def handle_info({Form.SectionForm, {:created, section}}, socket) do
    section = struct(section, questions: [])
    quiz = QuizUtils.add_section(socket.assigns.quiz, section)
    {:noreply, assign(socket, quiz: quiz)}
  end

  @impl true
  def handle_info({Form.SectionForm, {:updated, section}}, socket) do
    quiz = QuizUtils.update_section(socket.assigns.quiz, section)
    {:noreply, assign(socket, quiz: quiz)}
  end

  @impl true
  def handle_info({Form.DeleteSectionForm, {:deleted, section}}, socket) do
    quiz = QuizUtils.remove_section(socket.assigns.quiz, section)
    {:noreply, assign(socket, quiz: quiz)}
  end

  @impl true
  def handle_info({Form.QuestionForm, {:created, question}}, socket) do
    quiz =
      QuizUtils.add_question(socket.assigns.quiz, question)
      |> QuizUtils.calculate_ranks()

    {:noreply, assign(socket, quiz: quiz)}
  end

  @impl true
  def handle_info({Form.QuestionForm, {:updated, question}}, socket) do
    quiz = QuizUtils.update_question(socket.assigns.quiz, question)
    {:noreply, assign(socket, quiz: quiz)}
  end

  @impl true
  def handle_info({Form.DeleteQuestionForm, {:deleted, question}}, socket) do
    quiz =
      QuizUtils.remove_question(socket.assigns.quiz, question)
      |> QuizUtils.calculate_ranks()

    {:noreply, assign(socket, quiz: quiz)}
  end

  @impl true
  def handle_info(%{event: "sections_updated", payload: sections}, socket) do
    quiz =
      QuizUtils.update_sections(socket.assigns.quiz, sections)
      |> QuizUtils.calculate_ranks()

    {:noreply, assign(socket, quiz: quiz)}
  end

  @impl true
  def handle_info(%{event: "questions_updated", payload: questions}, socket) do
    quiz =
      QuizUtils.update_questions(socket.assigns.quiz, questions)
      |> QuizUtils.calculate_ranks()

    {:noreply, assign(socket, quiz: quiz)}
  end

  @impl true
  def handle_event("move_section_up", %{"section_id" => section_id}, socket) do
    section = Contest.get_section!(section_id, socket.assigns.current_scope)
    Contest.move_section_up(section)
    {:noreply, socket}
  end

  @impl true
  def handle_event("move_section_down", %{"section_id" => section_id}, socket) do
    section = Contest.get_section!(section_id, socket.assigns.current_scope)
    Contest.move_section_down(section)
    {:noreply, socket}
  end

  @impl true
  def handle_event("move_question_up", %{"question_id" => question_id}, socket) do
    question = Contest.get_question!(question_id, socket.assigns.current_scope)
    Contest.move_question_up(question)
    {:noreply, socket}
  end

  @impl true
  def handle_event("move_question_down", %{"question_id" => question_id}, socket) do
    question = Contest.get_question!(question_id, socket.assigns.current_scope)
    Contest.move_question_down(question)
    {:noreply, socket}
  end
end
