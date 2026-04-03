defmodule AndaWeb.QuizLive.Section do
  use AndaWeb, :live_component
  alias Anda.Contest

  def section_edit_controls(assigns) do
    ~H"""
    <div class="flex flex-row gap-2">
      <.link
        patch={~p"/admin/quiz/#{@section.quiz_id}/section/#{@section.id}/edit"}
        phx-click={JS.push_focus()}
      >
        <.button class="btn btn-square btn-outline btn-sm"><.icon name="hero-pencil" /></.button>
      </.link>
      <.button
        class="btn btn-square btn-outline btn-sm"
        phx-click="move_section_up"
        phx-value-section_id={@section.id}
        phx-target={@myself}
      >
        <.icon name="hero-arrow-up" />
      </.button>
      <.button
        class="btn btn-square btn-outline btn-sm"
        phx-click="move_section_down"
        phx-value-section_id={@section.id}
        phx-target={@myself}
      >
        <.icon name="hero-arrow-down" />
      </.button>

      <.link
        _patch={~p"/admin/quiz/#{@section.quiz_id}/section/#{@section.id}/delete"}
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
    <div class=" py-6 grid grid-cols-1 md:grid-cols-4 gap-2">
      <.link
        patch={~p"/admin/quiz/#{@section.quiz_id}/question/#{@question.id}/edit"}
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
        phx-target={@myself}
      >
        <.icon name="hero-arrow-up" />
      </.button>
      <.button
        class="btn btn-square btn-outline btn-sm"
        phx-click="move_question_down"
        phx-value-question_id={@question.id}
        phx-target={@myself}
      >
        <.icon name="hero-arrow-down" />
      </.button>
      <.link
        patch={~p"/admin/quiz/#{@section.quiz_id}/question/#{@question.id}/delete"}
        phx-click={JS.push_focus()}
      >
        <.button class="btn btn-square btn-outline btn-error btn-sm">
          <.icon name="hero-trash" />
        </.button>
      </.link>
    </div>
    """
  end

  def scoring_controls(assigns) do
    ~H"""
    <div class=" py-6 grid grid-cols-1 md:grid-cols-2 gap-2">
      <.link
        patch={~p"/admin/quiz/#{@section.quiz_id}/scoring/#{@question.id}"}
        phx-click={JS.push_focus()}
      >
        <.button class="btn btn-square btn-outline btn-sm">
          <.icon name="hero-document-check" />
        </.button>
      </.link>
      <.link
        _patch={~p"/admin/quiz/#{@section.quiz_id}/scoring/#{@question.id}"}
        phx-click={JS.push_focus()}
      >
        <.button class="btn btn-square btn-outline btn-sm">
          <.icon name="hero-eye" />
        </.button>
      </.link>
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
  def render(assigns) do
    ~H"""
    <div class={"#{@class} bg-base-100 p-6 card shadow-sm"} id={@id}>
      <div class="flex border-stone-300 border-b-2 pb-4 border-dotted">
        <div class="flex-grow">
          <h2 class="text-xl font-semibold mb-2">{@section.title}</h2>
          <div>{@section.description}</div>
        </div>
        <.section_edit_controls :if={@mode == :edit} section={@section} myself={@myself} />
      </div>

      <div
        id={"section-#{@section.id}-questions"}
        phx-update="stream"
        class="divide-stone-300 divide-y-2 divide-dotted"
      >
        <div
          :for={{id, question} <- @streams.questions}
          id={id}
          class="flex"
        >
          <div class="flex-grow py-6">
            <p class="whitespace-pre-line">{question.text}</p>
            <.media_view
              :if={question.media_url}
              id={"media-#{question.id}"}
              class="my-5"
              src={question.media_url}
              type={question.media_type}
              aspect_ratio={question.media_aspect_ratio}
            />
            <.question_details question={question} />
          </div>
          <div class="flex-shrink ml-5">
            <.question_edit_controls
              :if={@mode == :edit}
              question={question}
              section={@section}
              myself={@myself}
            />
            <.scoring_controls
              :if={@mode == :score}
              question={question}
              section={@section}
            />
          </div>
        </div>
      </div>
      <.link
        :if={@mode == :edit}
        patch={~p"/admin/quiz/#{@section.quiz_id}/question/new?section_id=#{@section.id}"}
        phx-click={JS.push_focus()}
      >
        <.button class="btn btn-outline mt-2"><.icon name="hero-plus" />Legg til spørsmål</.button>
      </.link>
    </div>
    """
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

  @impl true
  def update(%{:section => section} = assigns, socket) do
    questions = Contest.list_questions(section.id, assigns.current_scope)

    {:ok,
     socket
     |> assign(assigns)
     |> stream(:questions, questions)}
  end

  @impl true
  def update(%{:updated_question => question}, socket) do
    {:ok,
     socket
     |> stream_insert(:questions, question)}
  end

  @impl true
  def update(%{:updated_questions => questions}, socket) do
    {:ok,
     socket
     |> stream(:questions, questions, reset: true)}
  end

  @impl true
  def update(%{:deleted_question => question}, socket) do
    {:ok,
     socket
     |> stream_delete(:questions, question)}
  end
end
