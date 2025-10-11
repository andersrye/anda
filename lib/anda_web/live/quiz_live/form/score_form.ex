defmodule AndaWeb.QuizLive.Form.ScoreForm do
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
        {@question.question}
      </div>
      <.form for={@form} phx-change="validate" phx-submit="save" phx-target={@myself}>
        <.checkgroup label="svar" field={@form[:answers]} options={@options} />
        <.button phx-disable-with="Saving...">Save</.button>
      </.form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", unsigned_params, socket) do
    dbg(unsigned_params)
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"form" => %{"answers" => selected_answers}}, socket) do
    selected_answers =
      selected_answers
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&(String.length(&1) != 0))

    scores =
      Enum.reduce(socket.assigns.unique_answers, %{}, fn {v, ids}, acc ->
        if v in selected_answers do
          Map.update(acc, 1, ids, &Enum.concat(&1, ids))
        else
          Map.update(acc, 0, ids, &Enum.concat(&1, ids))
        end
      end)

    dbg(selected_answers)
    dbg(socket.assigns.unique_answers)
    dbg(scores)
    Submission.set_scores(scores)

    {:noreply, socket}
  end

  @impl true
  @spec update(maybe_improper_list() | map(), any()) :: {:ok, map()}
  def update(assigns, socket) do
    id = assigns.question.id

    unique_answers = Submission.get_all_unique_answers2(id)
    options = unique_answers |> Enum.map(fn {v, ids} -> {"#{v} (#{Enum.count(ids)})", v} end)

    dbg(unique_answers)
    dbg(options)

    changeset = Changeset.change({%{answers: []}, %{answers: {:array, :string}}})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:options, options)
     |> assign(:unique_answers, unique_answers)
     |> assign(:form, to_form(changeset, as: "form"))}
  end
end
