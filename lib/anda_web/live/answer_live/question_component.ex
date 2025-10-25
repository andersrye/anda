defmodule AndaWeb.AnswerLive.QuestionComponent do
  use AndaWeb, :live_component
  alias Anda.Submission
  alias Ecto.Changeset

  @impl true
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    has_alternatives =
      !is_nil(assigns.question.alternatives) && !Enum.empty?(assigns.question.alternatives)

    answer_value = if assigns.answer != nil, do: assigns.answer.answer, else: ""
    changeset = Changeset.change({%{answer: answer_value}, %{answer: :string}})

    assigns =
      assigns
      |> assign_new(:form, fn -> to_form(changeset, as: "form") end)
      |> assign(:has_alternatives, has_alternatives)

    ~H"""
    <div class={} id={@id}>
      {@question.question}
      <div :if={@has_alternatives}>
        <input :for={alternative <- @question.alternatives} type="radio" value={alternative} />
      </div>
      <img
        :if={!is_nil(@question.media_url) && String.starts_with?(@question.media_type, "image")}
        src={@question.media_url}
      />
      <div :if={!@has_alternatives}>
        <.form for={@form} phx-change="submit" phx-target={@myself}>
          <.input id={"#{@id}-form"} type="text" field={@form[:answer]} phx-debounce={500} />
        </.form>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("submit", %{"form" => %{"answer" => new_answer}}, socket) do
    dbg(new_answer)
    answer =
      if(socket.assigns.answer) do
        socket.assigns.answer
      else
        %Submission.Answer{
          submission_id: socket.assigns.submission.id,
          question_id: socket.assigns.question.id,
          index: 0
        }
      end

    case Submission.submit_answer(
           answer,
           new_answer,
           socket.assigns.question,
           socket.assigns.submission
         ) do
      {:ok, answer} ->
        {:noreply, socket |> assign(:answer, answer)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
end
