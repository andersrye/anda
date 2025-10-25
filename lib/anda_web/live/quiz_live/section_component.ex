defmodule AndaWeb.QuizLive.Section do
  use AndaWeb, :live_component
  alias Anda.Contest
  alias Anda.Contest.Question

  @impl true
  def render(assigns) do
    ~H"""
    <div class={"#{@class} bg-base-100 p-6 drop-shadow-xs"} id={@id}>
      <div class="flex">
        <h2 class="text-xl font-semibold flex-grow">{@section.title}</h2>
        <.link
          patch={~p"/admin/quiz/#{@section.quiz_id}/section/#{@section.id}/edit"}
          phx-click={JS.push_focus()}
        >
          <.button>
            endre
          </.button>
        </.link>
      </div>

      <div
        id={"section-#{@section.id}-questions"}
        phx-update="stream"
        class="divide-black divide-y-2  divide-dotted"
      >
        <div
          :for={{id, question} <- @streams.questions}
          id={id}
          class="flex divide-black divide-x-2  divide-dotted"
        >
          <div class="flex-grow py-6">
            {question.question}
            <img
              :if={!is_nil(question.media_url) && String.starts_with?(question.media_type, "image")}
              src={question.media_url}
            />
            <ul :if={!is_nil(question.alternatives)} class="list-disc ml-5">
              <li :for={alternative <- question.alternatives}>
                {alternative}
              </li>
            </ul>
          </div>
          <div class="pl-5 py-6 grid grid-cols-2 gap-2">
            <.button
              phx-click={JS.push("edit_question", target: @myself, value: %{id: question.id})}
              phx-target={@myself}
            >
              endre
            </.button>
            <.button
              phx-click={JS.push("delete_question", target: @myself, value: %{id: question.id})}
              phx-target={@myself}
            >
              slett
            </.button>
            <span>
              svar: {@answer_counts[question.id] || 0}
            </span>

            <.button
              phx-click={JS.push("score_question", target: @myself, value: %{id: question.id})}
              phx-target={@myself}
            >
              rett
            </.button>
          </div>
        </div>
      </div>
      <.button phx-click="new_question" phx-target={@myself}>
        legg til spørsmål
      </.button>
      <.modal
        :if={@edit_question != nil}
        id="edit-question-modal"
        show
        on_cancel={JS.push("cancel_edit", target: @myself)}
      >
        <.live_component
          module={AndaWeb.QuizLive.Form.QuestionForm}
          id={@quiz_id}
          title="test"
          question={@edit_question}
          edit_action={@edit_action}
          section={@section}
          on_saved={fn q -> send_update(@myself, %{question: q}) end}
        />
      </.modal>
      <.modal
        :if={@score_question != nil}
        id="score-question-modal"
        show
        on_cancel={JS.push("cancel_score", target: @myself)}
      >
        <.live_component
          module={AndaWeb.QuizLive.Form.ScoreForm}
          id={@quiz_id}
          title={"ASD"}
          question={@score_question}
        />
      </.modal>
      <.modal
        :if={@delete_question != nil}
        id="delete-question-modal"
        show
        on_cancel={JS.push("cancel_delete", target: @myself)}
      >
        Sikker?
        <.button phx-click="confirm_delete" phx-target={@myself}>Ja</.button>
        <.button phx-click="cancel_delete" phx-target={@myself}>Nei</.button>
      </.modal>
    </div>
    """
  end

  @impl true
  @spec handle_event(any(), any(), any()) :: {:noreply, any()}
  def handle_event("new_question", _value, socket) do
    {:noreply,
     socket
     |> assign(:edit_question, %Question{
       section_id: socket.assigns.section.id,
       num_answers: 1,
       alternatives: []
     })
     |> assign(:edit_action, :new_question)}
  end

  @impl true
  @spec handle_event(any(), any(), any()) :: {:noreply, any()}
  def handle_event("edit_question", %{"id" => id}, socket) do
    question = Contest.get_question!(id)

    {:noreply,
     socket
     |> assign(:edit_question, question)
     |> assign(:edit_action, :edit_question)}
  end

  @impl true
  @spec handle_event(any(), any(), any()) :: {:noreply, any()}
  def handle_event("score_question", %{"id" => id}, socket) do
    question = Contest.get_question!(id)

    {:noreply,
     socket
     |> assign(:score_question, question)
     |> assign(:edit_action, :score_question)}
  end

  @impl true
  @spec handle_event(any(), any(), any()) :: {:noreply, any()}
  def handle_event("delete_question", %{"id" => id}, socket) do
    question = Contest.get_question!(id)

    {:noreply,
     socket
     |> assign(:delete_question, question)}
  end

  @impl true
  def handle_event("cancel_edit", _value, socket) do
    {:noreply, assign(socket, :edit_question, nil)}
  end

  @impl true
  def handle_event("cancel_score", _value, socket) do
    {:noreply, assign(socket, :score_question, nil)}
  end

  @impl true
  def handle_event("cancel_delete", _value, socket) do
    {:noreply, assign(socket, :delete_question, nil)}
  end

  @impl true
  def handle_event("confirm_delete", _value, socket) do
    question = socket.assigns.delete_question
    _res = Contest.delete_question(question)

    {:noreply,
     socket
     |> assign(:delete_question, nil)
     |> stream_delete(:questions, question)}
  end

  @impl true
  def update(%{:section => section} = assigns, socket) do
    questions = Contest.list_questions(section.id)

    answer_counts =
      Contest.answer_counts(section.id)
      |> Enum.reduce(%{}, fn v, acc -> Map.put(acc, v.question_id, v.count) end)

    dbg(answer_counts)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:answer_counts, answer_counts)
     |> assign(:edit_question, nil)
     |> assign(:delete_question, nil)
     |> assign(:score_question, nil)
     |> stream(:questions, questions)}
  end

  @impl true
  def update(%{:question => question}, socket) do
    {:ok,
     socket
     |> assign(:edit_question, nil)
     |> stream_insert(:questions, question)}
  end

  @impl true
  def update(%{:new_answer => question_id}, socket) do
    counts = socket.assigns.answer_counts |> Map.update(question_id, 1, fn n -> n + 1 end)

    dbg(counts)

    {:ok,
     socket
     |> assign(:answer_counts, counts)
     # TODO: sukk!
     |> stream_insert(:questions, Contest.get_question!(question_id))}
  end
end
