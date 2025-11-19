defmodule AndaWeb.QuizLive.Form.ScoreForm do
  alias Anda.Contest
  alias Ecto.Changeset
  alias Anda.Submission
  use AndaWeb, :live_component

  @impl true
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
        <.button phx-disable-with="Saving...">Save</.button>
      </.form>
    </div>
    """
  end

  @impl true
  @spec update(maybe_improper_list() | map(), any()) :: {:ok, map()}
  def update(assigns, socket) do
    id = assigns.question_id
    question = Contest.get_question!(id)

    unique_answers = Submission.get_all_unique_answers2(id)
    dbg(unique_answers)

    options =
      unique_answers
      |> Enum.map(fn {v, ids, _} ->
        {"#{v} (#{Enum.count(ids)})", v}
      end)

    selected_options =
      unique_answers
      |> Enum.filter(fn {_, _, score} -> score > 0 end)
      |> Enum.map(fn {text, _, _} -> text end)

    max_score = unique_answers |>  Enum.map(fn {_, _, score} -> score end) |> Enum.max()

    changeset =
      Changeset.change(
        {%{answers: selected_options, points: max(max_score, 1)}, %{answers: {:array, :string}, points: :integer}}
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
  def handle_event("validate", unsigned_params, socket) do
    dbg(unsigned_params)
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "save",
        %{"form" => %{"answers" => selected_answers, "points" => score}},
        socket
      ) do
    selected_answers =
      selected_answers
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&(String.length(&1) != 0))

    scores =
      Enum.reduce(socket.assigns.unique_answers, %{}, fn {v, ids, _}, acc ->
        if v in selected_answers do
          Map.update(acc, score, ids, &Enum.concat(&1, ids))
        else
          Map.update(acc, 0, ids, &Enum.concat(&1, ids))
        end
      end)

    Submission.set_scores(scores)
    socket.assigns.on_saved.()

    {:noreply, socket}
  end
end
