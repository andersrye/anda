defmodule AndaWeb.AnswerLive.QuestionInput do
  use AndaWeb, :live_component
  alias Anda.Submission.Answer
  alias Anda.Submission
  import AndaWeb.AnswerLive.AnswerComponents

  defp process_alternatives(alternatives) do
    Enum.reduce(alternatives, [], fn val, acc ->
      cond do
        String.starts_with?(val, "---") ->
          [:hr | acc]

        String.starts_with?(val, "--") ->
          [{String.replace_prefix(val, "--", ""), []} | acc]

        :else ->
          first = List.first(acc)

          if is_tuple(first) do
            [{header, values} | tail] = acc
            [{header, [val | values]} | tail]
          else
            [val | acc]
          end
      end
    end)
    |> Enum.reverse()
    |> Enum.map(fn item ->
      if(is_tuple(item)) do
        {header, values} = item
        {header, Enum.reverse(values)}
      else
        item
      end
    end)
  end

  @impl true
  def update(assigns, socket) do
    answer =
      assigns.answer || Answer.create(assigns.question.id, assigns.submission.id, assigns.index)

    changeset = Answer.changeset(answer)
    alternatives = assigns.question.alternatives || []

    num_alternatives = Enum.count(alternatives)
    has_alternatives_groups = Enum.any?(alternatives, &String.starts_with?(&1, "--"))

    alternatives = process_alternatives(alternatives)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(answer: answer)
     |> assign(num_alternatives: num_alternatives)
     |> assign(has_alternatives_groups: has_alternatives_groups)
     |> assign(alternatives: alternatives)
     |> assign(:form, to_form(changeset, as: "answer"))}
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
            :if={
              @question.type == "alternatives" && @num_alternatives <= 6 && !@has_alternatives_groups
            }
            id={"input-#{@id}"}
            field={@form[:text]}
            type="radiogroup"
            class="max-w-3xs"
            disabled={!@enabled}
            options={@alternatives}
            phx-target={@myself}
          />
          <.select_input
            :if={
              (@question.type == "alternatives" && @num_alternatives > 6) || @has_alternatives_groups
            }
            id={"input-#{@id}"}
            class="max-w-3xs"
            field={@form[:text]}
            type="select"
            disabled={!@enabled}
            phx-target={@myself}
            options={@alternatives}
            prompt="Velg et svar"
          />
          <.text_input
            :if={@question.type != "alternatives"}
            id={"input-#{@id}"}
            inputmode={if @question.type == "number", do: "numeric", else: nil}
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
