defmodule AndaWeb.AnswerLive.QuestionInput do
  use AndaWeb, :live_component
  alias Anda.Submission.Answer
  alias Anda.Submission
  import AndaWeb.AnswerLive.AnswerComponents

  @impl true
  def update(%{answer_updated: answer}, socket) do
    changeset = Answer.changeset(answer)

    {:ok,
     socket
     |> assign(answer: answer)
     |> assign(:form, to_form(changeset, as: "answer"))}
  end

  @impl true
  def update(assigns, socket) do
    answer =
      assigns.answer || Answer.create(assigns.question.id, assigns.submission.id, assigns.index)

    changeset = Answer.changeset(answer)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(answer: answer)
     |> assign_new(:saved, fn -> false end)
     |> assign_new(:form, fn -> to_form(changeset, as: "answer") end)}
  end

  @impl true
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div id={@id} class={@class}>
      <div class="flex gap-2">
        <.form
          id={"form-#{@id}"}
          for={@form}
          phx-target={@myself}
          class="flex-grow"
        >
          <.radio_input
            :if={@question.type == "alternatives" && Enum.count(@question.alternatives || []) <= 6}
            id={"input-#{@id}"}
            field={@form[:text]}
            type="radiogroup"
            class="max-w-3xs"
            disabled={!@enabled}
            options={@question.alternatives}
            phx-target={@myself}
          />
          <.select_input
            :if={@question.type == "alternatives" && Enum.count(@question.alternatives || []) > 6}
            id={"input-#{@id}"}
            class="max-w-3xs"
            field={@form[:text]}
            type="select"
            disabled={!@enabled}
            phx-target={@myself}
            options={@question.alternatives}
            prompt="Velg et svar"
          />
          <.text_input
            :if={@question.type != "alternatives"}
            id={"input-#{@id}"}
            class="max-w-3xs"
            disabled={!@enabled}
            field={@form[:text]}
            phx-target={@myself}
            placeholder="Skriv et svar"
          />
          <button type="submit" class="hidden" disabled></button>
        </.form>

      </div>
    </div>
    """
  end

  @impl true
  def handle_event("submit", _, socket) when socket.assigns.action == :preview do
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", %{"answer" => %{"text" => new_answer}}, socket)
      when socket.assigns.enabled == true do
    with {:ok, answer} <-
           Submission.submit_answer(
             socket.assigns.answer,
             new_answer,
             socket.assigns.question,
             socket.assigns.submission
           ) do
      changeset = Answer.changeset(answer)

      {:reply, %{success: true},
       socket
       |> assign(
         form: to_form(changeset, as: "answer"),
         answer: answer
       )}
    else
      {:error, changeset} ->
        {:reply, %{success: false},
         socket
         |> assign(form: to_form(changeset, as: "answer"))}
    end
  end
end
