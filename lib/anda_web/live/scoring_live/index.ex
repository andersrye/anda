defmodule AndaWeb.ScoringLive.Index do
alias Anda.Contest.QuizUtils
  use AndaWeb, :live_view
  alias Anda.Contest
  alias AndaWeb.ScoringLive.Form

  def scoring_controls(assigns) do
    has_been_scored = assigns.question.scored_answer_count > 0
    fully_scored = assigns.question.scored_answer_count == assigns.question.total_answer_count
    assigns = assign(assigns, has_been_scored: has_been_scored, fully_scored: fully_scored)

    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-1 gap-2 mb-2">
      <.link
        patch={~p"/admin/quiz/#{@section.quiz_id}/scoring/question/#{@question.id}/answers"}
        phx-click={JS.push_focus()}
      >
        <.button class="btn btn-outline btn-sm">
          <.icon name="hero-inbox" />
          {@question.total_answer_count}
        </.button>
      </.link>
      <.link
        patch={~p"/admin/quiz/#{@section.quiz_id}/scoring/question/#{@question.id}"}
        phx-click={JS.push_focus()}
      >
        <.button class="btn btn-outline btn-sm">
          <.icon name="hero-document-check" />
          {@question.scored_answer_count}
        </.button>
      </.link>
      <div class="flex flex-col place-items-center">
        <.icon
          :if={@has_been_scored && @fully_scored}
          class="size-6 bg-green-500"
          name="hero-check-circle"
        />
        <.icon
          :if={@has_been_scored && !@fully_scored}
          class="size-6 bg-yellow-500"
          name="hero-exclamation-triangle-solid"
        />
      </div>
    </div>
    """
  end

  def question_details(assigns) do
    type_text =
      case assigns.question.type do
        "alternatives" -> "#{Enum.count(assigns.question.alternatives)} alternativer"
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
    quiz = Contest.get_quiz_w_questions_w_answer_stats(id, socket.assigns.current_scope)

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
  def handle_info({Form.ScoreForm, {:scored, question, num_scored}}, socket) do
    quiz = QuizUtils.update_question_scored_count(socket.assigns.quiz, question, num_scored)
    {:noreply, assign(socket, quiz: quiz)}
  end
end
