defmodule AndaWeb.EditLive.Form.DeleteQuestionForm do
  use AndaWeb, :live_component

  alias Anda.Contest

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Slett spørsmål
      </.header>
      <p>Sikker på at du vil slette spørsmålet "{@question.text}"?</p>
      <p class="my-5">Dette kan ikke gjøres om.</p>
      <div class="flex gap-3 mt-5">
        <.button
          class="btn btn-error"
          phx-click="confirm_delete"
          phx-target={@myself}
          phx-disable-with="Sletter..."
        >
          Slett
        </.button>
        <.button class="btn btn-soft" phx-click="cancel" phx-target={@myself}>Avbryt</.button>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    question = Contest.get_question!(assigns.question_id, assigns.current_scope)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(question: question)}
  end

  @impl true
  def handle_event("confirm_delete", _, socket) do
    Contest.delete_question(socket.assigns.question)
    notify_parent({:deleted, socket.assigns.question})

    {:noreply, socket |> push_patch(to: socket.assigns.patch)}
  end

  @impl true
  def handle_event("cancel", _, socket) do
    {:noreply, socket |> push_patch(to: socket.assigns.patch)}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
