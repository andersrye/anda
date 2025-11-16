defmodule AndaWeb.AnswerLive.QuestionComponent do
  alias Anda.Submission.Answer
  use AndaWeb, :live_component
  alias Anda.Submission

  defp score(assigns) do
    assigns =
      assigns
      |> assign(
        score:
          if assigns.score && floor(assigns.score) == assigns.score do
            floor(assigns.score)
          else
            assigns.score
          end
      )

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
  def update(assigns, socket) do
    answer =
      assigns.answer || Answer.create(assigns.question.id, assigns.submission.id, assigns.index)

    changeset = Answer.changeset(answer)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       answer: answer,
       saved: false
     )
     |> assign_new(:form, fn -> to_form(changeset, as: "answer") end)}
  end

  @impl true
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="" id={@id}>
      <!--
      <img
        :if={!is_nil(@question.media_url) && String.starts_with?(@question.media_type, "image")}
        src={@question.media_url}
      />
      -->
      <div class="px-4 flex gap-2">
        <.form
          id={"form-#{@id}"}
          for={@form}
          phx-target={@myself}
          class="flex-grow"
          phx-change="submit"
        >
          <.input
            :if={@question.type == "alternatives" && Enum.count(@question.alternatives) <= 6}
            id={"input-#{@id}"}
            field={@form[:text]}
            type="radiogroup"
            disabled={!@enabled}
            options={for a <- @question.alternatives, do: {a, a}}
          />
          <.input
            :if={@question.type == "alternatives" && Enum.count(@question.alternatives) > 6}
            id={"input-#{@id}"}
            class="max-w-3xs"
            field={@form[:text]}
            type="select"
            disabled={!@enabled}
            options={for a <- @question.alternatives, do: {a, a}}
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
        </.form>
        <div class="flex-shrink">
          <.score score={@answer.score} />
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("submit", p, socket) when socket.assigns.action == :preview do
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
        dbg(changeset)
        {:noreply, socket |> assign(form: to_form(changeset, as: "answer"), saved: false)}
    end
  end
end
