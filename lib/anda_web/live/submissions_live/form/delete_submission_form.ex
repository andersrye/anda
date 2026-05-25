defmodule AndaWeb.SubmissionsLive.Form.DeleteSubmissionForm do
alias Anda.Submission
  use AndaWeb, :live_component

  alias Anda.Contest

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Slett besvarelse
      </.header>
      <p>Er du sikker på at du vil slette besvarelsen til "{@submission.name}"? Det er kjipt hvis du gjør feil her!</p>
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
    {:ok,
     socket
     |> assign(assigns)
    }
  end

  @impl true
  def handle_event("confirm_delete", _, socket) do
    Submission.delete_submission(socket.assigns.submission, socket.assigns.current_scope)
    notify_parent({:deleted, socket.assigns.submission})

    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel", _, socket) do
    notify_parent({:canceled})
    {:noreply, socket}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
