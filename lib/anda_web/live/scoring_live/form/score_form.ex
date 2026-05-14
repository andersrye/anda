defmodule AndaWeb.ScoringLive.Form.ScoreForm do
  alias Anda.Contest
  alias Anda.Repo
  alias Ecto.Changeset
  alias Anda.Submission
  use AndaWeb, :live_component

  @impl true
  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    has_been_scored = Enum.any?(assigns.unique_answers, &(!is_nil(&1.score)))

    change_count =
      Enum.count(assigns.unique_answers, &(&1.score != &1.new_score || &1.new_count > 0))

    assigns = assign(assigns, change_count: change_count, has_been_scored: has_been_scored)

    ~H"""
    <div class="">
      <.form
        for={@score_form}
        phx-change="change"
        phx-submit="set_scores"
        phx-target={@myself}
        class="flex flex-col"
      >
        <.header>
          Retting
        </.header>
        <.question question={@question} />
        <input type="hidden" name={@score_form[:answers].name <> "[]"} value="" />

        <div class="overflow-auto flex-shrink">
          <table id="score-table" class="table table-sm sm:table-md" phx-hook=".TableHook">
            <thead>
              <tr>
                <th></th>
                <.sortable_header
                  key="text"
                  title="Svar"
                  sort_order={@sort_order}
                  default_order="asc"
                  phx-target={@myself}
                />
                <.sortable_header
                  key="count"
                  title="Antall"
                  sort_order={@sort_order}
                  phx-target={@myself}
                />
                <.sortable_header
                  key="score"
                  title="Poeng"
                  sort_order={@sort_order}
                  phx-target={@myself}
                />
              </tr>
            </thead>
            <tbody>
              <tr
                :for={answer <- @unique_answers}
                class="hover:bg-base-200/50 hover:cursor-pointer has-checked:bg-blue-100"
              >
                <td class="w-3">
                  <.input
                    type="multicheckbox"
                    multiple={true}
                    item={answer.text}
                    class="checkbox checkbox-xs"
                    field={@score_form[:answers]}
                  />
                </td>
                <td>{answer.text}</td>
                <td>
                  {answer.total_count}
                  <span
                    :if={answer.new_count > 0 && @has_been_scored}
                    class="text-yellow-600 font-bold"
                  >
                    (+{answer.new_count})
                  </span>
                </td>
                <td>
                  <.score_inline score={answer.score} />
                  <span :if={answer.score != answer.new_score}>
                    →
                  </span>
                  <.score_inline :if={answer.score != answer.new_score} score={answer.new_score} />
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="my-3">
          <span class="text-sm mr-2">
            {Enum.count(@score_form[:answers].value, &(&1 != ""))} valgt
          </span>
          <div class="join">
            <.input type="number" field={@score_form[:points]} class="join-item max-w-20 input-sm" />
            <.button class="btn btn-sm join-item mt-1">Sett poeng</.button>
          </div>
        </div>
      </.form>
      <div class="flex items-center gap-3">
        <.form
          for={@submit_form}
          phx-change="change_submit"
          phx-submit="save"
          phx-target={@myself}
        >
          <.input
            type="text"
            label="Fasit (valgfritt)"
            field={@submit_form[:answer_key]}
            class="mb-3"
          />
          <.button
            disabled={Enum.count(@score_form[:answers].value, &(&1 != "")) > 0}
            phx-disable-with="Lagrer..."
          >
            Lagre
          </.button>
          <span>{@change_count} {if @change_count == 1, do: "endret", else: "endrede"}</span>
        </.form>
      </div>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".TableHook">
        export default {
          mounted() {
            const rows = this.el.querySelectorAll('tbody tr')
            for(const row of rows) {
              row.addEventListener("click", e => {
                const checkbox = row.querySelector("input")
                if(e.target == checkbox) return
                checkbox.checked = !checkbox.checked
                checkbox.dispatchEvent(new Event("input", {bubbles: true}))
              })
            }
          }
        }
      </script>
    </div>
    """
  end

  defp schema(), do: %{answers: {:array, :string}, points: :integer}
  defp submit_schema(), do: %{answer_key: :string}

  def sort_answers(answers, sort_order) do
    sorter =
      case sort_order do
        "text_asc" -> &(&1.text <= &2.text)
        "text_desc" -> &(&1.text >= &2.text)
        "count_asc" -> &(&1.total_count <= &2.total_count)
        "count_desc" -> &(&1.total_count >= &2.total_count)
        "score_asc" -> &(&1.new_score <= &2.new_score)
        "score_desc" -> &(&1.new_score >= &2.new_score)
      end

    Enum.sort(answers, sorter)
  end

  def get_answers(question) do
    unique_answers = Submission.get_all_unique_answers(question.id)

    score_by_answer =
      Enum.reduce(question.answer_keys, %{}, fn a, acc ->
        Map.put(acc, a.text, a.score)
      end)

    alternatives =
      question.alternatives
      |> List.wrap()
      |> Enum.filter(&(!String.starts_with?(&1, "--")))
      |> Enum.filter(&Enum.all?(unique_answers, fn a -> a.text != &1 end))
      |> Enum.map(&%{text: &1, total_count: 0, new_count: 0})

    (unique_answers ++ alternatives)
    |> Enum.map(&Map.put(&1, :score, Map.get(score_by_answer, &1.text, 0)))
    |> Enum.map(&Map.put(&1, :new_score, &1.score || 0))
  end

  @impl true
  def update(assigns, socket) do
    question =
      Contest.get_question!(assigns.question_id, assigns.current_scope)
      |> Repo.preload(:answer_keys)

    unique_answers = get_answers(question)

    sort_order = "text_asc"

    unique_answers = sort_answers(unique_answers, sort_order)

    score_changeset =
      Changeset.change({%{answers: [], points: question.points || 1}, schema()})

    submit_changeset =
      Changeset.change({%{answer_key: question.answer_key}, submit_schema()})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:question, question)
     |> assign(:unique_answers, unique_answers)
     |> assign(:sort_order, sort_order)
     |> assign(:score_form, to_form(score_changeset, as: "form"))
     |> assign(:submit_form, to_form(submit_changeset, as: "submit_form"))}
  end

  @impl true
  def handle_event(
        "change",
        %{"form" => %{"answers" => selected_answers, "points" => points}},
        socket
      ) do
    changeset =
      Changeset.change({%{answers: selected_answers, points: points}, schema()})

    {:noreply, assign(socket, form: to_form(changeset, as: "form"))}
  end

  @impl true
  def handle_event(
        "change_submit",
        %{"submit_form" => %{"answer_key" => answer_key}},
        socket
      ) do
    changeset =
      Changeset.change({%{answer_key: answer_key}, submit_schema()})

    {:noreply, assign(socket, form: to_form(changeset, as: "form"))}
  end

  def handle_event("set_sort_order", %{"sort_order" => sort_order}, socket) do
    {:noreply,
     assign(socket,
       sort_order: sort_order,
       unique_answers: sort_answers(socket.assigns.unique_answers, sort_order)
     )}
  end

  @impl true
  def handle_event(
        "set_scores",
        %{"form" => %{"answers" => selected_answers, "points" => points}},
        socket
      ) do
    points = String.to_integer(points)

    answers =
      socket.assigns.unique_answers
      |> Enum.map(fn answer ->
        if(answer.text in selected_answers) do
          Map.put(answer, :new_score, points)
        else
          answer
        end
      end)
      |> sort_answers(socket.assigns.sort_order)

    changeset =
      Changeset.change({%{answers: [], points: points}, schema()})

    {:noreply, assign(socket, unique_answers: answers, form: to_form(changeset, as: "form"))}
  end

  @impl true
  def handle_event("save", %{"submit_form" => %{"answer_key" => answer_key}}, socket) do
    scores =
      socket.assigns.unique_answers
      |> Enum.group_by(& &1.new_score, & &1.text)
      |> Enum.map(fn {score, answers} -> {answers, score} end)

    {:ok, {question, num_scored}} =
      Submission.set_scores(socket.assigns.question, scores, answer_key)

    notify_parent({:scored, question, num_scored})

    {:noreply, push_patch(socket, to: socket.assigns.patch)}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
