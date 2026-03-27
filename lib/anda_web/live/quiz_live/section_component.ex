defmodule AndaWeb.QuizLive.Section do
  use AndaWeb, :live_component
  alias Anda.Contest
  alias Anda.Contest.Question

  @impl true
  def render(assigns) do
    ~H"""
    <div class={"#{@class} bg-base-100 p-6 card shadow-sm"} id={@id}>
      <div class="flex border-stone-300 border-b-2 pb-4 border-dotted">
        <div class="flex-grow">
          <h2 class="text-xl font-semibold mb-2">{@section.title}</h2>
          <div>{@section.description}</div>
        </div>
        <div :if={@mode == :edit} class="flex flex-row gap-2">
          <.link
            :if={@mode == :edit}
            patch={~p"/admin/quiz/#{@section.quiz_id}/section/#{@section.id}/edit"}
            phx-click={JS.push_focus()}
          >
            <.button class="btn btn-square btn-outline btn-sm"><.icon name="hero-pencil" /></.button>
          </.link>
          <.button
            :if={@mode == :edit}
            class="btn btn-square btn-outline btn-sm"
            phx-click="move_section_up"
            phx-value-section_id={@section.id}
            phx-target={@myself}
          >
            <.icon name="hero-arrow-up" />
          </.button>
          <.button
            :if={@mode == :edit}
            class="btn btn-square btn-outline btn-sm"
            phx-click="move_section_down"
            phx-value-section_id={@section.id}
            phx-target={@myself}
          >
            <.icon name="hero-arrow-down" />
          </.button>

          <.link
            :if={@mode == :edit}
            _patch={~p"/admin/quiz/#{@section.quiz_id}/section/#{@section.id}/delete"}
            phx-click={JS.push_focus()}
          >
            <.button class="btn btn-square btn-outline btn-error btn-sm">
              <.icon name="hero-trash" />
            </.button>
          </.link>
        </div>
      </div>

      <div
        id={"section-#{@section.id}-questions"}
        phx-update="stream"
        class="divide-stone-300 divide-y-2 divide-dotted"
      >
        <div
          :for={{id, question} <- @streams.questions}
          id={id}
          class="flex -divide-stone-300 -divide-x-2  divide-dotted"
        >
          <div class="flex-grow py-6">
            <p class="whitespace-pre-line">{question.text}</p>
            <img
              :if={!is_nil(question.media_url) && String.starts_with?(question.media_type, "image")}
              class="max-h-64 my-5"
              src={question.media_url}
            />
            <ul :if={!is_nil(question.alternatives)} class="list-disc ml-5">
              <li :for={alternative <- Enum.take(question.alternatives, 6)}>
                {alternative}
              </li>
            </ul>
            <span :if={Enum.count(question.alternatives || []) > 6} class="ml-1">
              + {Enum.count(question.alternatives || []) - 6} til
            </span>
          </div>
          <div class="flex-shrink ml-5">
            <div :if={@mode == :edit} class=" py-6 grid grid-cols-1 md:grid-cols-2 gap-2">
              <.link
                patch={~p"/admin/quiz/#{@section.quiz_id}/question/#{question.id}/edit"}
                phx-click={JS.push_focus()}
              >
                <.button class="btn btn-square btn-outline btn-sm">
                  <.icon name="hero-pencil" />
                </.button>
              </.link>
              <.link
                patch={~p"/admin/quiz/#{@section.quiz_id}/question/#{question.id}/delete"}
                phx-click={JS.push_focus()}
              >
                <.button class="btn btn-square btn-outline btn-error btn-sm">
                  <.icon name="hero-trash" />
                </.button>
              </.link>
            </div>
            <div :if={@mode == :score} class=" py-6 grid grid-cols-1 md:grid-cols-2 gap-2">
              <.link
                patch={~p"/admin/quiz/#{@section.quiz_id}/scoring/#{question.id}"}
                phx-click={JS.push_focus()}
              >
                <.button class="btn btn-square btn-outline btn-sm">
                  <.icon name="hero-document-check" />
                </.button>
              </.link>
              <.link
                _patch={~p"/admin/quiz/#{@section.quiz_id}/scoring/#{question.id}"}
                phx-click={JS.push_focus()}
              >
                <.button class="btn btn-square btn-outline btn-sm">
                  <.icon name="hero-eye" />
                </.button>
              </.link>
            </div>
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
  def update(%{:deleted_question => question}, socket) do
    {:ok,
     socket
     |> stream_delete(:questions, question)}
  end
end
