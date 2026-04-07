defmodule AndaWeb.ScoringLive.Form.AnswersList do
  alias Anda.Contest
  alias Ecto.Changeset
  alias Anda.Submission
  use AndaWeb, :live_component

  attr :key, :string
  attr :sort_order, :string
  attr :title, :string
  attr :rest, :global

  def sortable_header(assigns) do
    assigns = assign(assigns, this_asc: "#{assigns.key}_asc", this_desc: "#{assigns.key}_desc")

    ~H"""
    <th
      class="hover:bg-base-200 hover:cursor-pointer"
      phx-click="set_sort_order"
      phx-value-sort_order={if @sort_order === @this_asc, do: @this_desc, else: @this_asc}
      {@rest}
    >
      {@title}
      <.icon :if={@sort_order == @this_desc} name="hero-chevron-up" />
      <.icon :if={@sort_order == @this_asc} name="hero-chevron-down" />
    </th>
    """
  end

  @impl true
  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Alle svar
      </.header>
      <div>
        {@question.text}
      </div>
      <div class="overflow-x-auto mt-5">
        <table class="table table-xs sm:table-md">
          <thead>
            <tr>
              <.sortable_header key="name" title="Name" sort_order={@sort_order} phx-target={@myself} />
              <.sortable_header key="svar" title="Svar" sort_order={@sort_order} phx-target={@myself} />
              <.sortable_header key="score" title="Poeng" sort_order={@sort_order} phx-target={@myself} />
            </tr>
          </thead>
          <tbody>
            <tr :for={answer <- @answers}>
              <td>{answer.name}</td>
              <td>{answer.text}</td>
              <td>{answer.score}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  @impl true
  @spec update(maybe_improper_list() | map(), any()) :: {:ok, map()}
  def update(assigns, socket) do
    sort_order = "name_desc"
    question = Contest.get_question!(assigns.question_id, assigns.current_scope)
    answers = Submission.get_all_answers(assigns.question_id, sort_order)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:question, question)
     |> assign(:answers, answers)
     |> assign(:sort_order, sort_order)}
  end

  @impl true
  def handle_event("validate", _unsigned_params, socket) do
    # dbg(unsigned_params)
    {:noreply, socket}
  end

  @impl true
  def handle_event("set_sort_order", %{"sort_order" => sort_order}, socket) do
    answers = Submission.get_all_answers(socket.assigns.question_id, sort_order)

    {:noreply,
     socket
     |> assign(answers: answers)
     |> assign(sort_order: sort_order)}
  end
end
