defmodule AndaWeb.ScoringLive.Form.ScoreForm do
  alias Anda.Contest
  alias Ecto.Changeset
  alias Anda.Submission
  use AndaWeb, :live_component

  @impl true
  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Retting
      </.header>
      <div>
        {@question.text}
      </div>
      <.form for={@form} phx-change="validate" phx-submit="save" phx-target={@myself}>
        <.checkgroup label="Velg alle riktige svar" field={@form[:answers]} options={@options} />
        <label>
          <span class="text-sm">Hvor mange poeng? </span>
          <.input type="number" field={@form[:points]} class="max-w-20" />
        </label>
        <.button phx-disable-with="Lagrer...">Lagre</.button>
      </.form>
    </div>
    """
  end

  @impl true
  @spec update(maybe_improper_list() | map(), any()) :: {:ok, map()}
  def update(assigns, socket) do
    question = Contest.get_question!(assigns.question_id, assigns.current_scope)
    unique_answers = Submission.get_all_unique_answers(assigns.question_id)

    options =
      unique_answers
      |> Enum.map(fn %{text: text, count: count} ->
        {"#{text} (#{count})", text}
      end)

    selected_options =
      unique_answers
      |> Enum.filter(&(&1.score > 0))
      |> Enum.map(& &1.text)

    max_score =
      unique_answers
      |> Enum.map(& &1.score)
      |> Enum.max(&>=/2, fn -> 0 end)

    changeset =
      Changeset.change(
        {%{answers: selected_options, points: max(max_score, 1)},
         %{answers: {:array, :string}, points: :integer}}
      )

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:question, question)
     |> assign(:options, options)
     |> assign(:unique_answers, unique_answers)
     |> assign(:form, to_form(changeset, as: "form"))}
  end

  @impl true
  def handle_event("validate", _unsigned_params, socket) do
    # dbg(unsigned_params)
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "save",
        %{"form" => %{"answers" => selected_answers, "points" => score}},
        socket
      ) do
    dbg(selected_answers)
    dbg(score)

    selected_answers =
      selected_answers
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&(String.length(&1) != 0))

    dbg(selected_answers)

    scores =
      Enum.reduce(socket.assigns.unique_answers, %{}, fn %{text: text, ids: ids}, acc ->
        if text in selected_answers do
          Map.update(acc, score, ids, &Enum.concat(&1, ids))
        else
          Map.update(acc, 0, ids, &Enum.concat(&1, ids))
        end
      end)

    dbg(scores)

    {:ok, num_scored} = Submission.set_scores(scores)
    notify_parent({:scored, socket.assigns.question, num_scored})

    {:noreply, socket |> push_patch(to: socket.assigns.patch) }
  end

  @impl true
  def handle_event(
        "save",
        payload,
        socket
      ) do
    dbg(payload)
    {:noreply, socket}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
