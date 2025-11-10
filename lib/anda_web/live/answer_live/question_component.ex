defmodule AndaWeb.AnswerLive.QuestionComponent do
  import AndaWeb.AnswerLive.LiveForm
  alias Anda.Submission.Answer
  use AndaWeb, :live_component
  alias Anda.Submission
  alias Ecto.Changeset

  defp print_float(float) do
    if floor(float) == float do
      floor(float)
    else
      float
    end
  end

  defp answer_values(answers) do
    if answers != nil do
      num_answers = answers |> Enum.map(fn a -> a.index end) |> Enum.max(fn -> 0 end)

      for index <- 0..num_answers do
        existing = Enum.find(answers, fn a -> a.index == index end)
        (existing && existing.text) || ""
      end
    else
      []
    end
  end

  defp answer_changeset(question, answers) do
    values = answer_values(answers)

    if question.num_answers == 1 do
      Changeset.change({%{text: Enum.at(values, 0, "")}, %{text: :string}})
    else
      Changeset.change({%{text: values}, %{text: {:array, :string}}})
    end
  end

  @impl true
  def update(assigns, socket) do
    scores = (assigns.answers || []) |> Enum.map(fn a -> a.score end)
    changeset = answer_changeset(assigns.question, assigns.answers)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn -> to_form(changeset, as: "form") end)
     |> assign(:scores, scores)}
  end

  @impl true
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="mb-8 w-full" id={@id}>
      <div class="text-base mb-2 font-medium">
        {@question.question}
      </div>
      <img
        :if={!is_nil(@question.media_url) && String.starts_with?(@question.media_type, "image")}
        src={@question.media_url}
      />
      <div class="px-4 flex gap-2">
        <.form
          id={"form-#{@id}"}
          for={@form}
          phx-target={@myself}
          class="flex-grow"
          phx-change="live_form"
          phx-debounce="500"
        >
          <.input
            :if={@question.type == "alternatives" && Enum.count(@question.alternatives) <= 6}
            id={"input-#{@id}"}
            field={@form[:text]}
            type="radiogroup"
            disabled={@action != :edit}
            options={for a <- @question.alternatives, do: {a, a}}
          />
          <.input
            :if={@question.type == "alternatives" && Enum.count(@question.alternatives) > 6}
            id={"input-#{@id}"}
            class="max-w-3xs"
            field={@form[:text]}
            type="select"
            disabled={@action != :edit}
            options={for a <- @question.alternatives, do: {a, a}}
            prompt="Velg"
          />
          <.textgroup
            :if={@question.type != "alternatives" && @question.num_answers > 1}
            id={"input-#{@id}"}
            class="max-w-3xs"
            disabled={@action != :edit}
            field={@form[:text]}
            num_inputs={@question.num_answers}
            phx-debounce="500"
          />
          <.input
            :if={@question.type != "alternatives" && @question.num_answers == 1}
            id={"input-#{@id}"}
            type="text"
            class="max-w-3xs"
            disabled={@action != :edit}
            field={@form[:text]}
            phx-debounce="500"
          />
        </.form>
        <div class="flex-shrink">
          <div :for={score <- @scores}>
            <div
              :if={score != nil && score > 0}
              class="text-green-700 outline-green-700 outline-solid outline-2 rounded-full p-2 w-8 h-8 flex justify-center items-center font-semibold"
            >
              {print_float(score)}p
            </div>
            <div :if={score != nil && score == 0}>
              <.icon name="hero-x-mark" class="w-8 h-8 p-2 bg-red-700" />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("live_form", %{"form" => %{"text" => new_answer}}, socket)
      when socket.assigns.action == :edit do
    new_answers = if is_list(new_answer), do: new_answer, else: [new_answer]

    result =
      Submission.submit_answers(
        socket.assigns.answers,
        new_answers,
        socket.assigns.question,
        socket.assigns.submission
      )

    case result do
      {:ok, res} ->
        new_answers = Map.values(res)

        {
          :noreply,
          socket
          |> assign(:answers, new_answers)
          |> assign(
            form: to_form(answer_changeset(socket.assigns.question, new_answers), as: "form")
          )
        }

      {:error, _id, %Ecto.Changeset{} = failed_changeset, _rest} ->
        #TODO: dette er en hack...
        changeset = failed_changeset |> Changeset.change(%{:text =>  answer_values(socket.assigns.answers)})
        {:noreply, socket |> assign(form: to_form(changeset, as: "form"))}
    end
  end
end
