defmodule AndaWeb.QuizLive.Form.QuizForm do
  use AndaWeb, :live_component

  alias Anda.Contest

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="quiz-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Tittel" />
        <.input field={@form[:description]} type="textarea" label="Beskrivelse" />
        <.input class="join-item input" field={@form[:slug]} type="text" label="Url-id" />
        <div class="text-xs label">
          <span class="mr-1">Url:</span>
          <span class="font-mono">{@base_url}{@form[:slug].value}</span>
        </div>
        <.input
          field={@form[:mode]}
          type="radiogroup"
          label="Status"
          col={true}
          options={[
            %{label: "Skjult", value: "hidden", helptext: "Ikke synlig og kan ikke besvares"},
            %{label: "Åpen", value: "open", helptext: "Synlig for alle og åpen for besvarelser"},
            %{label: "Stengt", value: "closed", helptext: "Synlig for alle, men kan ikke besvares"}
          ]}
        />

        <:actions>
          <.button phx-disable-with="Saving...">Lagre</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{quiz: quiz} = assigns, socket) do
    base_url = URI.to_string(socket.host_uri) <> "/quiz/"

    {:ok,
     socket
     |> assign(assigns)
     |> assign(base_url: base_url)
     |> assign_new(:form, fn ->
       to_form(Contest.change_quiz(quiz))
     end)}
  end

  @impl true
  def handle_event("validate", %{"quiz" => quiz_params}, socket) do
    changeset = Contest.change_quiz(socket.assigns.quiz, quiz_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"quiz" => quiz_params}, socket) do
    save_quiz(socket, socket.assigns.action, quiz_params)
  end

  defp save_quiz(socket, :edit_quiz, quiz_params) do
    case Contest.update_quiz(socket.assigns.quiz, quiz_params, socket.assigns.current_scope) do
      {:ok, quiz} ->
        notify_parent({:saved, quiz})

        {:noreply,
         socket
         |> put_flash(:info, "Quiz updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_quiz(socket, :new_quiz, quiz_params) do
    case Contest.create_quiz(quiz_params, socket.assigns.current_scope) do
      {:ok, quiz} ->
        notify_parent({:saved, quiz})

        {:noreply,
         socket
         |> put_flash(:info, "Quiz created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
