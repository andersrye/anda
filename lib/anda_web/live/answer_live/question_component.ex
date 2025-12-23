defmodule AndaWeb.AnswerLive.QuestionComponent do
  alias Anda.Submission.Answer
  use AndaWeb, :live_component
  alias Anda.Submission

  defp score(assigns) do
    ~H"""
    <div class="font-mono">
      <div
        :if={@score != nil && @score > 0}
        class="text-green-700 outline-green-700 outline-solid outline-2 rounded-full p-2 w-8 h-8 flex justify-center items-center -font-semibold"
      >
        {@score}p
      </div>
      <div :if={@score != nil && @score == 0}>
        <.icon name="hero-x-mark" class="w-8 h-8 p-2 bg-red-700" />
      </div>
    </div>
    """
  end

  @impl true
  def update(%{answer_updated: answer}, socket) do
    IO.puts "UPDATE answer_updated "

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

  # @impl true
  # def update_many(assigns_sockets) do
  #   dbg(assigns_sockets)
  #   IO.puts "UPDATE MANY #{inspect(Enum.map(assigns_sockets, fn {assigns, _} -> "#{assigns.submission.id} #{assigns.question.id} #{assigns.index}" end))}"
  #   submission_id = Enum.find_value(assigns_sockets, fn {assigns, _} -> assigns.submission.id end)

  #   answers_by_question_id =
  #     Submission.get_answers(submission_id)
  #     |> Enum.reduce(%{}, fn a, acc ->
  #       Map.update(acc, a.question_id, [a], fn l -> [a | l] end)
  #     end)

  #   Enum.map(assigns_sockets, fn {assigns, socket} ->
  #     answer = Enum.find(answers_by_question_id[assigns.question.id] || [], fn a -> a.index == assigns.index end)
  #     || Answer.create(assigns.question.id, assigns.submission.id, assigns.index)
  #     socket
  #     |> assign(assigns)
  #     |> assign(:answer, answer)
  #     |> assign_new(:saved, fn -> false end)
  #     |> assign_new(:form, fn -> to_form(Answer.changeset(answer), as: "answer") end)
  #   end)
  # end

  @impl true
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="" id={@id}>
      <div class="flex gap-2">
        <.form
          id={"form-#{@id}"}
          for={@form}
          phx-target={@myself}
          class="flex-grow"
          phx-change="submit"
        >
          <.input
            :if={@question.type == "alternatives" && Enum.count(@question.alternatives || []) <= 6}
            id={"input-#{@id}"}
            field={@form[:text]}
            type="radiogroup"
            disabled={!@enabled}
            options={for a <- @question.alternatives || [], do: {a, a}}
          />
          <.input
            :if={@question.type == "alternatives" && Enum.count(@question.alternatives || []) > 6}
            id={"input-#{@id}"}
            class="max-w-3xs"
            field={@form[:text]}
            type="select"
            disabled={!@enabled}
            options={for a <- @question.alternatives || [], do: {a, a}}
            prompt="Velg"
          />
          <.input
            :if={@question.type != "alternatives"}
            id={"input-#{@id}"}
            type="text"
            class={["max-w-3xs", @saved && "input-success"]}
            disabled={!@enabled}
            field={@form[:text]}
            phx-debounce="500"
            phx-value-index="1"
          />
        <button type="submit" class="hidden" disabled></button>
        </.form>
        <div class="flex-shrink">
          <.score score={@answer.score} />
        </div>
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

      {:noreply,
       socket
       |> assign(
         form: to_form(changeset, as: "answer"),
         answer: answer,
         saved: true
       )}
    else
      {:error, changeset} ->
        {:noreply, socket |> assign(form: to_form(changeset, as: "answer"), saved: false)}
    end
  end
end
